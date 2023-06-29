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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITranslator {
    function ownerOf(uint256 tokenId) external view returns (address);

    function translatedCount(address who) external view returns (uint256);

    function publicTranslation(address to) external;

    function burnTranslation(address to) external;
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

interface ITRMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

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
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

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
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
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
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./BytesLib.sol";

library MyStrings {
    using BytesLib for bytes;


    function strlen(string memory s) internal pure returns (uint256 len, uint256 bytelength) {
        uint256 i = 0;
        bytelength = bytes(s).length;

        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
    }

    // require(maxlength %3 == 0)
    function shorten(string memory origin, uint256 maxlength)
        internal
        pure
        returns (string memory)
    {
        bytes memory b = bytes(origin);
        uint256 len = b.length;

        if (len <= maxlength) return origin;

        bytes memory part = b.slice(0, maxlength);
        string memory ellipse = "...";

        return string(abi.encodePacked(string(part), ellipse));
    }

}

pragma solidity ^0.8.0;

import "./interface/ITRMetadata.sol";
import "./interface/ITranslator.sol";
import "./libs/MyStrings.sol";
import "base64-sol/base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libs/DateTimeLibrary.sol";

contract TRMetadata is ITRMetadata {
    using MyStrings for string;
    using BytesLib for bytes;

    string public background;
    ITranslator public translator;

    constructor(address _translator) {
        translator = ITranslator(_translator);
    }

    function tokenURI(
        uint256 tokenId
    ) external view override returns (string memory) {
        string memory svg = generateSVG(tokenId);
        return generateTokenUri(svg);
    }

    // TODO: 生成一个SVG文件放到项目中，方便预览效果
    function generateSVG(
        uint tokenId
    ) internal view returns (string memory svg) {
        address owner = translator.ownerOf(tokenId);
        uint256 count = translator.translatedCount(owner);
        return
            string(
                abi.encodePacked(
                    '<svg id="l_1" data-name="l 1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 131 190.43">',
                    "<defs>",
                    '<linearGradient id="a" x1="12.95" y1="1982" x2="74.24" y2="2001.2" gradientTransform="translate(0 -1807.55)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#0e2e5f"/><stop offset="1" stop-color="#2f76d8"/></linearGradient>',
                    '<linearGradient id="a_2" x1="125.35" y1="1976.67" x2="58.58" y2="2001.64" xlink:href="#a"/>',
                    '<linearGradient id="a_3" y1="1893.21" x2="131" y2="1893.21" gradientTransform="translate(0 -1807.55)" gradientUnits="userSpaceOnUse"><stop offset=".01" stop-color="#ebcd88"/><stop offset=".19" stop-color="#f0db96"/><stop offset=".41" stop-color="#f8f3e6"/><stop offset=".73" stop-color="#bf8b30"/><stop offset=".95" stop-color="#e9c98c"/><stop offset=".95" stop-color="#eaca8d"/></linearGradient>',
                    '<linearGradient id="a_4" x1="50.92" y1="1835.41" x2="79.64" y2="1835.41" xlink:href="#a_3"/>',
                    '<linearGradient id="a_5" x1="53.51" y1="1835.43" x2="77.03" y2="1835.43" gradientTransform="translate(0 -1807.55)" gradientUnits="userSpaceOnUse"><stop offset=".01" stop-color="#2869c3"/><stop offset=".01" stop-color="#0e2e5f"/><stop offset=".47" stop-color="#347ee3"/><stop offset=".62" stop-color="#347ee3"/><stop offset=".81" stop-color="#347ee3"/><stop offset="1" stop-color="#0e2e5f"/></linearGradient>',
                    '<linearGradient id="a_6" y1="1835.43" y2="1835.43" xlink:href="#a_3"/>',
                    '<linearGradient id="a_7" x1="74" y1="1846.72" x2="84.58" y2="1846.72" xlink:href="#a_3"/>',
                    '<linearGradient id="a_8" x1="46.1" y1="1846.72" x2="56.68" y2="1846.72" xlink:href="#a_3"/>',
                    '<linearGradient id="a_9" x1="51.39" y1="1843.86" x2="79.29" y2="1843.86" xlink:href="#a_3"/>',
                    "<style>.cs1,.cs5,.cs6{isolation:isolate}.cs6{fill:#333;stroke:#333;stroke-width:.1px;stroke-miterlimit:10;font-family:PingFangSC-Light-GBpc-EUC-H,PingFang SC}.cs5{fill:#4d4d4d;font-family:PingFangSC-Thin-GBpc-EUC-H,PingFang SC}.cs5,.cs6{font-size:3.32px;letter-spacing:.07em}.cs1{fill:#36382e;font-family:PingFangSC-Medium-GBpc-EUC-H,PingFang SC;font-size:2.6px}</style></defs>",
                    '<path style="fill:#fff" d="M.14 0H131v190.43H.14z"/>',
                    '<path style="fill:url(#a)" d="m0 150.36 125.28 40.07H0v-40.07z"/><path style="fill:url(#a_2)" d="M131 150.36 5.72 190.43H131v-40.07z"/>',
                    '<text transform="translate(28.41 63.21)" style="font-family:PingFangSC-Light-GBpc-EUC-H,PingFang SC;stroke-miterlimit:10;stroke:#333;stroke-width:.1px;fill:#333;font-size:8.37px;letter-spacing:.07em;isolation:isolate">',
                    unicode"翻译作品存证证书",
                    "</text>",
                    '<text transform="translate(25.87 70.45)" style="font-family:PingFangSC-Thin-GBpc-EUC-H,PingFang SC;fill:#4d4d4d;font-size:4.21px;letter-spacing:.08em;isolation:isolate">CERTIFICATE OF ORIGINAL WORK</text><text transform="translate(35.83 147.36)" style="font-size:3.82px;letter-spacing:.03em;font-family:PingFangSC-Light-GBpc-EUC-H,PingFang SC;fill:#333;isolation:isolate">',
                    unicode"登链社区 - 中文区块链技术社区",
                    "</text>",
                    '<text transform="translate(40.47 151.15)" style="font-size:1.72px;letter-spacing:.02em;fill:#4d4d4d;font-family:PingFangSC-Light-GBpc-EUC-H,PingFang SC;isolation:isolate">Upchain Commutity - Chinese blockchain dev community</text><path style="fill:url(#a_3)" d="M65.82 171.31 131 150.36l-.14-11.11V0H.14v147.41L0 150.36l65.5 20.95-62.25-33.22V3.12h124.5V139.1l-61.93 32.21z"/><path d="M79.64 27.88c0 .68-.62 1.31-.72 2s.33 1.45.14 2.09-1 1.07-1.24 1.68-.1 1.48-.46 2-1.23.75-1.67 1.26-.5 1.39-1 1.83-1.39.38-2 .74-.88 1.19-1.49 1.52-1.44 0-2.08.16-1.17.9-1.85 1-1.36-.44-2-.44-1.39.53-2 .44-1.2-.81-1.84-1-1.43.07-2.08-.16-.93-1.11-1.49-1.47-1.45-.3-2-.74-.58-1.33-1-1.83-1.3-.7-1.66-1.26-.18-1.43-.46-2-1.06-1-1.25-1.68.24-1.42.14-2.09-.71-1.28-.71-2 .62-1.31.71-2-.32-1.45-.14-2.08 1-1.08 1.25-1.68.09-1.48.46-2.05 1.23-.75 1.67-1.26.5-1.39 1-1.83 1.39-.37 2-.74.87-1.19 1.49-1.47 1.43 0 2.08-.16 1.17-.9 1.84-1 1.37.43 2 .43 1.39-.53 2-.43 1.21.8 1.85 1 1.48-.12 2.08.16.92 1.11 1.49 1.47 1.45.31 2 .74.57 1.33 1 1.84 1.31.69 1.67 1.26.18 1.42.46 2 1 1 1.24 1.68-.23 1.41-.14 2.08.71 1.31.71 1.99Z" style="fill:url(#a_4)"/><circle cx="65.27" cy="27.88" r="11.76" style="stroke-width:.16px;fill:url(#a_5);stroke:url(#a_6);stroke-miterlimit:10"/><path d="M79.21 35.78s4 .83 5.37 1.73L82.1 39.3l.9 3.6c-2.47-1.35-9-2.45-9-2.45l1.13-5Z" style="fill:url(#a_7)"/><path d="M51.47 35.78s-4 .83-5.37 1.73l2.48 1.79-.9 3.6c2.47-1.35 9-2.47 9-2.47l-1.13-5Z" style="fill:url(#a_8)"/><path d="M51.39 34.45a55 55 0 0 1 27.9 0L78.5 40a53.13 53.13 0 0 0-26.1 0Z" style="fill:url(#a_9)"/><path d="M61.1 24.51a5 5 0 0 1-.45 1.3H62c-.18-.4-.32-.82-.48-1.28h1.18v.06a.43.43 0 0 1 0 .35h-.55l.06.17h.66v.06a.32.32 0 0 1 0 .37h-.45c.27.57 1.29 2.28 1.17 3l-.13.12a.3.3 0 0 1-.38-.14l-.33-1.07-.33-.85v2.61H62v.24a.71.71 0 0 1 .43.08.45.45 0 0 1 0 .28H65V28a.21.21 0 0 1-.19 0v-.22H65v-.42h-.2v-.13c-.25.43-.25 1.13-.6 1.47H64a10 10 0 0 1 1-2.9h.15c.16.09 0 .28 0 .42s.23 0 .28 0v.23h-.36l-.24.6a2.58 2.58 0 0 1 .68 0v.19h-.23v.42h.24a.24.24 0 0 1 0 .23h-.21v1.8H66v-2.5h-.3a.24.24 0 0 1 0-.26h.57v2.46h1a.45.45 0 0 1 0-.28 1.89 1.89 0 0 1-.75 0V29h.7v-.2a1.2 1.2 0 0 1-.77-.14A10.94 10.94 0 0 1 67 26.5c-.14 0-.29 0-.34-.06s0-.11 0-.2h.47a.87.87 0 0 1 .22-.45h.15v.05a.72.72 0 0 1-.07.38 1.78 1.78 0 0 1 .69.05v.18h-.82l-.64 2h.47a4.37 4.37 0 0 1 0-1.35.24.24 0 0 1 .23 0v1.35a1.68 1.68 0 0 1 .77.08.33.33 0 0 1-.06.19h-.71v.19a2.24 2.24 0 0 1 .73 0 .25.25 0 0 1 0 .24h-.69a.35.35 0 0 1-.06.28 2.62 2.62 0 0 1 .79 0 .58.58 0 0 1 0 .32h1.15v-2.52c0-.34-.07-.82.11-1H69c.11.08.06.42.06.6a7.47 7.47 0 0 1 0 1.89h-.26v-2.46l-.17-.15v-.17l.11-.12a5.26 5.26 0 0 1 1.68.06.49.49 0 0 1 0 .24.2.2 0 0 1-.18.12 9.59 9.59 0 0 1 0 2.51.26.26 0 0 1-.24 0 9.36 9.36 0 0 1 .08-2.48h-.45c.19.09.11.6.11.88v2.7h.66a.34.34 0 0 1 .07-.36h.86v-.76h-.69v-.28h.71v-1.71a1.51 1.51 0 0 1 .06-.56h.21v2.27c.18 0 .65-.05.73.06v.21h-.73v.73a2.84 2.84 0 0 1 .92 0 .58.58 0 0 1 0 .32h.4v-3.6h1.89c.18 0 .56-.06.64 0a.14.14 0 0 1 0 .17h-2.26v3h1.86a4.66 4.66 0 0 1-.66-1.09h-.07a4.15 4.15 0 0 1-.75 1.15h-.14c0-.56.66-.78.74-1.3-.13-.23-.76-.9-.66-1.18h.07c.18.18.61 1 .77 1a2.3 2.3 0 0 1 .71-1h.12c0 .46-.51.83-.7 1.18.14.22.74 1.13.64 1.35.28 0 .41 0 .4.31l-.19.24h-18.9c-.19-.2-.74-.49-.57-.73L57.29 28a.59.59 0 0 0 .19-.5c-.08-.34-.47-.39-.62-.64.23-.25.61-.46.49-.94a2.58 2.58 0 0 0-.87-.45v3.19h-1V25l1-.43c.32-.08.63.17.84.26.94.41 1.65.86.85 1.92a1 1 0 0 1 .32 1.3c-.34.74-1.21 1.15-1.71 1.76h3.46a.34.34 0 0 1 0-.34h.36v-.28h-.37v-2.57c-.29.42-.44 2-1 2.06-.07 0-.11-.05-.15-.13-.13-.26.07-.67.15-.86a22 22 0 0 1 .94-2.18h-.43v-.06c-.08-.11 0-.27 0-.37h.62v-.17H60c-.09-.14 0-.25 0-.38Zm8.07.62a1.67 1.67 0 0 1 .7.06v.2l-.06.15h-.64v-.09a.31.31 0 0 1 0-.32ZM56 25.15v.41h.38v-.41Zm-.41.47v.43H56v-.43Zm5 .37-.12.25h1.77l-.11-.24a5.17 5.17 0 0 1-1.57 0Zm-4.15.58v-.41H56v.41Zm9.33-.33a.66.66 0 0 1 .34.05v.16h-.38v-.13Zm-5.18.26v2.42h1.57V26.5Zm-5 .15v.43H56v-.43Zm.43.49v.43h.4v-.43Zm-.43.47V28H56v-.41Zm.45.47v.37h.4V28Zm5.11 1.12v.25h.43v-.28Z" style="fill-rule:evenodd;fill:#fff"/><circle id="cs" cx="65.89" cy="26.37" r=".23" style="fill:#fff"/><text class="cs1" transform="rotate(-9.18 259.366 -341.853)">U</text><text class="cs1" transform="matrix(.99 -.11 .11 .99 60.24 36.63)">P</text><text class="cs1" transform="rotate(-2.95 738.225 -1194.061)">C</text><text class="cs1" transform="translate(64.81 36.3)">H</text><text class="cs1" transform="rotate(4.17 -465.354 941.085)">A</text><text class="cs1" transform="matrix(.99 .12 -.12 .99 69.46 36.53)">I</text><text class="cs1" transform="rotate(10.41 -165.923 405.782)">N</text>',
                    '<text class="cs5" transform="translate(24.19 105.59)">',
                    unicode"TokenID：",
                    "</text>",
                    '<text class="cs6" transform="translate(41.6 105.59)" >',
                    Strings.toString(count),
                    "</text>",
                    "</svg>"
                )
            );
    }

    function generateTokenUri(
        string memory svg
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"image": "',
                                "data:image/svg+xml;base64,",
                                Base64.encode(bytes(svg)),
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}