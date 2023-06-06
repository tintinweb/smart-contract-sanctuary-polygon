// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for access related errors.
 */
library AccessError {
    /**
     * @dev Thrown when an address tries to perform an unauthorized action.
     * @param addr The address that attempts the action.
     */
    error Unauthorized(address addr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for address related errors.
 */
library AddressError {
    /**
     * @dev Thrown when a zero address was passed as a function parameter (0x0000000000000000000000000000000000000000).
     */
    error ZeroAddress();

    /**
     * @dev Thrown when an address representing a contract is expected, but no code is found at the address.
     * @param contr The address that was expected to be a contract.
     */
    error NotAContract(address contr);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for initialization related errors.
 */
library InitError {
    /**
     * @dev Thrown when attempting to initialize a contract that is already initialized.
     */
    error AlreadyInitialized();

    /**
     * @dev Thrown when attempting to interact with a contract that has not been initialized yet.
     */
    error NotInitialized();
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title Library for errors related with expected function parameters.
 */
library ParameterError {
    /**
     * @dev Thrown when an invalid parameter is used in a function.
     * @param parameter The name of the parameter.
     * @param reason The reason why the received parameter is invalid.
     */
    error InvalidParameter(string parameter, string reason);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../errors/InitError.sol";

/**
 * @title Mixin for contracts that require initialization.
 */
abstract contract InitializableMixin {
    /**
     * @dev Reverts if contract is not initialized.
     */
    modifier onlyIfInitialized() {
        if (!_isInitialized()) {
            revert InitError.NotInitialized();
        }

        _;
    }

    /**
     * @dev Reverts if contract is already initialized.
     */
    modifier onlyIfNotInitialized() {
        if (_isInitialized()) {
            revert InitError.AlreadyInitialized();
        }

        _;
    }

    /**
     * @dev Override this function to determine if the contract is initialized.
     * @return True if initialized, false otherwise.
     */
    function _isInitialized() internal view virtual returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC165 interface for determining if a contract supports a given interface.
 */
interface IERC165 {
    /**
     * @notice Determines if the contract in question supports the specified interface.
     * @param interfaceID XOR of all selectors in the contract.
     * @return True if the contract supports the specified interface.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC721 non-fungible token (NFT) contract.
 */
interface IERC721 {
    /**
     * @notice Thrown when an address attempts to provide allowance to itself.
     * @param addr The address attempting to provide allowance.
     */
    error CannotSelfApprove(address addr);

    /**
     * @notice Thrown when attempting to transfer a token to an address that does not satisfy IERC721Receiver requirements.
     * @param addr The address that cannot receive the tokens.
     */
    error InvalidTransferRecipient(address addr);

    /**
     * @notice Thrown when attempting to specify an owner which is not valid (ex. the 0x00000... address)
     */
    error InvalidOwner(address addr);

    /**
     * @notice Thrown when attempting to operate on a token id that does not exist.
     * @param id The token id that does not exist.
     */
    error TokenDoesNotExist(uint256 id);

    /**
     * @notice Thrown when attempting to mint a token that already exists.
     * @param id The token id that already exists.
     */
    error TokenAlreadyMinted(uint256 id);

    /**
     * @notice Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @notice Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @notice Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @notice Returns the number of tokens in ``owner``'s account.
     *
     * Requirements:
     *
     * - `holder` must be a valid address
     */
    function balanceOf(address holder) external view returns (uint256 balance);

    /**
     * @notice Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`.
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

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Gives permission to `to` to transfer `tokenId` token to another account.
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
     * @notice Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @notice Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @notice Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./IERC721.sol";

/**
 * @title ERC721 extension with helper functions that allow the enumeration of NFT tokens.
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @notice Thrown calling *ByIndex function with an index greater than the number of tokens existing
     * @param requestedIndex The index requested by the caller
     * @param length The length of the list that is being iterated, making the max index queryable length - 1
     */
    error IndexOverrun(uint requestedIndex, uint length);

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     *
     * Requirements:
     * - `owner` must be a valid address
     * - `index` must be less than the balance of the tokens for the owner
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     *
     * Requirements:
     * - `index` must be less than the total supply of the tokens
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./IERC165.sol";

/**
 * @title Additional metadata for IERC721 tokens.
 */
interface IERC721Metadata is IERC165 {
    /**
     * @notice Retrieves the name of the token, e.g. "Synthetix Account Token".
     * @return A string with the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @notice Retrieves the symbol of the token, e.g. "SNX-ACC".
     * @return A string with the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Retrieves the off-chain URI where the specified token id may contain associated data, such as images, audio, etc.
     * @param tokenId The numeric id of the token in question.
     * @return The URI of the token in question.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/**
 * @title ERC721 extension that allows contracts to receive tokens with `safeTransferFrom`.
 */
interface IERC721Receiver {
    /**
     * @notice Function that will be called by ERC721 tokens implementing the `safeTransferFrom` function.
     * @dev The contract transferring the token will revert if the receiving contract does not implement this function.
     * @param operator The address that is executing the transfer.
     * @param from The address whose token is being transferred.
     * @param tokenId The numeric id of the token being transferred.
     * @param data Optional additional data that may be passed by the operator, and could be used by the implementing contract.
     * @return The selector of this function (IERC721Receiver.onERC721Received.selector). Caller will revert if not returned.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../errors/AccessError.sol";

library OwnableStorage {
    bytes32 private constant _SLOT_OWNABLE_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.Ownable"));

    struct Data {
        address owner;
        address nominatedOwner;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_OWNABLE_STORAGE;
        assembly {
            store.slot := s
        }
    }

    function onlyOwner() internal view {
        if (msg.sender != getOwner()) {
            revert AccessError.Unauthorized(msg.sender);
        }
    }

    function getOwner() internal view returns (address) {
        return OwnableStorage.load().owner;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "../interfaces/IERC721.sol";
import "../interfaces/IERC721Metadata.sol";
import "../interfaces/IERC721Receiver.sol";
import "../errors/AddressError.sol";
import "../errors/AccessError.sol";
import "../errors/InitError.sol";
import "../errors/ParameterError.sol";
import "./ERC721Storage.sol";
import "../utils/AddressUtil.sol";
import "../utils/StringUtil.sol";

/*
 * @title ERC721 non-fungible token (NFT) contract.
 * See IERC721.
 *
 * Reference implementations:
 * - OpenZeppelin - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
 */
contract ERC721 is IERC721, IERC721Metadata {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == this.supportsInterface.selector || // ERC165
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId;
    }

    /**
     * @inheritdoc IERC721
     */
    function balanceOf(address holder) public view virtual override returns (uint balance) {
        if (holder == address(0)) {
            revert InvalidOwner(holder);
        }

        return ERC721Storage.load().balanceOf[holder];
    }

    /**
     * @inheritdoc IERC721
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }

        return ERC721Storage.load().ownerOf[tokenId];
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function name() external view virtual override returns (string memory) {
        return ERC721Storage.load().name;
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function symbol() external view virtual override returns (string memory) {
        return ERC721Storage.load().symbol;
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }

        string memory baseURI = ERC721Storage.load().baseTokenURI;

        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, StringUtil.uintToString(tokenId)))
                : "";
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address to, uint256 tokenId) public virtual override {
        ERC721Storage.Data storage store = ERC721Storage.load();
        address holder = store.ownerOf[tokenId];

        if (to == holder) {
            revert CannotSelfApprove(to);
        }

        if (msg.sender != holder && !isApprovedForAll(holder, msg.sender)) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _approve(to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address operator) {
        if (!_exists(tokenId)) {
            revert TokenDoesNotExist(tokenId);
        }

        return ERC721Storage.load().tokenApprovals[tokenId];
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (msg.sender == operator) {
            revert CannotSelfApprove(operator);
        }

        ERC721Storage.load().operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @inheritdoc IERC721
     */
    function isApprovedForAll(
        address holder,
        address operator
    ) public view virtual override returns (bool) {
        return ERC721Storage.load().operatorApprovals[holder][operator];
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _transfer(from, to, tokenId);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert AccessError.Unauthorized(msg.sender);
        }

        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert InvalidTransferRecipient(to);
        }
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return ERC721Storage.load().ownerOf[tokenId] != address(0);
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address holder = ownerOf(tokenId);

        // Not checking tokenId existence since it is checked in ownerOf() and getApproved()

        return (spender == holder ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(holder, spender));
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();
        if (to == address(0)) {
            revert AddressError.ZeroAddress();
        }

        if (tokenId == 0) {
            revert ParameterError.InvalidParameter("tokenId", "cannot be zero");
        }

        if (_exists(tokenId)) {
            revert TokenAlreadyMinted(tokenId);
        }

        _beforeTransfer(address(0), to, tokenId);

        store.balanceOf[to] += 1;
        store.ownerOf[tokenId] = to;

        _postTransfer(address(0), to, tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();
        address holder = store.ownerOf[tokenId];

        _approve(address(0), tokenId);

        _beforeTransfer(holder, address(0), tokenId);

        store.balanceOf[holder] -= 1;
        delete store.ownerOf[tokenId];

        _postTransfer(holder, address(0), tokenId);

        emit Transfer(holder, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();

        if (ownerOf(tokenId) != from) {
            revert AccessError.Unauthorized(from);
        }

        if (to == address(0)) {
            revert AddressError.ZeroAddress();
        }

        _beforeTransfer(from, to, tokenId);

        // Clear approvals from the previous holder
        _approve(address(0), tokenId);

        store.balanceOf[from] -= 1;
        store.balanceOf[to] += 1;
        store.ownerOf[tokenId] = to;

        _postTransfer(from, to, tokenId);

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        ERC721Storage.load().tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (AddressUtil.isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (
                bytes4 retval
            ) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                return false;
            }
        } else {
            return true;
        }
    }

    function _beforeTransfer(
        address from,
        address to,
        uint256 tokenId // solhint-disable-next-line no-empty-blocks
    ) internal virtual {}

    function _postTransfer(
        address from,
        address to,
        uint256 tokenId // solhint-disable-next-line no-empty-blocks
    ) internal virtual {}

    function _initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseTokenURI
    ) internal virtual {
        ERC721Storage.Data storage store = ERC721Storage.load();
        if (
            bytes(store.name).length > 0 ||
            bytes(store.symbol).length > 0 ||
            bytes(store.baseTokenURI).length > 0
        ) {
            revert InitError.AlreadyInitialized();
        }

        if (bytes(tokenName).length == 0 || bytes(tokenSymbol).length == 0) {
            revert ParameterError.InvalidParameter("name/symbol", "must not be empty");
        }

        store.name = tokenName;
        store.symbol = tokenSymbol;
        store.baseTokenURI = baseTokenURI;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "./ERC721.sol";
import "./ERC721EnumerableStorage.sol";
import "../interfaces/IERC721Enumerable.sol";

/*
 * @title ERC721 extension with helper functions that allow the enumeration of NFT tokens.
 * See IERC721Enumerable
 *
 * Reference implementations:
 * - OpenZeppelin - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721EnumerableStorage.sol
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721Enumerable).interfaceId;
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view virtual override returns (uint256) {
        if (ERC721.balanceOf(owner) <= index) {
            revert IndexOverrun(index, ERC721.balanceOf(owner));
        }
        return ERC721EnumerableStorage.load().ownedTokens[owner][index];
    }

    /**
     * @inheritdoc IERC721Enumerable
     */
    function totalSupply() public view virtual override returns (uint256) {
        return ERC721EnumerableStorage.load().allTokens.length;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        if (index >= ERC721Enumerable.totalSupply()) {
            revert IndexOverrun(index, ERC721Enumerable.totalSupply());
        }
        return ERC721EnumerableStorage.load().allTokens[index];
    }

    function _beforeTransfer(address from, address to, uint256 tokenId) internal virtual override {
        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        ERC721EnumerableStorage.load().ownedTokens[to][length] = tokenId;
        ERC721EnumerableStorage.load().ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        ERC721EnumerableStorage.load().allTokensIndex[tokenId] = ERC721EnumerableStorage
            .load()
            .allTokens
            .length;
        ERC721EnumerableStorage.load().allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = ERC721EnumerableStorage.load().ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = ERC721EnumerableStorage.load().ownedTokens[from][lastTokenIndex];

            ERC721EnumerableStorage.load().ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            ERC721EnumerableStorage.load().ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete ERC721EnumerableStorage.load().ownedTokensIndex[tokenId];
        delete ERC721EnumerableStorage.load().ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721EnumerableStorage.load().allTokens.length - 1;
        uint256 tokenIndex = ERC721EnumerableStorage.load().allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = ERC721EnumerableStorage.load().allTokens[lastTokenIndex];

        ERC721EnumerableStorage.load().allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        ERC721EnumerableStorage.load().allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete ERC721EnumerableStorage.load().allTokensIndex[tokenId];
        ERC721EnumerableStorage.load().allTokens.pop();
    }

    function _initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory baseTokenURI
    ) internal virtual override {
        super._initialize(tokenName, tokenSymbol, baseTokenURI);
        if (ERC721EnumerableStorage.load().allTokens.length > 0) {
            revert InitError.AlreadyInitialized();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library ERC721EnumerableStorage {
    bytes32 private constant _SLOT_ERC721_ENUMERABLE_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.ERC721Enumerable"));

    struct Data {
        mapping(uint256 => uint256) ownedTokensIndex;
        mapping(uint256 => uint256) allTokensIndex;
        mapping(address => mapping(uint256 => uint256)) ownedTokens;
        uint256[] allTokens;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_ERC721_ENUMERABLE_STORAGE;
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library ERC721Storage {
    bytes32 private constant _SLOT_ERC721_STORAGE =
        keccak256(abi.encode("io.synthetix.core-contracts.ERC721"));

    struct Data {
        string name;
        string symbol;
        string baseTokenURI;
        mapping(uint256 => address) ownerOf;
        mapping(address => uint256) balanceOf;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
    }

    function load() internal pure returns (Data storage store) {
        bytes32 s = _SLOT_ERC721_STORAGE;
        assembly {
            store.slot := s
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library AddressUtil {
    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }

        return size > 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

/*
    Reference implementations:
    * OpenZeppelin - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
*/

library StringUtil {
    function uintToString(uint value) internal pure returns (string memory) {
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
            // solhint-disable-next-line numcast/safe-cast
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/interfaces/IERC721Enumerable.sol";

/**
 * @title Module wrapping an ERC721 token implementation.
 */
interface INftModule is IERC721Enumerable {
    /**
     * @notice Returns whether the token has been initialized.
     * @return A boolean with the result of the query.
     */
    function isInitialized() external returns (bool);

    /**
     * @notice Initializes the token with name, symbol, and uri.
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) external;

    /**
     * @notice Allows the owner to mint tokens.
     * @param to The address to receive the newly minted tokens.
     * @param tokenId The ID of the newly minted token
     */
    function mint(address to, uint tokenId) external;

    /**
     * @notice Allows the owner to mint tokens. Verifies that the receiver can receive the token
     * @param to The address to receive the newly minted token.
     * @param tokenId The ID of the newly minted token
     * @param data any data which should be sent to the receiver
     */
    function safeMint(address to, uint256 tokenId, bytes memory data) external;

    /**
     * @notice Allows the owner to burn tokens.
     * @param tokenId The token to burn
     */
    function burn(uint tokenId) external;

    /**
     * @notice Allows an address that holds tokens to provide allowance to another.
     * @param tokenId The token which should be allowed to spender
     * @param spender The address that is given allowance.
     */
    function setAllowance(uint tokenId, address spender) external;

    /**
     * @notice Allows the owner to update the base token URI.
     * @param uri The new base token uri
     */
    function setBaseTokenURI(string memory uri) external;
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

import "@synthetixio/core-contracts/contracts/token/ERC721Enumerable.sol";
import "@synthetixio/core-contracts/contracts/utils/AddressUtil.sol";
import "@synthetixio/core-contracts/contracts/initializable/InitializableMixin.sol";
import "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import "@synthetixio/core-contracts/contracts/errors/AddressError.sol";

import "../storage/Initialized.sol";

import "../interfaces/INftModule.sol";

/**
 * @title Module wrapping an ERC721 token implementation.
 * See INftModule.
 */
contract NftModule is INftModule, ERC721Enumerable, InitializableMixin {
    bytes32 internal constant _INITIALIZED_NAME = "NftModule";

    /**
     * @inheritdoc INftModule
     */
    function isInitialized() external view returns (bool) {
        return _isInitialized();
    }

    /**
     * @inheritdoc INftModule
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) external {
        OwnableStorage.onlyOwner();

        _initialize(tokenName, tokenSymbol, uri);
        Initialized.load(_INITIALIZED_NAME).initialized = true;
    }

    /**
     * @inheritdoc INftModule
     */
    function burn(uint256 tokenId) external override {
        OwnableStorage.onlyOwner();
        _burn(tokenId);
    }

    /**
     * @inheritdoc INftModule
     */
    function mint(address to, uint256 tokenId) external override {
        OwnableStorage.onlyOwner();
        _mint(to, tokenId);
    }

    /**
     * @inheritdoc INftModule
     */
    function safeMint(address to, uint256 tokenId, bytes memory data) external override {
        OwnableStorage.onlyOwner();
        _mint(to, tokenId);

        if (!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert InvalidTransferRecipient(to);
        }
    }

    /**
     * @inheritdoc INftModule
     */
    function setBaseTokenURI(string memory uri) external override {
        OwnableStorage.onlyOwner();
        ERC721Storage.load().baseTokenURI = uri;
    }

    /**
     * @inheritdoc INftModule
     */
    function setAllowance(uint tokenId, address spender) external override {
        OwnableStorage.onlyOwner();
        ERC721Storage.load().tokenApprovals[tokenId] = spender;
    }

    function _isInitialized() internal view override returns (bool) {
        return Initialized.load(_INITIALIZED_NAME).initialized;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11 <0.9.0;

library Initialized {
    struct Data {
        bool initialized;
    }

    function load(bytes32 id) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("io.synthetix.code-modules.Initialized", id));
        assembly {
            store.slot := s
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Module with ERC721 logic for the grateful subscription.
 */
interface IGratefulSubscription {
    /**************************************************************************
     * Governance functions
     *************************************************************************/

    /**
     * @notice Initialize the NFT
     * @dev Only owner / Token must not be initialized
     * @param tokenName The NFT token name
     * @param tokenSymbol The NFT token symbol
     * @param uri The NFT uri
     */
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) external;

    /**
     * @notice Mint token to user and increment counter
     * @dev Only owner / Token must be initialized
     * @param to Address to mint the NFT
     */
    function mint(address to) external;

    /**************************************************************************
     * View functions
     *************************************************************************/

    /**
     * @notice Get the current subscriptions token ID
     * @return The current token ID
     */
    function getCurrentTokenId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Subscription} from "../storage/Subscription.sol";

/**
 * @title Module for starting and finishing subscription.
 */
interface ISubscriptionsModule {
    /**************************************************************************
     * User functions
     *************************************************************************/

    /**
     * @notice Start subscription from giver to creator.
     *
     * Requirements:
     *
     * - Only profiles NFTs allowed on the system
     * - Sender must have subscribe role authorized
     * - Only existing creator profile ID
     * - Giver and creator cannot be the same
     * - Creator cannot be Grateful treasury
     * - Giver cannot be already subscribed to creator
     * - Only vaults initialized into the system
     * - Rate must be valid (between min and max vault rate)
     * - Subscription NFT will be minted to current giver profile owner
     * - Giver profile ID must have enough vault balance to start a subscription
     * - Giver profile ID must have enough vault balance to remain solvent for `solvencyTimeRequired` after subscription starts
     * - Emits a `SubscriptionStarted` event
     *
     * @param giverId The giver profile ID
     * @param creatorId The creator profile ID
     * @param vaultId The vault ID from where start the subscription
     * @param subscriptionRate The subscription rate from giver balance to creator balance (1e-20/second)
     *
     */
    function subscribe(
        bytes32 giverId,
        bytes32 creatorId,
        bytes32 vaultId,
        uint256 subscriptionRate
    ) external;

    /**
     * @notice End subscription from giver to creator.
     *
     * Requirements:
     *
     * - Only profiles NFTs allowed on the system
     * - Sender must have unsubscribe role authorized
     * - Only existing creator profile ID
     * - Giver and creator cannot be the same
     * - Creator cannot be Grateful treasury
     * - Giver must be subscribed to creator
     * - Emits `SubscriptionFinished` event
     *
     * @param giverId The giver profile ID
     * @param creatorId The creator profile ID
     */
    function unsubscribe(bytes32 giverId, bytes32 creatorId) external;

    /**************************************************************************
     * View functions
     *************************************************************************/

    /**
     * @notice Return subscription data from a subscription ID
     * @dev The subscription ID is a token ID from the Grateful Subcription NFT
     * @param subscriptionId The ID from where return the subscription data
     * @return subscription The subscription struct data
     */
    function getSubscription(
        uint256 subscriptionId
    ) external pure returns (Subscription.Data memory subscription);

    /**
     * @notice Return subscription data from giver and creator IDs
     * @param giverId The ID from where the subscription was created
     * @param creatorId The ID from whom is receiving the subscription
     * @return subscription The subscription struct data
     */
    function getSubscriptionFrom(
        bytes32 giverId,
        bytes32 creatorId
    ) external view returns (Subscription.Data memory subscription);

    /**
     * @notice Return the subscription ID from giver and creator IDs
     * @param giverId The ID from where the subscription was created
     * @param creatorId The ID from whom is receiving the subscription
     * @return The subscription ID
     */
    function getSubscriptionId(
        bytes32 giverId,
        bytes32 creatorId
    ) external view returns (uint256);

    /**
     * @notice Return the subscription and fee rates from a subscription ID
     * @param subscriptionId The ID from where return the subscription data
     * @return Subscription rate and fee rate
     */
    function getSubscriptionRates(
        uint256 subscriptionId
    ) external view returns (uint256, uint256);

    /**
     * @notice Return if a subscription is active from giver to creator
     * @param giverId The ID from where the subscription was created
     * @param creatorId The ID from whom is receiving the subscription
     * @return Subscribed flag
     */
    function isSubscribed(
        bytes32 giverId,
        bytes32 creatorId
    ) external view returns (bool);

    /**
     * @notice Return the total subscription duration since it was created
     * @param subscriptionId The ID from where return the subscription data
     * @return The current duration
     */
    function getSubscriptionDuration(
        uint256 subscriptionId
    ) external view returns (uint256);

    /**************************************************************************
     * Events
     *************************************************************************/

    /**
     * @notice Emits the data from the started subscription
     * @param giverId The ID from the profile starting the subscription
     * @param creatorId The ID from the profile receiving the subscription
     * @param vaultId The vault using in the subscription
     * @param subscriptionId The subscription ID from the Grateful Subscription NFT
     * @param rate The subscription rate going to the creator (1e-20/second)
     * @param feeRate The fee rate going to the treasury (1e-20/second)
     */
    event SubscriptionStarted(
        bytes32 indexed giverId,
        bytes32 indexed creatorId,
        bytes32 indexed vaultId,
        uint256 subscriptionId,
        uint256 rate,
        uint256 feeRate
    );

    // Note: Duplicated event until library events are exportable (https://github.com/ethereum/solidity/pull/10996)
    /**
     * @notice Emits the data from the finished subscription
     * @param giverId The ID from the profile that was subscribed
     * @param creatorId The ID from the profile that was receiving the subscription
     * @param vaultId The vault being used in the subscription
     * @param subscriptionId The subscription ID from the Grateful Subscription NFT
     * @param rate The subscription rate that was going to the creator (1e-20/second)
     * @param feeRate The fee rate that was going to the treasury (1e-20/second)
     */
    event SubscriptionFinished(
        bytes32 indexed giverId,
        bytes32 indexed creatorId,
        bytes32 indexed vaultId,
        uint256 subscriptionId,
        uint256 rate,
        uint256 feeRate
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IGratefulSubscription} from "../../interfaces/IGratefulSubscription.sol";
import {NftModule} from "@synthetixio/core-modules/contracts/modules/NftModule.sol";
import {ERC721} from "@synthetixio/core-contracts/contracts/token/ERC721.sol";
import {OwnableStorage} from "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import {SubscriptionNft} from "../../storage/SubscriptionNft.sol";
import {SubscriptionRenderer} from "../../utils/SubscriptionRenderer.sol";

/**
 * @title Module with ERC721 logic for the grateful subscription.
 * @dev See IGratefulSubscription
 */
contract GratefulSubscription is IGratefulSubscription, ERC721 {
    using SubscriptionNft for SubscriptionNft.Data;

    /// @inheritdoc	IGratefulSubscription
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory uri
    ) public override {
        OwnableStorage.onlyOwner();

        SubscriptionNft.load().incrementCounter();

        _initialize(tokenName, tokenSymbol, uri);
    }

    /// @inheritdoc	IGratefulSubscription
    function mint(address to) external override {
        OwnableStorage.onlyOwner();

        SubscriptionNft.Data storage nft = SubscriptionNft.load();

        uint256 tokenId = nft.tokenIdCounter;
        nft.incrementCounter();

        _mint(to, tokenId);
    }

    /// @inheritdoc	IGratefulSubscription
    function getCurrentTokenId() external view override returns (uint256) {
        return SubscriptionNft.load().tokenIdCounter;
    }

    /// @inheritdoc	ERC721
    function tokenURI(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        return SubscriptionRenderer.render(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title Stores the subscription data for each subscription.
 *
 * A subscription ID is a token ID minted in the Grateful subscription NFT.
 *
 * A subscription between a giver and a creator is unique.
 */
library Subscription {
    using SafeCast for uint256;

    struct Data {
        /**
         * @dev The subscription rate being streamed from giver to creator.
         *
         * Rate unit is 1e-20 per second.
         */
        uint96 rate;
        /**
         * @dev The fee rate being streamed from giver to treasury.
         *
         * Fee rate unit is 1e-20 per second.
         */
        uint80 feeRate;
        /**
         * @dev The last time the subscription was updated.
         *
         * This is stored when starting, updating or finishing it.
         */
        uint40 lastUpdate;
        /**
         * @dev The subscription total duration since creation.
         */
        uint40 duration;
        /**
         * @dev The creator ID who is receiving the subscription.
         */
        bytes32 creatorId;
        /**
         * @dev The vault balance that is being used in the subscription.
         */
        bytes32 vaultId;
    }

    /**
     * @dev Loads the subscription data from a subscription ID.
     */
    function load(
        uint256 subscriptionId
    ) internal pure returns (Data storage store) {
        bytes32 s = keccak256(abi.encode("Subscription", subscriptionId));
        assembly {
            store.slot := s
        }
    }

    /**
     * @dev Starts a subscription.
     *
     * This is used the first time a subscription is created.
     */
    function start(
        Data storage self,
        uint256 rate,
        uint256 feeRate,
        bytes32 creatorId,
        bytes32 vaultId
    ) internal {
        self.rate = rate.toUint96();
        self.feeRate = feeRate.toUint80();
        self.lastUpdate = (block.timestamp).toUint40();
        self.creatorId = creatorId;
        self.vaultId = vaultId;
    }

    /**
     * @dev Updates a subscription.
     *
     * This is used if the giver wants to update the rate or the vault being used.
     *
     * Also is called if restarting an already created subscription.
     */
    function update(
        Data storage self,
        uint256 rate,
        uint256 feeRate,
        bytes32 vaultId
    ) internal {
        self.rate = rate.toUint96();
        self.feeRate = feeRate.toUint80();
        self.lastUpdate = (block.timestamp).toUint40();
        self.vaultId = vaultId;
    }

    /**
     * @dev Finishes a subscription.
     *
     * This is used when the giver wants to unsubscribe.
     */
    function finish(Data storage self) internal {
        uint256 elapsedTime = block.timestamp - self.lastUpdate;

        self.rate = 0;
        self.feeRate = 0;
        self.lastUpdate = (block.timestamp).toUint40();
        self.duration += (elapsedTime).toUint40();
    }

    /**
     * @dev Returns if the subscription is active.
     */
    function isSubscribed(Data storage self) internal view returns (bool) {
        return self.rate != 0;
    }

    /**
     * @dev Returns the current subscription duration.
     *
     * It is the stored duration plus the elapsed time since last update.
     */
    function getDuration(
        Data storage self
    ) internal view returns (uint256 duration) {
        uint256 lastUpdate = self.lastUpdate;
        if (lastUpdate == 0) return 0;

        uint256 elapsedTime = block.timestamp - lastUpdate;

        duration = self.duration + (elapsedTime).toUint128();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Stores the data of the Grateful subscription NFT.
 */
library SubscriptionNft {
    bytes32 private constant _SUBSCRIPTION_NFT_STORAGE_SLOT =
        keccak256(abi.encode("SubscriptionNft"));

    struct Data {
        /**
         * @dev The current token ID from the NFT.
         *
         * This is then used as a subscription ID.
         */
        uint256 tokenIdCounter;
    }

    /**
     * @dev Loads the singleton storage info about the Grateful subscription NFT.
     */
    function load() internal pure returns (Data storage store) {
        bytes32 s = _SUBSCRIPTION_NFT_STORAGE_SLOT;
        assembly {
            store.slot := s
        }
    }

    /**
     * @dev Increments the current token ID counter.
     */
    function incrementCounter(Data storage self) internal {
        self.tokenIdCounter++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct Color {
    uint256 red;
    uint256 green;
    uint256 blue;
}

library Utils {
    function rgba(
        Color memory color,
        string memory _a
    ) internal pure returns (string memory) {
        return
            string.concat(
                "rgba(",
                uint2str(color.red),
                ",",
                uint2str(color.green),
                ",",
                uint2str(color.blue),
                ",",
                _a,
                ")"
            );
    }

    function uint2str(
        uint256 _i
    ) internal pure returns (string memory _uintAsString) {
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
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ISubscriptionsModule} from "../interfaces/ISubscriptionsModule.sol";
import {OwnableStorage} from "@synthetixio/core-contracts/contracts/ownership/OwnableStorage.sol";
import {Subscription} from "../storage/Subscription.sol";
import {Utils, Color} from "./RendererUtils.sol";

library SubscriptionRenderer {
    using Subscription for Subscription.Data;
    using Strings for uint256;

    uint256 constant MONTH_SECONDS = 30 days;

    function render(uint256 tokenId) internal view returns (string memory) {
        address system = OwnableStorage.load().owner;

        Subscription.Data memory subscription = ISubscriptionsModule(system)
            .getSubscription(tokenId);

        uint256 currentDuration = _getCurrentDuration(
            subscription.duration,
            subscription.lastUpdate
        );

        return _constructTokenURI(tokenId, subscription, currentDuration);
    }

    function _getCurrentDuration(
        uint256 duration,
        uint256 lastUpdate
    ) private view returns (uint256) {
        uint256 elapsedTime = block.timestamp - lastUpdate;

        return duration + elapsedTime;
    }

    function _constructTokenURI(
        uint256 tokenId,
        Subscription.Data memory subscription,
        uint256 duration
    ) internal view returns (string memory) {
        string memory _name = _getName(tokenId);
        string memory _description = _getDescription(subscription, duration);
        string memory _image = Base64.encode(bytes(_getSVG(tokenId, duration)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                _name,
                                '", "description":"',
                                _description,
                                '", "image": "data:image/svg+xml;base64,',
                                _image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function _getName(uint256 tokenId) private pure returns (string memory) {
        return string(abi.encodePacked("Subscription #", tokenId.toString()));
    }

    function _getDescription(
        Subscription.Data memory subscription,
        uint256 duration
    ) private view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "This NFT represents a subscription",
                    "\\n",
                    "Status: ",
                    _getStatus(subscription.rate),
                    "\\n",
                    "Since: ",
                    _getSince(duration),
                    "\\n",
                    "Duration: ",
                    _getDuration(duration),
                    "\\n",
                    "Creator: https://imgrateful.io/profile/",
                    subscription.creatorId
                )
            );
    }

    function _getStatus(uint256 rate) private pure returns (string memory) {
        return rate > 0 ? "Active" : "Inactive";
    }

    function _getSince(uint256 duration) private view returns (string memory) {
        uint256 creation = block.timestamp - duration;
        return creation.toString();
    }

    function _getDuration(
        uint256 duration
    ) private pure returns (string memory) {
        uint256 durationDays = duration / 1 days;
        return string(abi.encodePacked(durationDays.toString(), " days"));
    }

    function _getSVG(
        uint256 tokenId,
        uint256 duration
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xhtml="http://www.w3.org/1999/xhtml" viewBox="0 0 400 400" width="400" height="400">',
                    _getSVGBody(tokenId, duration),
                    "</svg>"
                )
            );
    }

    function _getSVGBody(
        uint256 tokenId,
        uint256 duration
    ) private pure returns (string memory) {
        (Color memory mainColor, Color memory secondaryColor) = _getColors(
            tokenId
        );

        string memory gradient = _getGradient(
            tokenId,
            mainColor,
            secondaryColor
        );

        uint256 cicles = duration / MONTH_SECONDS;
        uint256 length = duration - (MONTH_SECONDS * cicles);

        uint256 percentage = (length * 100) / MONTH_SECONDS;
        uint256 size = percentage + 70;

        return
            string(
                abi.encodePacked(
                    _getMainDotStyle(size, gradient),
                    _getMainDotBody(),
                    _getMonthsDots(cicles),
                    _getYearsDots(cicles, gradient)
                )
            );
    }

    function _getMainDotStyle(
        uint256 size,
        string memory gradient
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<style>.dot{position: absolute;top: 50%;left: 50%;transform: translate(-50%, -50%);width: ",
                    Utils.uint2str(size),
                    "px;height: ",
                    Utils.uint2str(size),
                    "px;filter: blur(0.5rem);background: ",
                    gradient,
                    "border-radius: 50%;animation: animate-pulse 2s linear infinite;}",
                    _getKeyframes(size),
                    "}</style>"
                )
            );
    }

    function _getMainDotBody() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<foreignObject x="0" y="0" width="100%" height="100%">'
                    '<xhtml:div class="dot"></xhtml:div>',
                    "</foreignObject>"
                )
            );
    }

    function _getMonthsDots(
        uint256 cicles
    ) private pure returns (string memory) {
        string memory dots = string.concat(
            "<style>.monthDot{position: absolute;top: 42.5px;left: 42.5px;width: 5px; height: 5px; border-radius: 50%;} .darkDot{background: rgba(0, 40, 122); opacity: 0.8;} .lightDot{background: rgba(255, 100, 25);}</style>"
        );

        uint256 yearsCicles = cicles / 12;
        cicles = cicles - (yearsCicles * 12);

        for (uint i = 1; i <= 12; i++) {
            (string memory x, string memory y) = _getXY(i);
            string memory background = i - 1 > cicles ? "darkDot" : "lightDot";
            dots = string.concat(
                dots,
                "<foreignObject x=",
                x,
                " y=",
                y,
                ' width="100px" height="100px">'
                '<xhtml:div class="monthDot ',
                background,
                '"></xhtml:div>',
                "</foreignObject>"
            );
        }

        return dots;
    }

    function _getYearsDots(
        uint256 cicles,
        string memory gradient
    ) private pure returns (string memory) {
        string memory yearsDots = string.concat(
            "<style>.yearDot{position: absolute;top: 45px;left: 50px;width: 40px; height: 40px;background: ",
            gradient,
            ";filter: blur(0.4rem);border-radius: 50%;}</style>"
        );

        uint256 yearsCicles = cicles / 12;

        yearsDots = yearsCicles >= 1
            ? string.concat(
                yearsDots,
                '<foreignObject x=260 y=0 width="100px" height="100px">'
                '<xhtml:div class="yearDot"></xhtml:div>',
                "</foreignObject>"
            )
            : "";

        return yearsDots;
    }

    function _getColors(
        uint256 tokenId
    ) private pure returns (Color memory main, Color memory secondary) {
        Color memory ORANGE = Color(255, 100, 25);
        Color memory PINK = Color(235, 128, 181);
        Color memory YELLOW = Color(248, 219, 80);

        uint256 random = uint256(
            keccak256(abi.encodePacked("COLOR", tokenId))
        ) % 6;

        if (random == 0) return (ORANGE, PINK);
        if (random == 1) return (ORANGE, YELLOW);
        if (random == 2) return (PINK, ORANGE);
        if (random == 3) return (PINK, YELLOW);
        if (random == 4) return (YELLOW, ORANGE);
        if (random == 5) return (YELLOW, PINK);
    }

    function _getGradient(
        uint256 tokenId,
        Color memory mainColor,
        Color memory secondaryColor
    ) private pure returns (string memory) {
        uint256 random = uint256(
            keccak256(abi.encodePacked("GRADIENT", tokenId))
        ) % 10;

        if (random >= 3) {
            return _getRadialGradient(tokenId, mainColor, secondaryColor);
        } else {
            return _getLinearGradient(tokenId, mainColor, secondaryColor);
        }
    }

    function _getRadialGradient(
        uint256 tokenId,
        Color memory mainColor,
        Color memory secondaryColor
    ) private pure returns (string memory) {
        uint256 percentage = uint256(
            keccak256(abi.encodePacked("PERCENTAGE", tokenId))
        ) % 25;

        return
            string.concat(
                "radial-gradient(",
                Utils.rgba(secondaryColor, "1"),
                Utils.uint2str(percentage),
                "%, ",
                Utils.rgba(secondaryColor, "0.7"),
                Utils.uint2str(percentage + 10),
                "%, ",
                Utils.rgba(mainColor, "1"),
                Utils.uint2str(percentage + 20),
                "%, ",
                Utils.rgba(mainColor, "0.5"),
                Utils.uint2str(percentage + 35),
                "%, rgba(255, 255, 255, 1) 75%);"
            );
    }

    function _getLinearGradient(
        uint256 tokenId,
        Color memory mainColor,
        Color memory secondaryColor
    ) private pure returns (string memory) {
        uint256 degree = uint256(
            keccak256(abi.encodePacked("DEGREE", tokenId))
        ) % 360;

        return
            string.concat(
                "linear-gradient(",
                Utils.uint2str(degree),
                "deg,",
                Utils.rgba(secondaryColor, "1"),
                " 15%, ",
                Utils.rgba(secondaryColor, "1"),
                " 25%, ",
                Utils.rgba(mainColor, "1"),
                " 75%, ",
                Utils.rgba(mainColor, "1"),
                " 100%);filter: blur(1rem);"
            );
    }

    function _getKeyframes(uint256 size) private pure returns (string memory) {
        string memory keyframes = string.concat(
            "@keyframes animate-pulse {50% {width: ",
            Utils.uint2str((size * 11) / 10),
            "px;height: ",
            Utils.uint2str((size * 11) / 10),
            "px;}"
        );

        return keyframes;
    }

    function _getXY(
        uint256 index
    ) private pure returns (string memory x, string memory y) {
        if (index == 1) return ("215", "45");
        if (index == 2) return ("260", "90");
        if (index == 3) return ("280", "155");
        if (index == 4) return ("260", "215");
        if (index == 5) return ("215", "260");
        if (index == 6) return ("155", "280");
        if (index == 7) return ("95", "260");
        if (index == 8) return ("50", "215");
        if (index == 9) return ("30", "155");
        if (index == 10) return ("50", "90");
        if (index == 11) return ("95", "45");
        if (index == 12) return ("155", "30");
    }
}