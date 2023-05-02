// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ITemplate is IERC165 {
    function name() external pure returns (string memory);
    function image(uint256 tokenId) external view returns (string memory);
}

// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * ========================= VERSION_2.0.0 ==============================
 *   ██       ██████  ████████ ████████    ██      ██ ███    ██ ██   ██
 *   ██      ██    ██    ██       ██       ██      ██ ████   ██ ██  ██
 *   ██      ██    ██    ██       ██       ██      ██ ██ ██  ██ █████
 *   ██      ██    ██    ██       ██       ██      ██ ██  ██ ██ ██  ██
 *   ███████  ██████     ██       ██    ██ ███████ ██ ██   ████ ██   ██    
 * ======================================================================
 *  ================ Open source smart contract on EVM =================
 *   ============== Verify Random Function by ChainLink ===============
 */

import "./utils/AppStorage.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./interfaces/ITemplate.sol";


contract Template_BlackTicket is ITemplate, ERC165 {
    using Strings for *;

    function name() external pure returns (string memory){
        return "BlackTicket";
    }

    function image(uint256 tokenId) external view returns (string memory) {
        AppStorage.Layout storage app = AppStorage.layout();

        (,bytes memory res) = msg.sender.staticcall(abi.encodeWithSignature("status()"));
        (string memory state1, string memory state2) = abi.decode(res, (string, string));

        return string.concat('data:image/svg+xml;base64,', Base64.encode(abi.encodePacked(
            _template({
                timestamp : block.timestamp.toString(),
                ticketId : tokenId.toString(),
                maximumTicket : app.Uint256.maximumTicket.toString(),
                soldTickets : app.Uint256.soldTickets.toString(),
                nftContract : address(app.Address.nftAddr).toHexString(),
                nftId : app.Uint256.nftId.toString(),
                nftName : IERC721Metadata(app.Address.nftAddr).name(),
                winnerId : app.Uint256.winnerId == 0 ? "?" : app.Uint256.winnerId.toString(),
                state1 : state1,
                state2 : state2
            })
        )));
    }

    function _template(
        string memory timestamp,
        string memory ticketId,
        string memory maximumTicket,
        string memory soldTickets,
        string memory nftContract,
        string memory nftId,
        string memory nftName,
        string memory winnerId,
        string memory state1,
        string memory state2
    ) private pure returns(string memory) {      
        return string.concat(
            '<svg stroke-miterlimit="10" style="fill-rule:nonzero;clip-rule:evenodd;stroke-linecap:round;stroke-linejoin:round" viewBox="0 0 1920 1080" xml:space="preserve" xmlns="http://www.w3.org/2000/svg"><defs><clipPath id="b"><path transform="translate(-448.393 -333.662)" d="M448.393 333.662H1103.2v116.271H448.393z"/></clipPath><clipPath id="c"><path transform="translate(-545.03 -448.7)" d="M545.03 448.7h475.123v23.546H545.03z"/></clipPath><clipPath id="d"><path transform="translate(-28.85 -1039.14)" d="M28.85 1039.14h736.212v23.654H28.85z"/></clipPath><clipPath id="e"><path transform="translate(-371.194 -674.582)" d="M371.194 674.582h137.288v53.472H371.194z"/></clipPath><clipPath id="f"><path transform="translate(-364.32 -628.047)" d="M364.32 628.047h120.91v21.589H364.32z"/></clipPath><clipPath id="g"><path transform="translate(-516.959 -674.363)" d="M516.959 674.363h137.288v53.472H516.959z"/></clipPath><clipPath id="h"><path transform="translate(-517.225 -629.349)" d="M517.225 629.349h120.91v21.589h-120.91z"/></clipPath><clipPath id="i"><path transform="translate(-672.878 -631.677)" d="M672.878 631.677h141.284v32.357H672.878z"/></clipPath><clipPath id="j"><path transform="translate(-675.367 -672.748)" d="M675.367 672.748h137.288v53.472H675.367z"/></clipPath><clipPath id="k"><path transform="translate(-896.285 -628.011)" d="M896.285 628.011h258.567v53.472H896.285z"/></clipPath><clipPath id="l"><path transform="translate(-896.285 -695.736)" d="M896.285 695.736h290.834v15.42H896.285z"/></clipPath><clipPath id="m"><path transform="translate(-896.285 -729.689)" d="M896.285 729.689h290.834v15.42H896.285z"/></clipPath><clipPath id="n"><path transform="translate(-896.285 -679.995)" d="M896.285 679.995h290.834v15.42H896.285z"/></clipPath><clipPath id="o"><path transform="translate(-896.285 -713.764)" d="M896.285 713.764h290.834v15.42H896.285z"/></clipPath><clipPath id="p"><path transform="rotate(90 1130.543 -461.747)" d="M1592.29 531.508h53.472v137.288h-53.472z"/></clipPath><clipPath id="q"><path transform="rotate(90 1112.947 -433.343)" d="M1546.29 558.695h21.589v120.91h-21.589z"/></clipPath><clipPath id="r"><path transform="rotate(90 1057.55 -534.52)" d="M1592.07 385.743h53.472v137.288h-53.472z"/></clipPath><clipPath id="s"><path transform="rotate(90 1040.207 -505.333)" d="M1545.54 370.997h40.71v163.878h-40.71z"/></clipPath><clipPath id="t"><path transform="rotate(90 1127.697 -304.003)" d="M1431.7 252.818h68.963v570.876H1431.7z"/></clipPath><filter color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="712.381" id="a" width="1580.66" x="187.405" y="210.235"><feDropShadow dx="25.357" dy="54.379" flood-color="#909090" flood-opacity=".333" in="SourceGraphic" result="Shadow" stdDeviation="5"/></filter></defs><path d="M0 0h1920v1080H0V0Z" fill="#c4c4c4" fill-rule="evenodd"/><g fill="#008bd2" fill-rule="evenodd"><path d="m1850.25 918.99-36.92-21.32a20.401 20.401 0 0 0-20.39 0l-36.92 21.32a20.381 20.381 0 0 0-10.2 17.65v42.64c0 7.28 3.89 14.01 10.19 17.66l36.92 21.32a20.401 20.401 0 0 0 20.39 0l36.92-21.32a20.376 20.376 0 0 0 10.19-17.66v-42.64a20.32 20.32 0 0 0-10.18-17.65Zm-47.11 89.24c-27.76 0-50.27-22.51-50.27-50.27s22.5-50.27 50.27-50.27c27.77 0 50.27 22.51 50.27 50.27s-22.51 50.27-50.27 50.27Z"/><path d="M1825.88 931.72h-12.67v13.01h-27.14v-13.01h-12.67v13.01h-9.44v12.63h9.44v15.29c0 4.19.98 7.36 2.94 9.5 1.96 2.14 5.03 3.21 9.22 3.21h21.89v-12.21h-18.66c-.89 0-1.57-.32-2.03-.95-.46-.63-.69-1.53-.69-2.7v-12.14h27.14v15.29c0 4.19.98 7.36 2.94 9.5 1.96 2.14 5.03 3.21 9.22 3.21h12.95v-12.21h-9.71c-.89 0-1.57-.32-2.03-.95-.46-.63-.69-1.53-.69-2.7v-12.14h12.44v-12.63h-12.45v-13.01Z"/></g><g fill-rule="evenodd"><path d="M187.405 210.235v648.003H1317.54c-.42-1.344-1.44-2.345-1.44-3.835 0-7.582 5.66-13.744 12.78-13.743 7.12 0 12.95 6.161 12.95 13.743 0 1.482-1.03 2.498-1.44 3.835h392.32V210.235h-393.6c.19.941.96 1.555.96 2.557 0 7.582-5.83 13.743-12.95 13.743-7.11 0-12.78-6.161-12.78-13.743 0-1.008.76-1.611.96-2.557H187.405Z" fill="#f9f9f9" filter="url(#a)"/><path d="M1088.87 845.387v8.219h227.31c.01-3.17 1.3-5.982 3.19-8.219h-230.5Zm249.62 0c1.89 2.237 3.17 5.049 3.19 8.219h391v-8.219h-394.19ZM187.361 829.567H1687.36v8.195H187.361v-8.195ZM588.639 811.9h600.001v8.195H588.639V811.9ZM187.394 211.056h280v8.196h-280v-8.196ZM187.405 231.661H1732.7v8.195H187.405v-8.195ZM1362.84 216.005h370v8.195h-370v-8.195ZM187.161 248.298h630v8.195h-630v-8.195Z"/><path d="m1328.19 225.32 1.44 615.332" fill="#f9f9f9" stroke="#000" stroke-dasharray="10.0,5.0" stroke-linecap="butt" stroke-width="4"/></g><g fill-rule="evenodd"><path d="M187.994 266.459h62v8.196h-62v-8.196ZM219.994 522.159h30v8.195h-30v-8.195ZM187.994 329.265h62v8.195h-62v-8.195ZM187.994 409.298h62v8.195h-62v-8.195ZM187.994 449.729h62v8.196h-62v-8.196ZM187.994 582.715h62v8.195h-62v-8.195ZM187.994 673.848h62v8.196h-62v-8.196ZM187.994 690.584h62v8.195h-62v-8.195ZM187.994 722.894h62v8.196h-62v-8.196ZM209.994 461.583h40v8.196h-40v-8.196ZM209.994 702.589h40v8.195h-40v-8.195ZM187.994 540h62v8.195h-62V540ZM187.994 507.351h62v8.195h-62v-8.195ZM187.994 362.8h62v8.196h-62V362.8ZM187.994 430.38h62v8.195h-62v-8.195ZM194.994 343.044h55v8.195h-55v-8.195ZM194.994 391.53h55v8.195h-55v-8.195ZM187.994 557.67h62v8.195h-62v-8.195ZM187.994 610.592h62v8.195h-62v-8.195ZM209.994 744.12h40v8.195h-40v-8.195ZM219.994 638.559h30v8.196h-30v-8.196Z"/></g><g fill-rule="evenodd"><path d="M1275.3 301.464H1380.3v8.195h-105v-8.195ZM1275.3 737.364h105v8.195h-105v-8.195ZM1275.3 752.885h105v8.196h-105v-8.196ZM1275.3 471.866h105v8.196h-105v-8.196ZM1275.3 409.581h105v8.196h-105v-8.196ZM1275.3 719.159h105v8.195h-105v-8.195ZM1275.3 690.881h105v8.196h-105v-8.196ZM1275.3 679.142h105v8.195h-105v-8.195ZM1275.3 657.305h105v8.195h-105v-8.195ZM1275.3 618.124h105v8.195h-105v-8.195ZM1275.3 540h105v8.195h-105V540ZM1275.3 581.545h105v8.196h-105v-8.196ZM1275.3 511.316h105v8.195h-105v-8.195ZM1275.3 450.84h105v8.196h-105v-8.196ZM1275.3 380.704h105v8.196h-105v-8.196ZM1275.3 321.415h105v8.195h-105v-8.195ZM1275.3 284.98h105v8.196h-105v-8.196ZM1275.3 633.355h105v8.195h-105v-8.195ZM1275.3 343.112h105v8.195h-105v-8.195ZM1275.3 599.412h105v8.196h-105v-8.196ZM1275.3 485.638h105v8.195h-105v-8.195ZM1275.3 363.792h105v8.195h-105v-8.195Z"/></g><g fill-rule="evenodd"><path d="M1697.38 290.501h35v8.195h-35v-8.195ZM1697.38 366.428h35v8.195h-35v-8.195ZM1697.38 395.751h35v8.196h-35v-8.196ZM1697.38 462.609h35v8.196h-35v-8.196ZM1697.38 507.838h35v8.196h-35v-8.196ZM1697.38 552.769h35v8.195h-35v-8.195ZM1697.38 634.892h35v8.195h-35v-8.195ZM1697.38 654.012h35v8.195h-35v-8.195ZM1697.38 674.478h35v8.195h-35v-8.195ZM1697.38 726.441h35v8.195h-35v-8.195ZM1697.38 746.927h35v8.195h-35v-8.195Z"/></g><g font-family="ArialMT"><text clip-path="url(#b)" font-size="100" transform="translate(448.393 333.662)"><tspan textLength="611.426" x="0" y="91">ChanceRoom</tspan></text><text clip-path="url(#c)" font-size="20" transform="translate(545.03 448.7)"><tspan textLength="426.455" x="0" y="18">NFT Lottery By lott link - Powered By Chain link </tspan></text></g><text clip-path="url(#d)" font-family="ArialMT" font-size="20" transform="translate(28.85 1039.14)"><tspan textLength="423.584" x="0" y="18">TokenURI Generation Timestamp : ',
            timestamp,
            '</tspan></text><path d="M394.548 662.224h377.899c28.195 0 51.051 7.874 51.051 17.587v39.406c0 9.713-22.856 17.587-51.051 17.587H394.548c-28.194 0-51.05-7.874-51.05-17.587v-39.406c0-9.713 22.856-17.587 51.05-17.587Z" fill="none" stroke="#000" stroke-linecap="butt" stroke-linejoin="bevel" stroke-width="4"/><text clip-path="url(#e)" font-family="ArialMT" font-size="45" transform="translate(371.194 674.582)"><tspan textLength="100.107" x="0" y="41">',
            ticketId,
            '</tspan></text><text clip-path="url(#f)" font-family="ArialMT" font-size="18" transform="translate(364.32 628.047)"><tspan textLength="116.358" x="0" y="16">Ticket Number</tspan></text><path d="M498.283 662.849s-10.203 41.54 2.447 72.582" fill="none" stroke="#000" stroke-width="4"/><text clip-path="url(#g)" font-family="ArialMT" font-size="45" transform="translate(516.959 674.363)"><tspan textLength="100.107" x="0" y="41">',
            maximumTicket,
            '</tspan></text><text clip-path="url(#h)" font-family="ArialMT" font-size="18" transform="translate(517.225 629.349)"><tspan textLength="99.035" x="0" y="16">Total Tickets</tspan></text><path d="M653.541 662.037s-10.202 41.541 2.447 72.582" fill="none" stroke="#000" stroke-width="4"/><text clip-path="url(#i)" font-family="ArialMT" font-size="18" transform="translate(672.878 631.677)"><tspan textLength="122.054" x="0" y="16">Number of sold</tspan></text><text clip-path="url(#j)" font-family="ArialMT" font-size="45" transform="translate(675.367 672.748)"><tspan textLength="100.107" x="0" y="41">',
            soldTickets,
            '</tspan></text><g font-family="ArialMT"><text clip-path="url(#k)" font-size="45" transform="translate(896.285 628.011)"><tspan textLength="245.083" x="0" y="41">Locked NFT</tspan></text><text clip-path="url(#l)" font-size="12" transform="translate(896.285 695.736)"><tspan textLength="280.898" x="0" y="11">',
            nftContract,
            '</tspan></text><text clip-path="url(#m)" font-size="12" transform="translate(896.285 729.689)"><tspan textLength="26.695" x="0" y="11">',
            nftId,
            '</tspan></text><text clip-path="url(#n)" font-size="12" transform="translate(896.285 679.995)"><tspan x="0" y="11">',
            nftName,
            '</tspan></text><text clip-path="url(#o)" font-size="12" transform="translate(896.285 713.764)"><tspan textLength="47.355" x="0" y="11">Token ID</tspan></text></g><path d="M1578.99 669.157v-244.06c0-18.209 7.87-32.97 17.59-32.97h39.4c9.71 0 17.59 14.761 17.59 32.97v244.06c0 18.208-7.88 32.97-17.59 32.97h-39.4c-9.72 0-17.59-14.762-17.59-32.97Z" fill="none" stroke="#000" stroke-linecap="butt" stroke-linejoin="bevel" stroke-width="4"/><text clip-path="url(#p)" font-family="ArialMT" font-size="45" transform="rotate(-90 1130.543 -461.747)"><tspan textLength="100.107" x="0" y="41">',
            ticketId,
            '</tspan></text><text clip-path="url(#q)" font-family="ArialMT" font-size="18" transform="rotate(-90 1112.947 -433.343)"><tspan textLength="116.358" x="0" y="16">Ticket Number</tspan></text><path d="M1580.55 541.707s41.54 10.203 72.59-2.447" fill="none" stroke="#000" stroke-width="4"/><text clip-path="url(#r)" font-family="ArialMT" font-size="45" transform="rotate(-90 1057.55 -534.52)"><tspan textLength="100.107" x="0" y="41">',
            winnerId,
            '</tspan></text><text clip-path="url(#s)" font-family="ArialMT" font-size="18" transform="rotate(-90 1040.208 -505.333)"><tspan textLength="126.035" x="0" y="16">Winner Number</tspan></text><text clip-path="url(#t)" font-family="ArialMT" font-size="30" text-anchor="middle" transform="rotate(-90 1127.697 -304.004)"><tspan x="285.438" y="27">',
            state1,
            '</tspan><tspan x="285.438" y="61">',
            state2,
            '</tspan></text></svg>'
        );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(ITemplate).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library AppStorage {

    bytes32 constant APP_STORAGE_POSITION = keccak256("APP_STORAGE_POSITION");

    function layout() internal pure returns (Layout storage l) {
        bytes32 position = APP_STORAGE_POSITION;
        assembly {
            l.slot := position
        }
    }

    struct Layout {
        VarUint256 Uint256;
        VarAddress Address;
        VarBool Bool;
        // VarInt256 Int256;
    }

    struct VarUint256 {
        uint256 initTime;
        uint256 deadLine;
        uint256 nftId;
        uint256 maximumTicket;
        uint256 soldTickets;
        uint256 ticketPrice;
        uint256 winnerId;
    }

    struct VarAddress {
        address nftAddr;
        address tempAddr;
    }

    struct VarBool {
        bool triggered;
        bool refunded;
    }

    // struct VarInt256 {
    //     int256 priceRate;
    // }
    
}