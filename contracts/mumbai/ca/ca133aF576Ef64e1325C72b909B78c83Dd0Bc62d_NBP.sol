// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Equal {
    function _equalStrings(string memory _a, string memory _b) internal pure returns (bool) {
        return keccak256(bytes(_a)) == keccak256(bytes(_b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Regex {
    // ^\w{1,25}$
    function validateProjectName(string memory input) internal pure returns (bool) {
        if(bytes(input).length <1 || bytes(input).length > 25) {
            return false;
        }

        for(uint i = 0; i < bytes(input).length; i++) {
            bytes1 c = bytes(input)[i];
            if(
                !(c >= 0x41 && c <= 0x5A) && // A-Z
                !(c >= 0x61 && c <= 0x7A) && // a-z
                !(c >= 0x30 && c <= 0x39) && // 0-9
                c != 0x5F // _
            ) {
                return false;

            }
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Projects.sol";
import "./libraries/Equal.sol";

error SBTNoSetApprovalForAll(address _operator, bool _approved);
error SBTNoIsApprovedForAll(address _account, address _operator);
error SBTNoSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes _data);
error SBTNoSafeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _amounts, bytes _data);

contract NBP is Projects, ERC165, IERC1155, IERC1155MetadataURI {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    struct MetadataStruct {
        uint256 tokenId;
        uint256 projectId;
        string name;
        string imageCID;
        string description;
        string role;
        string category;
        string twitter;
        string opensea;
        string discord;
        address createdBy;
    }

    // Mapping from token id to card info
    mapping(uint256 => MetadataStruct) private _tokenMetadata;

    // Mapping from project id to token id
    mapping(uint256 => uint256[]) private _projectCardIds;

    // Mapping from wallet address to last created token id
    mapping(address => uint256) private _userLatestTokenId;

    // Mapping from token id to number of cards owned by user
    mapping(uint256 => mapping(address => uint256)) private _balances;

    string private _tokenName;
    string private _tokenSymbol;
    string private _tokenUri;

    event EventBatch(
        address indexed _operator,
        address indexed _from,
        address[] _tos,
        uint256 indexed _id,
        uint256 _value
    );

    constructor(string memory _name, string memory _symbol, string memory _uri) {
        _tokenName = _name;
        _tokenSymbol = _symbol;
        _tokenUri = _uri;

        _tokenId.increment();
    }

    //  ==========  ERC165 logic    ==========
    function supportsInterface(bytes4 _interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return
            _interfaceId == type(IERC1155).interfaceId ||
            _interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    //  ==========  IERC1155 logic    ==========
    function balanceOf(address _account, uint256 _id) public view returns (uint256) {
        // _account cannot be the zero address.
        require(_account != address(0));
        return _balances[_id][_account];
    }

    function balanceOfBatch(
        address[] memory _accounts,
        uint256[] memory _ids
    ) public view returns (uint256[] memory) {
        uint256 count = _accounts.length;

        // _accounts and _ids must have the same length.
        require(count == _ids.length);

        uint256[] memory batchBalances = new uint256[](count);
        for (uint256 i = 0; i < count; ++i) {
            batchBalances[i] = balanceOf(_accounts[i], _ids[i]);
        }
        return batchBalances;
    }

    function setApprovalForAll(address _operator, bool _approved) public pure {
        revert SBTNoSetApprovalForAll(_operator, _approved);
    }

    function isApprovedForAll(address _account, address _operator) public pure returns (bool) {
        revert SBTNoIsApprovedForAll(_account, _operator);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public pure {
        revert SBTNoSafeTransferFrom(_from, _to, _id, _amount, _data);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public pure {
        revert SBTNoSafeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    //  ==========  IERC1155MetadataURI logic    ==========
    function uri(uint256 _id) public view returns (string memory) {
        // Token does not exist.
        require(bytes(_tokenMetadata[_id].name).length > 0);

        MetadataStruct memory tokenMetadata = _tokenMetadata[_id];
        uint256 projectId = tokenMetadata.projectId;
        string memory projectName = getProjectById(projectId).name;

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{',
                            '"name": "', tokenMetadata.name, '",'
                            '"description": "', tokenMetadata.description, '",',
                            '"image": "ipfs://', tokenMetadata.imageCID, '",',
                            '"imageUrl": "ipfs://', tokenMetadata.imageCID, '",',
                            '"attributes": [',
                                '{',
                                    '"trait_type": "tokenId",',
                                    '"value": "', Strings.toString(_id), '"',
                                '},',
                                '{',
                                    '"trait_type": "name",',
                                    '"value": "', tokenMetadata.name, '"',
                                '},',
                                '{',
                                    '"trait_type": "category",',
                                    '"value": "', tokenMetadata.category, '"',
                                '},',
                                '{',
                                    '"trait_type": "role",',
                                    '"value": "', tokenMetadata.role, '"',
                                '},',
                                '{',
                                    '"trait_type": "project",',
                                    '"value": "', projectName, '"',
                                '},',
                                '{',
                                    '"trait_type": "from",',
                                    '"value": "', Strings.toHexString(tokenMetadata.createdBy), '"',
                                '}',
                            ']',
                        '}'
                    )
                )
            )
        );
        string memory output = string(abi.encodePacked(_tokenUri, json));
        return output;
    }

    //  ==========  Additional logic    ==========
    function createCard(
        uint256 _projectId,
        string memory _name,
        string memory _imageCID,
        string memory _description,
        string memory _role,
        string memory _category,
        string memory _twitter,
        string memory _opensea,
        string memory _discord,
        address _createdBy
    ) external {
        uint256 tokenId = _tokenId.current();

        // Project does not exist.
        require(!Equal._equalStrings(getProjectById(_projectId).name, ""));

        // Name must be at least 1 and no more than 50 characters.
        require(0 < bytes(_name).length && bytes(_name).length <= 50);

        // Description must be at least 1 and no more than 1000 characters.
        require(0 < bytes(_description).length && bytes(_description).length <= 1000);

        _tokenMetadata[tokenId] = MetadataStruct({
            tokenId: tokenId,
            projectId: _projectId,
            name: _name,
            imageCID: _imageCID,
            description: _description,
            role: _role,
            category: _category,
            twitter: _twitter,
            opensea: _opensea,
            discord: _discord,
            createdBy: _createdBy
        });
        _userLatestTokenId[_createdBy] = tokenId;
        _projectCardIds[_projectId].push(tokenId);

        _tokenId.increment();
    }

    function mintBatch(
        address[] memory _tos,
        uint256 tokenId_, uint256
        _projectId
    ) external {
        // Card does not exist
        require(bytes(_tokenMetadata[tokenId_].name).length != 0);

        for (uint256 i = 0; i < _tos.length; i++) {
            address to = _tos[i];
            // Mint to the zero address.
            require(to != address(0));

            // Already minted to this user.
            require(_balances[tokenId_][to] == 0);

            _balances[tokenId_][to]++;

            address operator = msg.sender;
            emit TransferSingle(operator, address(0), to, tokenId_, 1);
        }

        _addUsersToProject(_projectId, _tos);
    }

    function burn(address _from, uint256 _id) external {
        // Burn from the zero address.
        require(_from != address(0));

        // Not authorized to burn.
        require(_from == msg.sender || _tokenMetadata[_id].createdBy == msg.sender);

        uint256 fromBalance = _balances[_id][_from];

        // Don't own this token.
        require(fromBalance >= 1);
        unchecked {
            _balances[_id][_from] = fromBalance - 1;
        }

        address operator = msg.sender;
        emit TransferSingle(operator, _from, address(0), _id, 1);
    }

    function getCreatedTokenId(address _walletAddress) external view returns(uint256) {
        return _userLatestTokenId[_walletAddress];
    }

    function getProjectCards(uint256 _projectId) external view returns(MetadataStruct[] memory) {
        uint256[] memory projectCardIds =  _projectCardIds[_projectId];
        uint256 count = projectCardIds.length;
        MetadataStruct[] memory projectCards = new MetadataStruct[](count);

        for (uint256 i; i < count; i++) {
            projectCards[i] = _tokenMetadata[projectCardIds[i]];
        }

        return projectCards;
    }

    function name() public view returns (string memory) {
        return _tokenName;
    }

    function symbol() public view returns (string memory) {
        return _tokenSymbol;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./libraries/Equal.sol";
import './libraries/Regex.sol';

contract Projects {
    using Counters for Counters.Counter;
    Counters.Counter private _projectIds;

    struct ProjectStruct {
        uint256 id;
        string name;
        string imageUrl;
        string description;
        address createdBy;
    }

    struct ProjectUserStruct {
        address walletAddress;
        bool isAdmin;
    }

    // Mapping from project id to project info
    mapping(uint256 => ProjectStruct) internal _projects;

    // Mapping from project name to project id
    mapping(string => uint256) internal _projectMapping;

    // Mapping from user address to project ids
    mapping(address => uint256[]) internal _userProjects;
    mapping(address => mapping(uint256 => bool)) internal _userProjectExists;

    // Mapping from project id to user address
    mapping(uint256 => address[]) internal _projectUsers;
    mapping(uint256 => mapping(address => bool)) internal _projectUserExists;

    // Mapping from project id to user admin
    mapping(uint256 => mapping(address => bool)) internal _operatorAdmins;

    constructor() {
        _projectIds.increment();
    }

    //  ==========  project logic    ==========
    function createProject(
        string memory _name,
        string memory _imageUrl,
        string memory _description
    ) external {
        // That name has been taken.
        require(getProjectIdByName(_name) == 0);

        // Project name must be at least 1 and no more than 25 characters, consisting only of letters, numbers, and '_'.
        require(Regex.validateProjectName(_name));

        // ImageUrl must be at least 0 characters.
        require(bytes(_imageUrl).length != 0);

        // Description must be less than 1000 characters.
        require(bytes(_description).length <= 1000);

        address operator = msg.sender;
        uint256 projectId = _projectIds.current();
        ProjectStruct memory project = ProjectStruct({
            id: projectId,
            name: _name,
            imageUrl: _imageUrl,
            description: _description,
            createdBy: operator
        });

        _projectMapping[_name] = projectId;
        _projects[projectId] = project;

        _userProjects[operator].push(projectId);
        _userProjectExists[operator][projectId] = true;

        _projectUsers[projectId].push(operator);
        _projectUserExists[projectId][operator] = true;

        _operatorAdmins[projectId][operator] = true;

        _projectIds.increment();
    }

    function updateProjectById(
        uint256 _projectId,
        string memory _name,
        string memory _imageUrl,
        string memory _description
    ) public {
        // Project does not exist.
        require(bytes(getProjectById(_projectId).name).length != 0);

        // Not authorized.
        require(getAdminByProjectId(_projectId, msg.sender));

        ProjectStruct memory currentProject = getProjectById(_projectId);
        string memory currentName = currentProject.name;

        // That name has been taken.
        require(Equal._equalStrings(currentName, _name) || getProjectIdByName(_name) == 0);

        // Project name must be at least 1 and no more than 25 characters, consisting only of letters, numbers, and '_'.
        require(Regex.validateProjectName(_name));

        // ImageUrl must be at least 0 characters.
        require(bytes(_imageUrl).length != 0);

        // Description must be less than 1000 characters.
        require(bytes(_description).length <= 1000);

        if (bytes(_name).length != 0 && !Equal._equalStrings(currentName, _name)) {
            _projects[_projectId].name = _name;
            _projectMapping[_name] = _projectId;
            delete _projectMapping[currentName];
        }

        if (bytes(_imageUrl).length != 0 && !Equal._equalStrings(currentProject.imageUrl, _imageUrl)) {
            _projects[_projectId].imageUrl = _imageUrl;
        }

        if (bytes(_description).length != 0 && !Equal._equalStrings(currentProject.description, _description)) {
            _projects[_projectId].description = _description;
        }
    }

    function getProjectById(uint256 _projectId) public view returns(ProjectStruct memory) {
        return _projects[_projectId];
    }

    function getProjectIdByName(string memory _name) public view returns(uint256) {
        return _projectMapping[_name];
    }

    //  ==========  user logic    ==========
    function _addUsersToProject(uint256 _projectId, address[] memory _addressList) internal {
        // Project does not exist.
        require(bytes(getProjectById(_projectId).name).length != 0);

        uint256 count = _addressList.length;
        for(uint256 i; i < count; i++) {
            address walletAddress = _addressList[i];

            if (!_projectUserExists[_projectId][walletAddress]) {
                _projectUsers[_projectId].push(walletAddress);
                _projectUserExists[_projectId][walletAddress] = true;
                _operatorAdmins[_projectId][walletAddress] = false;
            }

            if (!_userProjectExists[walletAddress][_projectId]) {
                _userProjects[walletAddress].push(_projectId);
                _userProjectExists[walletAddress][_projectId] = true;
            }
        }
    }

    //  ==========  projectUsers logic    ==========
    function getProjectUsersById(
        uint256 _projectId
    ) public view returns(
        ProjectStruct memory project,
        ProjectUserStruct[] memory projectUsers
    ) {
        return (getProjectById(_projectId), getUsersByProjectId(_projectId));
    }

    function getUsersByProjectId(
        uint256 _projectId
    ) public view returns(
        ProjectUserStruct[] memory
    ) {
        address[] memory addressList = _projectUsers[_projectId];
        uint256 count = addressList.length;
        ProjectUserStruct[] memory projectUsers = new ProjectUserStruct[](count);

        for (uint256 i; i < count; i++) {
            address walletAddress = addressList[i];
            ProjectUserStruct memory projectUser = ProjectUserStruct({
                walletAddress: walletAddress,
                isAdmin: getAdminByProjectId(_projectId, walletAddress)
            });
            projectUsers[i] = projectUser;
        }

        return projectUsers;
    }

    //  ==========  userProjects logic    ==========
    function getUserProjects(address _walletAddress) external view returns(ProjectStruct[] memory) {
        uint256[] memory projectIds = _userProjects[_walletAddress];
        uint256 count = projectIds.length;
        ProjectStruct[] memory projects = new ProjectStruct[](count);

        for (uint256 i; i < count; i++) {
            uint256 projectId = projectIds[i];
            ProjectStruct memory project = _projects[projectId];
            projects[i] = project;
        }

        return projects;
    }

    //  ==========  admin logic    ==========
    function getAdminByProjectId(uint256 _projectId, address _walletAddress) public view returns(bool) {
        return _operatorAdmins[_projectId][_walletAddress];
    }

    function updateAdminByProjectId(
        uint256 _projectId,
        address _walletAddress,
        bool _isAdmin
    ) public {
        address createdBy = _projects[_projectId].createdBy;
        // Not authorized.
        require(createdBy == msg.sender);

        // Permissions of the user who created the Project cannot be changed.
        require(createdBy != _walletAddress);

        if (getAdminByProjectId(_projectId, _walletAddress) != _isAdmin) {
            _operatorAdmins[_projectId][_walletAddress] = _isAdmin;
        }
    }
}