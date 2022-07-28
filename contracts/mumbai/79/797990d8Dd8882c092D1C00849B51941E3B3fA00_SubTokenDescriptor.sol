// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00
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
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
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
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
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

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp)
        internal
        pure
        returns (bool leapYear)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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

    function getDaysInMonth(uint256 timestamp)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp)
        internal
        pure
        returns (uint256 dayOfWeek)
    {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        uint256 year;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        uint256 year;
        uint256 month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp)
        internal
        pure
        returns (uint256 minute)
    {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp)
        internal
        pure
        returns (uint256 second)
    {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds)
        internal
        pure
        returns (uint256 newTimestamp)
    {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _years)
    {
        require(fromTimestamp <= toTimestamp);
        uint256 fromYear;
        uint256 fromMonth;
        uint256 fromDay;
        uint256 toYear;
        uint256 toMonth;
        uint256 toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(
            fromTimestamp / SECONDS_PER_DAY
        );
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _months)
    {
        require(fromTimestamp <= toTimestamp);
        uint256 fromYear;
        uint256 fromMonth;
        uint256 fromDay;
        uint256 toYear;
        uint256 toMonth;
        uint256 toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(
            fromTimestamp / SECONDS_PER_DAY
        );
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _days)
    {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _hours)
    {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _minutes)
    {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256 _seconds)
    {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library JsonWriter {

    using JsonWriter for string;

    struct Json {
        int256 depthBitTracker;
        string value;
    }

    bytes1 constant BACKSLASH = bytes1(uint8(92));
    bytes1 constant BACKSPACE = bytes1(uint8(8));
    bytes1 constant CARRIAGE_RETURN = bytes1(uint8(13));
    bytes1 constant DOUBLE_QUOTE = bytes1(uint8(34));
    bytes1 constant FORM_FEED = bytes1(uint8(12));
    bytes1 constant FRONTSLASH = bytes1(uint8(47));
    bytes1 constant HORIZONTAL_TAB = bytes1(uint8(9));
    bytes1 constant NEWLINE = bytes1(uint8(10));

    string constant TRUE = "true";
    string constant FALSE = "false";
    bytes1 constant OPEN_BRACE = "{";
    bytes1 constant CLOSED_BRACE = "}";
    bytes1 constant OPEN_BRACKET = "[";
    bytes1 constant CLOSED_BRACKET = "]";
    bytes1 constant LIST_SEPARATOR = ",";

    int256 constant MAX_INT256 = type(int256).max;

    /**
     * @dev Writes the beginning of a JSON array.
     */
    function writeStartArray(Json memory json) 
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, OPEN_BRACKET);
    }

    /**
     * @dev Writes the beginning of a JSON array with a property name as the key.
     */
    function writeStartArray(Json memory json, string memory propertyName)
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, propertyName, OPEN_BRACKET);
    }

    /**
     * @dev Writes the beginning of a JSON object.
     */
    function writeStartObject(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, OPEN_BRACE);
    }

    /**
     * @dev Writes the beginning of a JSON object with a property name as the key.
     */
    function writeStartObject(Json memory json, string memory propertyName)
        internal
        pure
        returns (Json memory)
    {
        return writeStart(json, propertyName, OPEN_BRACE);
    }

    /**
     * @dev Writes the end of a JSON array.
     */
    function writeEndArray(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        return writeEnd(json, CLOSED_BRACKET);
    }

    /**
     * @dev Writes the end of a JSON object.
     */
    function writeEndObject(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        return writeEnd(json, CLOSED_BRACE);
    }

    /**
     * @dev Writes the property name and address value (as a JSON string) as part of a name/value pair of a JSON object.
     */
    function writeAddressProperty(
        Json memory json,
        string memory propertyName,
        address value
    ) internal pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": "', addressToString(value), '"'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": "', addressToString(value), '"'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the address value (as a JSON string) as an element of a JSON array.
     */
    function writeAddressValue(Json memory json, address value)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', addressToString(value), '"'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', addressToString(value), '"'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and boolean value (as a JSON literal "true" or "false") as part of a name/value pair of a JSON object.
     */
    function writeBooleanProperty(
        Json memory json,
        string memory propertyName,
        bool value
    ) internal pure returns (Json memory) {
        string memory strValue;
        if (value) {
            strValue = TRUE;
        } else {
            strValue = FALSE;
        }

        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', strValue));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', strValue));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the boolean value (as a JSON literal "true" or "false") as an element of a JSON array.
     */
    function writeBooleanValue(Json memory json, bool value)
        internal
        pure
        returns (Json memory)
    {
        string memory strValue;
        if (value) {
            strValue = TRUE;
        } else {
            strValue = FALSE;
        }

        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, strValue));
        } else {
            json.value = string(abi.encodePacked(json.value, strValue));
        }
        
        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and int value (as a JSON number) as part of a name/value pair of a JSON object.
     */
    function writeIntProperty(
        Json memory json,
        string memory propertyName,
        int256 value
    ) internal pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', intToString(value)));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', intToString(value)));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the int value (as a JSON number) as an element of a JSON array.
     */
    function writeIntValue(Json memory json, int256 value)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, intToString(value)));
        } else {
            json.value = string(abi.encodePacked(json.value, intToString(value)));
        }
        
        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and value of null as part of a name/value pair of a JSON object.
     */
    function writeNullProperty(Json memory json, string memory propertyName)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": null'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": null'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the value of null as an element of a JSON array.
     */
    function writeNullValue(Json memory json)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, "null"));
        } else {
            json.value = string(abi.encodePacked(json.value, "null"));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the string text value (as a JSON string) as an element of a JSON array.
     */
    function writeStringProperty(
        Json memory json,
        string memory propertyName,
        string memory value
    ) internal pure returns (Json memory) {
        string memory jsonEscapedString = escapeJsonString(value);
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": "', jsonEscapedString, '"'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": "', jsonEscapedString, '"'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and string text value (as a JSON string) as part of a name/value pair of a JSON object.
     */
    function writeStringValue(Json memory json, string memory value)
        internal
        pure
        returns (Json memory)
    {
        string memory jsonEscapedString = escapeJsonString(value);
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', jsonEscapedString, '"'));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', jsonEscapedString, '"'));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the property name and uint value (as a JSON number) as part of a name/value pair of a JSON object.
     */
    function writeUintProperty(
        Json memory json,
        string memory propertyName,
        uint256 value
    ) internal pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', uintToString(value)));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', uintToString(value)));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the uint value (as a JSON number) as an element of a JSON array.
     */
    function writeUintValue(Json memory json, uint256 value)
        internal
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, uintToString(value)));
        } else {
            json.value = string(abi.encodePacked(json.value, uintToString(value)));
        }

        json.depthBitTracker = setListSeparatorFlag(json);

        return json;
    }

    /**
     * @dev Writes the beginning of a JSON array or object based on the token parameter.
     */
    function writeStart(Json memory json, bytes1 token)
        private
        pure
        returns (Json memory)
    {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, token));
        } else {
            json.value = string(abi.encodePacked(json.value, token));
        }

        json.depthBitTracker &= MAX_INT256;
        json.depthBitTracker++;

        return json;
    }

    /**
     * @dev Writes the beginning of a JSON array or object based on the token parameter with a property name as the key.
     */
    function writeStart(
        Json memory json,
        string memory propertyName,
        bytes1 token
    ) private pure returns (Json memory) {
        if (json.depthBitTracker < 0) {
            json.value = string(abi.encodePacked(json.value, LIST_SEPARATOR, '"', propertyName, '": ', token));
        } else {
            json.value = string(abi.encodePacked(json.value, '"', propertyName, '": ', token));
        }

        json.depthBitTracker &= MAX_INT256;
        json.depthBitTracker++;

        return json;
    }

    /**
     * @dev Writes the end of a JSON array or object based on the token parameter.
     */
    function writeEnd(Json memory json, bytes1 token)
        private
        pure
        returns (Json memory)
    {
        json.value = string(abi.encodePacked(json.value, token));
        json.depthBitTracker = setListSeparatorFlag(json);
        
        if (getCurrentDepth(json) != 0) {
            json.depthBitTracker--;
        }

        return json;
    }

    /**
     * @dev Escapes any characters that required by JSON to be escaped.
     */
    function escapeJsonString(string memory value)
        private
        pure
        returns (string memory str)
    {
        bytes memory b = bytes(value);
        bool foundEscapeChars;

        for (uint256 i; i < b.length; i++) {
            if (b[i] == BACKSLASH) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == DOUBLE_QUOTE) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == FRONTSLASH) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == HORIZONTAL_TAB) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == FORM_FEED) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == NEWLINE) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == CARRIAGE_RETURN) {
                foundEscapeChars = true;
                break;
            } else if (b[i] == BACKSPACE) {
                foundEscapeChars = true;
                break;
            }
        }

        if (!foundEscapeChars) {
            return value;
        }

        for (uint256 i; i < b.length; i++) {
            if (b[i] == BACKSLASH) {
                str = string(abi.encodePacked(str, "\\\\"));
            } else if (b[i] == DOUBLE_QUOTE) {
                str = string(abi.encodePacked(str, '\\"'));
            } else if (b[i] == FRONTSLASH) {
                str = string(abi.encodePacked(str, "\\/"));
            } else if (b[i] == HORIZONTAL_TAB) {
                str = string(abi.encodePacked(str, "\\t"));
            } else if (b[i] == FORM_FEED) {
                str = string(abi.encodePacked(str, "\\f"));
            } else if (b[i] == NEWLINE) {
                str = string(abi.encodePacked(str, "\\n"));
            } else if (b[i] == CARRIAGE_RETURN) {
                str = string(abi.encodePacked(str, "\\r"));
            } else if (b[i] == BACKSPACE) {
                str = string(abi.encodePacked(str, "\\b"));
            } else {
                str = string(abi.encodePacked(str, b[i]));
            }
        }

        return str;
    }

    /**
     * @dev Tracks the recursive depth of the nested objects / arrays within the JSON text
     * written so far. This provides the depth of the current token.
     */
    function getCurrentDepth(Json memory json) private pure returns (int256) {
        return json.depthBitTracker & MAX_INT256;
    }

    /**
     * @dev The highest order bit of json.depthBitTracker is used to discern whether we are writing the first item in a list or not.
     * if (json.depthBitTracker >> 255) == 1, add a list separator before writing the item
     * else, no list separator is needed since we are writing the first item.
     */
    function setListSeparatorFlag(Json memory json)
        private
        pure
        returns (int256)
    {
        return json.depthBitTracker | (int256(1) << 255);
    }

        /**
     * @dev Converts an address to a string.
     */
    function addressToString(address _address)
        internal
        pure
        returns (string memory)
    {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes16 alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }

        return string(str);
    }

    /**
     * @dev Converts an int to a string.
     */
    function intToString(int256 i) internal pure returns (string memory) {
        if (i == 0) {
            return "0";
        }

        if (i == type(int256).min) {
            // hard-coded since int256 min value can't be converted to unsigned
            return "-57896044618658097711785492504343953926634992332820282019728792003956564819968"; 
        }

        bool negative = i < 0;
        uint256 len;
        uint256 j;
        if(!negative) {
            j = uint256(i);
        } else {
            j = uint256(-i);
            ++len; // make room for '-' sign
        }
        
        uint256 l = j;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (l != 0) {
            bstr[--k] = bytes1((48 + uint8(l - (l / 10) * 10)));
            l /= 10;
        }

        if (negative) {
            bstr[0] = "-"; // prepend '-'
        }

        return string(bstr);
    }

    /**
     * @dev Converts a uint to a string.
     */
    function uintToString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            bstr[--k] = bytes1((48 + uint8(_i - (_i / 10) * 10)));
            _i /= 10;
        }

        return string(bstr);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import {BokkyPooBahsDateTimeLibrary as TimeLib} from "./BokkyPooBahsDateTimeLibrary.sol";

library Period {
    enum PeriodType {
        DAY,
        WEEK,
        MONTH,
        QUARTER,
        YEAR
    }

    function getPeriodName(PeriodType periodType)
        internal
        pure
        returns (string memory name)
    {
        if (periodType == PeriodType.DAY) {
            name = "DAY";
        } else if (periodType == PeriodType.WEEK) {
            name = "WEEK";
        } else if (periodType == PeriodType.MONTH) {
            name = "MONTH";
        } else if (periodType == PeriodType.QUARTER) {
            name = "QUARTER";
        } else if (periodType == PeriodType.YEAR) {
            name = "YEAR";
        }
    }

    function getPeriodTimestamp(PeriodType period, uint256 curTimestamp)
    internal
    pure
    returns (
        uint ts
    ) {
        if (period == PeriodType.DAY) {
            ts = TimeLib.addDays(curTimestamp, 1);
        } else if (period == PeriodType.WEEK) {
            ts = TimeLib.addYears(curTimestamp, 1);
        } else if (period == PeriodType.MONTH) {
            ts = TimeLib.addMonths(curTimestamp, 1);
        } else if (period == PeriodType.QUARTER) {
            ts = TimeLib.addMonths(curTimestamp, 3);
        } else if (period == PeriodType.YEAR) {
            ts = TimeLib.addYears(curTimestamp, 1);
        }
    }

    function convertTimestampToDateTimeString(uint256 timestamp)
        internal
        pure
        returns (string memory)
    {
        (
            uint256 YY,
            uint256 MM,
            uint256 DD,
            uint256 hh,
            uint256 mm,
            uint256 ss
        ) = TimeLib.timestampToDateTime(timestamp);

        string memory year = Strings.toString(YY);
        string memory month;
        string memory day;
        string memory hour;
        string memory minute;
        string memory second;
        if (MM == 0) {
            month = "00";
        } else if (MM < 10) {
            month = string(abi.encodePacked("0", Strings.toString(MM)));
        } else {
            month = Strings.toString(MM);
        }
        if (DD == 0) {
            day = "00";
        } else if (DD < 10) {
            day = string(abi.encodePacked("0", Strings.toString(DD)));
        } else {
            day = Strings.toString(DD);
        }

        if (hh == 0) {
            hour = "00";
        } else if (hh < 10) {
            hour = string(abi.encodePacked("0", Strings.toString(hh)));
        } else {
            hour = Strings.toString(hh);
        }

        if (mm == 0) {
            minute = "00";
        } else if (mm < 10) {
            minute = string(abi.encodePacked("0", Strings.toString(mm)));
        } else {
            minute = Strings.toString(mm);
        }

        if (ss == 0) {
            second = "00";
        } else if (ss < 10) {
            second = string(abi.encodePacked("0", Strings.toString(ss)));
        } else {
            second = Strings.toString(ss);
        }
        return
            string(
                abi.encodePacked(
                    year,
                    "-",
                    month,
                    "-",
                    day,
                    " ",
                    hour,
                    ":",
                    minute,
                    ":",
                    second
                )
            );
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IMerchantToken is IERC721Enumerable {

    struct Merchant {
        string name;
        address payeeAddress;
    }

    function setManager(address manager) external;

    function createMerchant(string memory name, address merchantOwner, address payeeAddress) external returns (uint);

    function updateMerchant(uint merchantTokenId, string memory name, address payeeAddress) external;

//    function getMerchantInfo(uint tokenId) external view returns (string memory name, address owner, address payee);

    function getMerchant(uint merchantTokenId) external view returns (Merchant memory merchant);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "../libs/Period.sol";

interface IPlanManager {

    struct Plan {
        string name;
        // 是否需要记录merchantTokenId
        string description; // plan description
        Period.PeriodType billingPeriod; // Billing Period [DAY, WEEK, MONTH, YEAR]
        address paymentToken;
        uint256 pricePerBillingPeriod;
//        Period.PeriodType termPeriod; // change to termLength
        //        uint termLength; // by month
        bool enabled;
    }

    function setManager(address _manager) external;

    function createPlan(
        uint256 merchantTokenId,
        string memory name,
        string memory description,
        Period.PeriodType billingPeriod,
        address paymentToken,
        uint256 pricePerBillingPeriod
//        Period.PeriodType termPeriod
    ) external returns (uint planIndex);

    function getPlan(uint256 merchant, uint256 planIndex)
    external
    view
    returns (
        Plan memory plan
    );

    function getPlans(uint256 merchant)
    external
    view
    returns (
        Plan[] memory plans
    );

    function disablePlan(uint256 merchant, uint256 planIndex) external;

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

interface ISubInfoManager {
    struct SubInfo {
        uint256 merchantTokenId;
        uint256 subTokenId;
        uint256 planIndex; // plan Index (name?)
        uint256 subStartTime; // sub valid start time subStartTime
        uint256 subEndTime; // sub valid end time subEndTime
        uint256 nextBillingTime; // next bill time nextBillingTime
//        uint256 termEndTime; // term end time termEndTime
        bool enabled; // if sub valid
    }

    function setManager(address _manager) external;

    function createSubInfo(
        uint256 merchantTokenId,
        uint256 subTokenId,
        uint256 planIndex,
        uint256 subStartTime,
        uint256 subEndTime,
        uint256 nextBillingTime
//        uint256 termEndTime
    ) external;

    function getSubInfo(uint256 subTokenId)
        external
        view
        returns (SubInfo memory subInfo);

    function updateSubInfo(
        uint256 merchantTokenId,
        uint256 tokenId,
        SubInfo memory subInfo
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

interface ISubTokenDescriptor {
    function tokenURI(address merchantToken, address planManager, address subInfoManager, uint256 subTokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../libs/Base64.sol";

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a Uniswap NFT
library NFTSVG {
    using Strings for uint256;

    struct SVGParams {
        // merchant info
        uint256 merchantCode;
        string merchantName;
        // plan info
        string planName;
        string planPeriod;
        string paymentTokenName;
        // sub info
        string startDateTime;
        string endDateTime;
        string nextBillDateTime;
//        string termDateTime;
        uint256 price;
    }

    function generateSVG(SVGParams memory params)
        internal
        pure
        returns (string memory svg)
    {
        string[17] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = string(abi.encodePacked("Plan Name : ", params.planName));

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = string(
            abi.encodePacked("Plan Period : ", params.planPeriod)
        );

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = string(
            abi.encodePacked("paymentToken : ", params.paymentTokenName)
        );

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = string(
            abi.encodePacked("price : ", Strings.toString(params.price))
        );

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = string(
            abi.encodePacked("Start Time : ", params.startDateTime)
        );

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = string(abi.encodePacked("End Time : ", params.endDateTime));

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = string(
            abi.encodePacked("Next Charge Time : ", params.nextBillDateTime)
        );

        // parts[14] = '</text><text x="10" y="160" class="base">';

        // parts[15] = getRing(tokenId);

        parts[16] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );
        string memory image = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(output))
            )
        );
        /*
        address: "0xe8ab59d3bcde16a29912de83a90eb39628cfc163",
        msg: "Forged in SVG for Uniswap in 2021 by 0xe8ab59d3bcde16a29912de83a90eb39628cfc163",
        sig: "0x2df0e99d9cbfec33a705d83f75666d98b22dea7c1af412c584f7d626d83f02875993df740dc87563b9c73378f8462426da572d7989de88079a382ad96c57b68d1b",
        version: "2"
        */
        return image;
    }

    // function generateSVGDefs(SVGParams memory params) private pure returns (string memory svg) {
    //     svg = string(
    //         abi.encodePacked(
    //             '<svg width="290" height="500" viewBox="0 0 290 500" xmlns="http://www.w3.org/2000/svg"',
    //             " xmlns:xlink='http://www.w3.org/1999/xlink'>",
    //             '<defs>',
    //             '<filter id="f1"><feImage result="p0" xlink:href="data:image/svg+xml;base64,',
    //             Base64.encode(
    //                 bytes(
    //                     abi.encodePacked(
    //                         "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><rect width='290px' height='500px' fill='#",
    //                         params.color0,
    //                         "'/></svg>"
    //                     )
    //                 )
    //             ),
    //             '"/><feImage result="p1" xlink:href="data:image/svg+xml;base64,',
    //             Base64.encode(
    //                 bytes(
    //                     abi.encodePacked(
    //                         "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
    //                         params.x1,
    //                         "' cy='",
    //                         params.y1,
    //                         "' r='120px' fill='#",
    //                         params.color1,
    //                         "'/></svg>"
    //                     )
    //                 )
    //             ),
    //             '"/><feImage result="p2" xlink:href="data:image/svg+xml;base64,',
    //             Base64.encode(
    //                 bytes(
    //                     abi.encodePacked(
    //                         "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
    //                         params.x2,
    //                         "' cy='",
    //                         params.y2,
    //                         "' r='120px' fill='#",
    //                         params.color2,
    //                         "'/></svg>"
    //                     )
    //                 )
    //             ),
    //             '" />',
    //             '<feImage result="p3" xlink:href="data:image/svg+xml;base64,',
    //             Base64.encode(
    //                 bytes(
    //                     abi.encodePacked(
    //                         "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
    //                         params.x3,
    //                         "' cy='",
    //                         params.y3,
    //                         "' r='100px' fill='#",
    //                         params.color3,
    //                         "'/></svg>"
    //                     )
    //                 )
    //             ),
    //             '" /><feBlend mode="overlay" in="p0" in2="p1" /><feBlend mode="exclusion" in2="p2" /><feBlend mode="overlay" in2="p3" result="blendOut" /><feGaussianBlur ',
    //             'in="blendOut" stdDeviation="42" /></filter> <clipPath id="corners"><rect width="290" height="500" rx="42" ry="42" /></clipPath>',
    //             '<path id="text-path-a" d="M40 12 H250 A28 28 0 0 1 278 40 V460 A28 28 0 0 1 250 488 H40 A28 28 0 0 1 12 460 V40 A28 28 0 0 1 40 12 z" />',
    //             '<path id="minimap" d="M234 444C234 457.949 242.21 463 253 463" />',
    //             '<filter id="top-region-blur"><feGaussianBlur in="SourceGraphic" stdDeviation="24" /></filter>',
    //             '<linearGradient id="grad-up" x1="1" x2="0" y1="1" y2="0"><stop offset="0.0" stop-color="white" stop-opacity="1" />',
    //             '<stop offset=".9" stop-color="white" stop-opacity="0" /></linearGradient>',
    //             '<linearGradient id="grad-down" x1="0" x2="1" y1="0" y2="1"><stop offset="0.0" stop-color="white" stop-opacity="1" /><stop offset="0.9" stop-color="white" stop-opacity="0" /></linearGradient>',
    //             '<mask id="fade-up" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-up)" /></mask>',
    //             '<mask id="fade-down" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-down)" /></mask>',
    //             '<mask id="none" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="white" /></mask>',
    //             '<linearGradient id="grad-symbol"><stop offset="0.7" stop-color="white" stop-opacity="1" /><stop offset=".95" stop-color="white" stop-opacity="0" /></linearGradient>',
    //             '<mask id="fade-symbol" maskContentUnits="userSpaceOnUse"><rect width="290px" height="200px" fill="url(#grad-symbol)" /></mask></defs>',
    //             '<g clip-path="url(#corners)">',
    //             '<rect fill="',
    //             params.color0,
    //             '" x="0px" y="0px" width="290px" height="500px" />',
    //             '<rect style="filter: url(#f1)" x="0px" y="0px" width="290px" height="500px" />',
    //             ' <g style="filter:url(#top-region-blur); transform:scale(1.5); transform-origin:center top;">',
    //             '<rect fill="none" x="0px" y="0px" width="290px" height="500px" />',
    //             '<ellipse cx="50%" cy="0px" rx="180px" ry="120px" fill="#000" opacity="0.85" /></g>',
    //             '<rect x="0" y="0" width="290" height="500" rx="42" ry="42" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)" /></g>'
    //         )
    //     );
    // }

    // function generateSVGBorderText(
    //     string memory quoteToken,
    //     string memory baseToken,
    //     string memory quoteTokenSymbol,
    //     string memory baseTokenSymbol
    // ) private pure returns (string memory svg) {
    //     svg = string(
    //         abi.encodePacked(
    //             '<text text-rendering="optimizeSpeed">',
    //             '<textPath startOffset="-100%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
    //             baseToken,
    //             unicode' • ',
    //             baseTokenSymbol,
    //             ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" />',
    //             '</textPath> <textPath startOffset="0%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
    //             baseToken,
    //             unicode' • ',
    //             baseTokenSymbol,
    //             ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /> </textPath>',
    //             '<textPath startOffset="50%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
    //             quoteToken,
    //             unicode' • ',
    //             quoteTokenSymbol,
    //             ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s"',
    //             ' repeatCount="indefinite" /></textPath><textPath startOffset="-50%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
    //             quoteToken,
    //             unicode' • ',
    //             quoteTokenSymbol,
    //             ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>'
    //         )
    //     );
    // }

    // function generateSVGCardMantle(
    //     string memory quoteTokenSymbol,
    //     string memory baseTokenSymbol,
    //     string memory feeTier
    // ) private pure returns (string memory svg) {
    //     svg = string(
    //         abi.encodePacked(
    //             '<g mask="url(#fade-symbol)"><rect fill="none" x="0px" y="0px" width="290px" height="200px" /> <text y="70px" x="32px" fill="white" font-family="\'Courier New\', monospace" font-weight="200" font-size="36px">',
    //             quoteTokenSymbol,
    //             '/',
    //             baseTokenSymbol,
    //             '</text><text y="115px" x="32px" fill="white" font-family="\'Courier New\', monospace" font-weight="200" font-size="36px">',
    //             feeTier,
    //             '</text></g>',
    //             '<rect x="16" y="16" width="258" height="468" rx="26" ry="26" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)" />'
    //         )
    //     );
    // }

    // function generageSvgCurve(
    //     int24 tickLower,
    //     int24 tickUpper,
    //     int24 tickSpacing,
    //     int8 overRange
    // ) private pure returns (string memory svg) {
    //     string memory fade = overRange == 1 ? '#fade-up' : overRange == -1 ? '#fade-down' : '#none';
    //     string memory curve = getCurve(tickLower, tickUpper, tickSpacing);
    //     svg = string(
    //         abi.encodePacked(
    //             '<g mask="url(',
    //             fade,
    //             ')"',
    //             ' style="transform:translate(72px,189px)">'
    //             '<rect x="-16px" y="-16px" width="180px" height="180px" fill="none" />'
    //             '<path d="',
    //             curve,
    //             '" stroke="rgba(0,0,0,0.3)" stroke-width="32px" fill="none" stroke-linecap="round" />',
    //             '</g><g mask="url(',
    //             fade,
    //             ')"',
    //             ' style="transform:translate(72px,189px)">',
    //             '<rect x="-16px" y="-16px" width="180px" height="180px" fill="none" />',
    //             '<path d="',
    //             curve,
    //             '" stroke="rgba(255,255,255,1)" fill="none" stroke-linecap="round" /></g>',
    //             generateSVGCurveCircle(overRange)
    //         )
    //     );
    // }

    // function getCurve(
    //     int24 tickLower,
    //     int24 tickUpper,
    //     int24 tickSpacing
    // ) internal pure returns (string memory curve) {
    //     int24 tickRange = (tickUpper - tickLower) / tickSpacing;
    //     if (tickRange <= 4) {
    //         curve = curve1;
    //     } else if (tickRange <= 8) {
    //         curve = curve2;
    //     } else if (tickRange <= 16) {
    //         curve = curve3;
    //     } else if (tickRange <= 32) {
    //         curve = curve4;
    //     } else if (tickRange <= 64) {
    //         curve = curve5;
    //     } else if (tickRange <= 128) {
    //         curve = curve6;
    //     } else if (tickRange <= 256) {
    //         curve = curve7;
    //     } else {
    //         curve = curve8;
    //     }
    // }

    // function generateSVGCurveCircle(int8 overRange) internal pure returns (string memory svg) {
    //     string memory curvex1 = '73';
    //     string memory curvey1 = '190';
    //     string memory curvex2 = '217';
    //     string memory curvey2 = '334';
    //     if (overRange == 1 || overRange == -1) {
    //         svg = string(
    //             abi.encodePacked(
    //                 '<circle cx="',
    //                 overRange == -1 ? curvex1 : curvex2,
    //                 'px" cy="',
    //                 overRange == -1 ? curvey1 : curvey2,
    //                 'px" r="4px" fill="white" /><circle cx="',
    //                 overRange == -1 ? curvex1 : curvex2,
    //                 'px" cy="',
    //                 overRange == -1 ? curvey1 : curvey2,
    //                 'px" r="24px" fill="none" stroke="white" />'
    //             )
    //         );
    //     } else {
    //         svg = string(
    //             abi.encodePacked(
    //                 '<circle cx="',
    //                 curvex1,
    //                 'px" cy="',
    //                 curvey1,
    //                 'px" r="4px" fill="white" />',
    //                 '<circle cx="',
    //                 curvex2,
    //                 'px" cy="',
    //                 curvey2,
    //                 'px" r="4px" fill="white" />'
    //             )
    //         );
    //     }
    // }

    // function generateSVGPositionDataAndLocationCurve(
    //     string memory tokenId,
    //     int24 tickLower,
    //     int24 tickUpper
    // ) private pure returns (string memory svg) {
    //     string memory tickLowerStr = tickToString(tickLower);
    //     string memory tickUpperStr = tickToString(tickUpper);
    //     uint256 str1length = bytes(tokenId).length + 4;
    //     uint256 str2length = bytes(tickLowerStr).length + 10;
    //     uint256 str3length = bytes(tickUpperStr).length + 10;
    //     (string memory xCoord, string memory yCoord) = rangeLocation(tickLower, tickUpper);
    //     svg = string(
    //         abi.encodePacked(
    //             ' <g style="transform:translate(29px, 384px)">',
    //             '<rect width="',
    //             uint256(7 * (str1length + 4)).toString(),
    //             'px" height="26px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)" />',
    //             '<text x="12px" y="17px" font-family="\'Courier New\', monospace" font-size="12px" fill="white"><tspan fill="rgba(255,255,255,0.6)">ID: </tspan>',
    //             tokenId,
    //             '</text></g>',
    //             ' <g style="transform:translate(29px, 414px)">',
    //             '<rect width="',
    //             uint256(7 * (str2length + 4)).toString(),
    //             'px" height="26px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)" />',
    //             '<text x="12px" y="17px" font-family="\'Courier New\', monospace" font-size="12px" fill="white"><tspan fill="rgba(255,255,255,0.6)">Min Tick: </tspan>',
    //             tickLowerStr,
    //             '</text></g>',
    //             ' <g style="transform:translate(29px, 444px)">',
    //             '<rect width="',
    //             uint256(7 * (str3length + 4)).toString(),
    //             'px" height="26px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)" />',
    //             '<text x="12px" y="17px" font-family="\'Courier New\', monospace" font-size="12px" fill="white"><tspan fill="rgba(255,255,255,0.6)">Max Tick: </tspan>',
    //             tickUpperStr,
    //             '</text></g>'
    //             '<g style="transform:translate(226px, 433px)">',
    //             '<rect width="36px" height="36px" rx="8px" ry="8px" fill="none" stroke="rgba(255,255,255,0.2)" />',
    //             '<path stroke-linecap="round" d="M8 9C8.00004 22.9494 16.2099 28 27 28" fill="none" stroke="white" />',
    //             '<circle style="transform:translate3d(',
    //             xCoord,
    //             'px, ',
    //             yCoord,
    //             'px, 0px)" cx="0px" cy="0px" r="4px" fill="white"/></g>'
    //         )
    //     );
    // }

    // function tickToString(int24 tick) private pure returns (string memory) {
    //     string memory sign = '';
    //     if (tick < 0) {
    //         tick = tick * -1;
    //         sign = '-';
    //     }
    //     return string(abi.encodePacked(sign, uint256(tick).toString()));
    // }

    // function rangeLocation(int24 tickLower, int24 tickUpper) internal pure returns (string memory, string memory) {
    //     int24 midPoint = (tickLower + tickUpper) / 2;
    //     if (midPoint < -125_000) {
    //         return ('8', '7');
    //     } else if (midPoint < -75_000) {
    //         return ('8', '10.5');
    //     } else if (midPoint < -25_000) {
    //         return ('8', '14.25');
    //     } else if (midPoint < -5_000) {
    //         return ('10', '18');
    //     } else if (midPoint < 0) {
    //         return ('11', '21');
    //     } else if (midPoint < 5_000) {
    //         return ('13', '23');
    //     } else if (midPoint < 25_000) {
    //         return ('15', '25');
    //     } else if (midPoint < 75_000) {
    //         return ('18', '26');
    //     } else if (midPoint < 125_000) {
    //         return ('21', '27');
    //     } else {
    //         return ('24', '27');
    //     }
    // }

    // function generateSVGRareSparkle(uint256 tokenId, address poolAddress) private pure returns (string memory svg) {
    //     if (isRare(tokenId, poolAddress)) {
    //         svg = string(
    //             abi.encodePacked(
    //                 '<g style="transform:translate(226px, 392px)"><rect width="36px" height="36px" rx="8px" ry="8px" fill="none" stroke="rgba(255,255,255,0.2)" />',
    //                 '<g><path style="transform:translate(6px,6px)" d="M12 0L12.6522 9.56587L18 1.6077L13.7819 10.2181L22.3923 6L14.4341 ',
    //                 '11.3478L24 12L14.4341 12.6522L22.3923 18L13.7819 13.7819L18 22.3923L12.6522 14.4341L12 24L11.3478 14.4341L6 22.39',
    //                 '23L10.2181 13.7819L1.6077 18L9.56587 12.6522L0 12L9.56587 11.3478L1.6077 6L10.2181 10.2181L6 1.6077L11.3478 9.56587L12 0Z" fill="white" />',
    //                 '<animateTransform attributeName="transform" type="rotate" from="0 18 18" to="360 18 18" dur="10s" repeatCount="indefinite"/></g></g>'
    //             )
    //         );
    //     } else {
    //         svg = '';
    //     }
    // }

    // function isRare(uint256 tokenId, address poolAddress) internal pure returns (bool) {
    //     bytes32 h = keccak256(abi.encodePacked(tokenId, poolAddress));
    //     return uint256(h) < type(uint256).max / (1 + BitMath.mostSignificantBit(tokenId) * 2);
    // }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

import "../plans/IPlanManager.sol";
import "../merchants/IMerchantToken.sol";
import "./ISubInfoManager.sol";
import "../libs/JsonWriter.sol";
import "./NFTSVG.sol";
import "../libs/Period.sol";
import "./ISubTokenDescriptor.sol";
import {BokkyPooBahsDateTimeLibrary as TimeLib} from "../libs/BokkyPooBahsDateTimeLibrary.sol";

contract SubTokenDescriptor is ISubTokenDescriptor {

    using JsonWriter for JsonWriter.Json;

    function tokenURI(address merchantToken, address planManager, address subInfoManager, uint256 tokenId) external view override returns (string memory) {

        // get sub info

//        SubInfo memory subInfo = getSubInfo(tokenId);
        ISubInfoManager.SubInfo memory subInfo = ISubInfoManager(subInfoManager).getSubInfo(tokenId);


        // get plan info
//        PlanInfo memory planInfo = getPlanInfo(subInfo.merchantTokenId, subInfo.planIndex);
        IPlanManager.Plan memory plan = IPlanManager(planManager).getPlan(subInfo.merchantTokenId, subInfo.planIndex);

        NFTSVG.SVGParams memory svgParams =
        NFTSVG.SVGParams({
            merchantCode: subInfo.merchantTokenId,
            merchantName: "merchant name",
            planName: plan.name,
            planPeriod: Period.getPeriodName(plan.billingPeriod),
            paymentTokenName: "TestToken",

        // sub info
            startDateTime: Period.convertTimestampToDateTimeString(subInfo.subStartTime),
            endDateTime: Period.convertTimestampToDateTimeString(subInfo.subEndTime),
            nextBillDateTime: Period.convertTimestampToDateTimeString(subInfo.nextBillingTime),
//            termDateTime: Period.convertTimestampToDateTimeString(subInfo.termEndTime),
            price: plan.pricePerBillingPeriod
        });

        string memory image = NFTSVG.generateSVG(svgParams);

        JsonWriter.Json memory writer;
        writer.writeStartObject();
        writer.writeStringProperty("name", "s10n sub token");
        writer.writeStringProperty("description", "token for s10 sub");
        writer.writeStringProperty("image", image);
        writer.writeStartArray("attributes");
        writer.writeStartObject();
        writer.writeStringProperty("trait_type", "plan_name");
        writer.writeStringProperty("value", plan.name);
        writer.writeEndObject();
        writer.writeEndArray();
        writer.writeEndObject();
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(writer.value))));
    }
}