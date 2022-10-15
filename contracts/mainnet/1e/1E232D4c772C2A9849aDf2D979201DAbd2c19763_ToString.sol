// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

import {DateTimeParts, Epoch, Quarters, dateTimeParts} from "./DateTime.sol";

library ToString {
    /**
     * Convert the given boolean value to string (ie. "true" / "false")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bool value) public pure returns (string memory) {
        return value ? "true" : "false";
    }

    /**
     * Convert the given uint value to string
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(uint256 value) public pure returns (string memory) {
        return toString(value, 0);
    }

    /**
     * Convert the given uint value to string, where as many decimal digits are used as given
     *
     * @param value  The value to convert to string
     * @param decimals  The number of decimal places to use
     * @return  The resulting string
     */
    function toString(uint256 value, uint8 decimals) public pure returns (string memory) {
        unchecked {
            bytes10 DEC_DIGITS = "0123456789";

            bytes memory buffer = "00000000000000000000000000000000000000000000000000000000000000000000000000000.";  // buffer.length = 78
            uint8 i = 78;

            // remove trailing 0s
            while ((0 < decimals) && (value % 10 == 0)) {
                value /= 10;
                decimals--;
            }
            // if there are remaining decimals to write, do so
            if (0 < decimals) {
                while (0 < decimals) {
                    buffer[--i] = DEC_DIGITS[value % 10];
                    value /= 10;
                    decimals--;
                }
                buffer[--i] = '.';
            }
            // output a 0 in case nothing left
            if (value == 0) {
                buffer[--i] = DEC_DIGITS[0];
            } else {
                while (value != 0) {
                    buffer[--i] = DEC_DIGITS[value % 10];
                    value /= 10;
                }
            }
            // transfer result from buffer
            bytes memory result = new bytes(78 - i);
            uint8 j = 0;
            while (i < 78) {
                result[j++] = buffer[i++];
            }
            return string(result);
        }
    }

    /**
     * Convert the given int value to string
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(int256 value) public pure returns (string memory) {
        return toString(value, 0);
    }

    /**
     * Convert the given int value to string, where as many decimal digits are used as given
     *
     * @param value  The value to convert to string
     * @param decimals  The number of decimal places to use
     * @return  The resulting string
     */
    function toString(int256 value, uint8 decimals) public pure returns (string memory) {
        unchecked {
            if (value < 0) {
                return string.concat('-', toString(value == type(int256).min ? 1 + type(uint256).max >> 1 : uint256(-value), decimals));
            } else {
                return toString(uint256(value), decimals);
            }
        }
    }

    /**
     * Convert the given bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes memory value) public pure returns (string memory) {
        unchecked {
            bytes16 HEX_DIGITS = "0123456789abcdef";

            uint256 len = value.length;
            bytes memory buffer = new bytes(len * 2 + 2);

            buffer[0] = '[';
            for ((uint256 i, uint256 j, uint256 k) = (0, 1, 2); i < len; (i, j, k) = (i + 1, j + 2, k + 2)) {
                uint8 val = uint8(value[i]);
                (buffer[j], buffer[k]) = (HEX_DIGITS[val >> 4], HEX_DIGITS[val & 0x0f]);
            }
            buffer[len * 2 + 1] = ']';

            return string(buffer);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes1 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes2 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes3 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes4 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes5 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes6 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes7 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes8 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes9 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes10 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes11 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes12 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes13 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes14 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes15 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes16 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes17 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes18 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes19 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes20 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes21 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes22 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes23 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes24 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes25 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes26 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes27 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes28 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes29 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes30 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes31 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given fixed-size bytes value to string (ie. "[...]")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(bytes32 value) public pure returns (string memory) {
        unchecked {
            bytes memory temp = new bytes(value.length);
            for (uint8 i = 0; i < value.length; i++) temp[i] = value[i];
            return toString(temp);
        }
    }

    /**
     * Convert the given address value to string (ie. "<...>")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(address value) public pure returns (string memory) {
        unchecked {
            bytes16 HEX_DIGITS = "0123456789abcdef";

            bytes20 nValue = bytes20(value);
            bytes memory buffer = new bytes(42);
            buffer[0] = '<';
            for ((uint256 i, uint256 j, uint256 k) = (0, 1, 2); i < 20; (i, j, k) = (i + 1, j + 2, k + 2)) {
                uint8 val = uint8(nValue[i]);
                (buffer[j], buffer[k]) = (HEX_DIGITS[val >> 4], HEX_DIGITS[val & 0x0f]);
            }
            buffer[41] = '>';
            return string(buffer);
        }
    }

    /**
     * Convert the given epoch value to ISO8601 format (ie. "0000-00-00T00:00:00Z")
     *
     * @param value  The value to convert to string
     * @return  The resulting string
     */
    function toString(Epoch value) public pure returns (string memory) {
        return toString(value, Quarters.wrap(0));
    }

    /**
     * Convert the given epoch value to ISO8601 format (ie. "0000-00-00T00:00:00+00:00")
     *
     * @param value  The value to convert to string
     * @param tzOffset  The number of quarters-of-an-hour to offset
     * @return  The resulting string
     */
    function toString(Epoch value, Quarters tzOffset) public pure returns (string memory) {
        unchecked {
            bytes10 DEC_DIGITS = "0123456789";

            DateTimeParts memory parts = dateTimeParts(value, tzOffset);

            bytes memory buffer = "0000-00-00T00:00:00";

            buffer[0] = DEC_DIGITS[(parts.year / 1000) % 10];
            buffer[1] = DEC_DIGITS[(parts.year / 100) % 10];
            buffer[2] = DEC_DIGITS[(parts.year / 10) % 10];
            buffer[3] = DEC_DIGITS[parts.year % 10];
            //
            buffer[5] = DEC_DIGITS[(parts.month / 10) % 10];
            buffer[6] = DEC_DIGITS[parts.month % 10];
            //
            buffer[8] = DEC_DIGITS[(parts.day / 10) % 10];
            buffer[9] = DEC_DIGITS[parts.day % 10];
            //
            buffer[11] = DEC_DIGITS[(parts.hour / 10) % 10];
            buffer[12] = DEC_DIGITS[parts.hour % 10];
            //
            buffer[14] = DEC_DIGITS[(parts.minute / 10) % 10];
            buffer[15] = DEC_DIGITS[parts.minute % 10];
            //
            buffer[17] = DEC_DIGITS[(parts.second / 10) % 10];
            buffer[18] = DEC_DIGITS[parts.second % 10];

            if (Quarters.unwrap(tzOffset) == 0) {
                return string.concat(string(buffer), "Z");
            } else {
                bytes memory tzBuffer = " 00:00";
                uint8 tzh;
                if (Quarters.unwrap(tzOffset) < 0) {
                    tzBuffer[0] = "-";
                    tzh = uint8(-parts.tzHours);
                } else {
                    tzBuffer[0] = "+";
                    tzh = uint8(parts.tzHours);
                }

                tzBuffer[1] = DEC_DIGITS[(tzh / 10) % 10];
                tzBuffer[2] = DEC_DIGITS[tzh % 10];
                //
                tzBuffer[4] = DEC_DIGITS[(parts.tzMinutes / 10) % 10];
                tzBuffer[5] = DEC_DIGITS[parts.tzMinutes % 10];

                return string.concat(string(buffer), string(tzBuffer));
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.17;

// Type used for UNIX epoch quantities
type Epoch is uint40;

// Type used to represent "quarters-of-an-hour" (used for timezone offset specification)
type Quarters is int8;

/**
 * Set of parts of a date/time value encoded by a given epoch
 *
 * @custom:member year  The year the given epoch encodes
 * @custom:member month  The month the given epoch encodes
 * @custom:member day  The day the given epoch encodes
 * @custom:member hour  The hour the given epoch encodes
 * @custom:member minute  The minute the given epoch encodes
 * @custom:member second  The second the given epoch encodes
 * @custom:member tzHours  The timezone offset hours
 * @custom:member tzMinutes  The timezone offset minutes (always multiple of 15)
 */
struct DateTimeParts {
    uint256 year;
    uint256 month;
    uint256 day;
    uint256 hour;
    uint256 minute;
    uint256 second;
    int8 tzHours;
    uint256 tzMinutes;
}

/**
 * Extract the date/time components from the given epoch value
 *
 * @param value  The value to extract components from
 * @return dateTimeParts  The DateTimeParts the given epoch encodes
 */
function dateTimeParts(Epoch value) pure returns (DateTimeParts memory) {
    return dateTimeParts(value, Quarters.wrap(0));
}

/**
 * Extract the date/time components from the given epoch value and timezone offset
 *
 * Mostly taken from: https://howardhinnant.github.io/date_algorithms.html#civil_from_days
 *
 * @param value  The value to extract components from
 * @param tzOffset  The number of quarters-of-an-hour to offset
 * @return dateTimeParts  The DateTimeParts the given epoch encodes
 */
function dateTimeParts(Epoch value, Quarters tzOffset) pure returns (DateTimeParts memory) {
    unchecked {
        require(-48 <= Quarters.unwrap(tzOffset), "Strings: timezone offset too small");
        require(Quarters.unwrap(tzOffset) <= 56, "Strings: timezone offset too big");

        DateTimeParts memory result;

        int256 tzOffsetInSeconds = int256(Quarters.unwrap(tzOffset)) * 900;
        uint256 nValue;
        if (tzOffsetInSeconds < 0) {
            require(uint256(-tzOffsetInSeconds) <= Epoch.unwrap(value), "Strings: epoch time too small for timezone offset");
            nValue = Epoch.unwrap(value) - uint256(-tzOffsetInSeconds);
        } else {
            nValue = Epoch.unwrap(value) + uint256(tzOffsetInSeconds);
        }

        require(nValue <= 253402311599, "Strings: epoch time too big");

        {
            uint256 z = nValue / 86400 + 719468;
            uint256 era = z / 146097;
            uint256 doe = z - era * 146097;
            uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
            uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
            uint256 mp = (5 * doy + 2) / 153;
            //
            result.year = yoe + era * 400 + (mp == 10 || mp == 11 ? 1 : 0);
            result.month = mp < 10 ? mp + 3 : mp - 9;
            result.day = doy - (153 * mp + 2) / 5 + 1;
        }

        {
            uint256 w = nValue % 86400;
            //
            result.hour = w / 3600;
            result.minute = (w % 3600) / 60;
            result.second = w % 60;
        }

        result.tzHours = int8(tzOffsetInSeconds / 3600);
        result.tzMinutes = uint8((uint256(tzOffsetInSeconds < 0 ? -tzOffsetInSeconds : tzOffsetInSeconds) % 3600) / 60);

        return result;
    }
}