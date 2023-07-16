/**
 *Submitted for verification at polygonscan.com on 2023-07-16
*/

// File: @openzeppelin/contracts/utils/math/SignedMath.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;



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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File: contracts/EasyTrade.sol



pragma solidity ^ 0.8.18;

//@openzeppelin = https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master









/*

EEEEEEEEEE      
EEE       
EEE     
EEEEEEE     AAAAa.  .sSSSSs  YYY  YYY
EEE            "AAa SSS      YYY  YYY
EEE        .aAAAAAA "SSSSSs. YYY  YYY
EEE        AAA  AAA      SSS YYYy YYY   
EEEEEEEEEE "AAAAAAA  SSSSSS'  "YYYYYY
                                  YYY                                                 
                             YYy yYYY                                                 
                              "YYYY"                                                  

*/
/// @author developer's website 🐸 https://www.halfsupershop.com/ 🐸
contract EasyTrade is ERC20, ERC721Holder, ERC1155Holder, Ownable, ReentrancyGuard {
    event TradeInitiated(uint tradeIndex, uint8 tokenTypeID);
    event TradeCompleted(uint tradeIndex);
    event TradeCanceled(uint tradeIndex);
    event CreatorSupportSet(address _contractAddress, uint _percentage, address _creatorRouting);
    event PrizePoolWinner(address _winner, uint256 _prize);
    event DonationReceived(address _donor, uint256 _toPrizePool, uint256 _toDev);

    //deployment vairable values, please call read functions for updated values
    bool public paused;
    uint256 _totalSupply;
    uint256 public randomCounter;
    uint256 public minRange = 0;
    uint256 public maxRange = 100;
    uint256 public targetNumber = 1;
    uint256 public coinRate = 0.001 ether;
    uint256 public coinRateMin = 0.001 ether;
    uint256 public listingFee = 0.001 ether;
    uint256 public prizeFee = 0.0005 ether;
    uint256 public saleThreshold = 0.01 ether;
    uint256 public prizePool;
    uint256 public winningPercentage = 100;
    uint256 public creatorsPercentageMax = 1000;
    uint256 public subMargin = 250;
    uint256 public xReq = 10;
    mapping(address => uint256) public creatorSupport;
    mapping(address => address payable) public creatorRouting;
    mapping(uint256 => string) public _info;

    address payable public payments;
    address public projectLeader;
    address[] public admins;

    struct Trade {
        address seller;
        address buyer;
        address contractAddress;
        uint[] ids;
        uint[] amounts;
        address For_contractAddress;
        uint[] For_ids;
        uint[] For_amounts;
        uint price;
        address ERC20Address;
        uint256 ERC20Amount;
        bool isActive;
    }

    //maximum size of trade array is 2^256-1
    Trade[] public trades;

    //address(0) = 0x0000000000000000000000000000000000000000

    constructor() ERC20("Easy", "EZT"){
        projectLeader = msg.sender;
    }

    function totalSupply() public view override returns (uint256) { return _totalSupply; }

    /**
    @dev Creates a new trade listing with the specified parameters.
    @param _luckyNumber The lucky number used for the prize pool payout.
    @param _buyer The address of the buyer of the trade.
    @param _tokenAddress The address of the token to be traded (ERC20, ERC721, or ERC1155).
    @param _ids The array of token IDs being traded (for ERC721 and ERC1155), leave empty for ERC20.
    @param _amounts The array of token amounts being traded (for ERC1155 or ERC20).
    @param For_tokenAddress The address of the token to be received in exchange.
    @param For_ids The array of token IDs being received in exchange (for ERC721 and ERC1155).
    @param For_amounts The array of token amounts being received in exchange (for ERC1155).
    @param _price The price of the trade.
    @param _ERC20Address The address of the ERC20 token being used for payment (if any).
    @param _ERC20Amount The amount of ERC20 tokens being used for payment (if any).
    @dev The function is payable and requires that the sent value is greater than or equal to the listing fee.
    @dev The function transfers the traded tokens to this contract's address.
    @dev The function mints additional play coins if the sent value is greater than or equal to twice the listing fee.
    @dev The function updates the prize pool based on the sent value and the number of plays earned.
    @dev The function emits a TradeInitiated event to notify listeners of the new trade.
    Tokens Minted from this contract cannot be offered for Trade.
    */
    function createTrade(uint _luckyNumber, address _buyer, address _tokenAddress, uint[] memory _ids, uint[] memory _amounts, address For_tokenAddress, uint[] memory For_ids, uint[] memory For_amounts, uint _price, address _ERC20Address, uint256 _ERC20Amount) public payable{
        require(!paused, "Trading Paused");
        require(msg.value >= listingFee, "Insufficient Funds");
        uint256 _plays = 1;
        uint8 _tokenTypeID; //0 = OTHER, 1 = ERC721, 2 = ERC1155, 3 = ERC20

        if (_ids.length > 0) {
            if (_amounts.length <= 0) {
                // ERC721
                _tokenTypeID = 1;
                if (!IERC721(_tokenAddress).isApprovedForAll(msg.sender, address(this))) {
                    // Set approval to manage all tokens owned by the user
                    IERC721(_tokenAddress).setApprovalForAll(address(this), true);
                }
                for (uint256 i = 0; i < _ids.length; i++) {
                    uint256 _tokenID = _ids[i];
                    IERC721(_tokenAddress).safeTransferFrom(msg.sender, address(this), _tokenID);
                }
            }
            else {
                // ERC1155
                _tokenTypeID = 2;
                if (!IERC1155(_tokenAddress).isApprovedForAll(msg.sender, address(this))) {
                    // Set approval for your contract to manage the user's ERC1155 tokens
                    IERC1155(_tokenAddress).setApprovalForAll(address(this), true);
                }
                IERC1155(_tokenAddress).safeBatchTransferFrom(msg.sender, address(this), _ids, _amounts, "");
            }
        } 
        else if (_tokenAddress != address(0) && _tokenAddress != address(this) && _amounts.length == 1) {
            // ERC20
            _tokenTypeID = 3;
            if (IERC20(_tokenAddress).allowance(msg.sender, address(this)) < _amounts[0]) {
                // Set approval to transfer the specified amount of tokens
                IERC20(_tokenAddress).approve(address(this), _amounts[0]);
            }
            IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amounts[0]);
        }

        if (_tokenTypeID <= 0) {
            require(msg.value >= coinRate * xReq, "X Value Not Met, Nothing To Trade");
        }

        // Store trade information in a struct
        Trade memory newTrade = Trade(
            msg.sender,
            _buyer, 
            _tokenAddress, 
            _ids, 
            _amounts, 
            For_tokenAddress, 
            For_ids, 
            For_amounts, 
            _price,
            _ERC20Address,
            _ERC20Amount, 
            true);

        trades.push(newTrade);
        uint tradeIndex = trades.length - 1;

        // Every trade listing gives 1 prize play
        payoutPrize(_luckyNumber);

        // Check if extras can be minted
        if (msg.value >= coinRate * 2) {
            uint256 _extra = uint256(msg.value / coinRate) - 1;
            _plays += _extra;
            _mint(msg.sender, _extra);
            _totalSupply += _extra;
            randomCounter++;
        }
        randomCounter++;
    
        prizePool += msg.value - (listingFee - prizeFee) * _plays;

        // Emit an event to notify listeners of the new trade
        emit TradeInitiated(tradeIndex, _tokenTypeID);
    }

    /**
    @dev Completes a trade specified by tradeIndex by transferring the buyer's payment to the seller and transferring the tokens to the buyer.
    The function first checks that the trade is still active and that the caller is either the buyer or the trade is a public trade.
    Then, it transfers the specified tokens from the buyer to the seller and from the seller to the buyer. It marks the trade as completed, adds a fee to the contract's address, and sends the remaining payment to the seller.
    The TradeCompleted event is emitted to notify listeners of the completed trade.
    @param tradeIndex The index of the trade to be completed in the trades array.
    */
    function completeTrade(uint tradeIndex) public payable nonReentrant {
        require(!paused, "Trading Paused");

        Trade storage trade = trades[tradeIndex];
        require(trade.isActive, "Trade is not active");
        require(msg.sender == trade.buyer || trade.buyer == address(0), "Only the specified buyer can complete the trade");
        
        // Mark the trade as completed
        trade.isActive = false;
        uint256 creatorPercentage = creatorSupport[trade.contractAddress];

        if (trade.ERC20Amount > 0) {
            // Ensure the buyer has sent the specified ERC20 tokens
            require(IERC20(trade.ERC20Address).balanceOf(msg.sender) >= trade.ERC20Amount, "Insufficient ERC20 tokens sent to cover the seller's price");

            if (IERC20(trade.ERC20Address).allowance(msg.sender, address(this)) < trade.ERC20Amount) {
                // Set approval to transfer the specified amount of tokens
                IERC20(trade.ERC20Address).approve(address(this), trade.ERC20Amount);
            }

            // Calculate creator percentage
            uint256 contractFee_ERC20 = (trade.ERC20Amount * creatorPercentage) / creatorsPercentageMax;

            // Calculate the remaining amount to be sent to the seller
            uint256 payout_ERC20 = trade.ERC20Amount - contractFee_ERC20;

            if (contractFee_ERC20 > 0) {
                // Transfer the contract fee to the creator routing address
                IERC20(trade.ERC20Address).transferFrom(msg.sender, creatorRouting[trade.contractAddress], contractFee_ERC20);
            }           
            
            // Transfer the remaining amount to the seller
            IERC20(trade.ERC20Address).transferFrom(msg.sender, trade.seller, payout_ERC20);
        }

        if (trade.price > 0) {
            // Ensure the buyer has sent enough Ether to cover the seller's price
            require(msg.value >= trade.price, "Insufficient Ether sent to cover the seller's price");

            uint256 contractFee = (trade.price * creatorPercentage) / creatorsPercentageMax;
            uint256 payout = trade.price - contractFee;

            if (contractFee > 0) {
                // Add a percentage of the trade's price to the creator routing address
                address payable creatorRoutingAddress = payable(creatorRouting[trade.contractAddress]);
                require(payable(creatorRoutingAddress).send(contractFee), "Failed to send contract fee to creator routing address");
            }

            if (payout >= saleThreshold) {
                //Add prizeFee to the prizePool
                prizePool += prizeFee;
                payout -= prizeFee;
            }

            // Send the payout to the seller
            payable(trade.seller).transfer(payout);            
        }

        if (trade.For_ids.length > 0) {
            // Transfer user's tokens to the seller
            if (trade.For_amounts.length <= 0) {
                if (!IERC721(trade.For_contractAddress).isApprovedForAll(msg.sender, address(this))) {
                    // Set approval to manage all tokens owned by the user
                    IERC721(trade.For_contractAddress).setApprovalForAll(address(this), true);
                }
                for (uint256 i = 0; i < trade.For_ids.length; i++) {
                    uint256 tokenID = trade.For_ids[i];
                    IERC721(trade.For_contractAddress).safeTransferFrom(msg.sender, trade.seller, tokenID);
                }
            }
            else {
                if (!IERC1155(trade.For_contractAddress).isApprovedForAll(msg.sender, address(this))) {
                    // Set approval for your contract to manage the user's ERC1155 tokens
                    IERC1155(trade.For_contractAddress).setApprovalForAll(address(this), true);
                }
                IERC1155(trade.For_contractAddress).safeBatchTransferFrom(msg.sender, trade.seller, trade.For_ids, trade.For_amounts, "");
            }
        }
        
        if (trade.ids.length > 0) {
            // Transfer seller's tokens to the user
            if (trade.amounts.length <= 0) {
                for (uint256 i = 0; i < trade.ids.length; i++) {
                    uint256 tokenID = trade.ids[i];
                    IERC721(trade.contractAddress).safeTransferFrom(address(this), msg.sender, tokenID);
                }
            }
            else {
                IERC1155(trade.contractAddress).safeBatchTransferFrom(address(this), msg.sender, trade.ids, trade.amounts, "");
            }
        }
        else if (trade.contractAddress != address(0) && trade.contractAddress != address(this) && trade.amounts.length == 1) {
            // Transfer the coins from the contract to the user
            require(IERC20(trade.contractAddress).transfer(msg.sender, trade.amounts[0]), "Token transfer failed");
        }
        
        // Emit a TradeCompleted event
        emit TradeCompleted(tradeIndex);
    }

    /**
    @dev Cancels an active trade and returns user's tokens back to the user.
    @param tradeIndex Index of the trade to cancel.
    Emits a TradeCanceled event.
    */
    function cancelTrade(uint tradeIndex) public nonReentrant {
        Trade storage trade = trades[tradeIndex];

        require(trade.isActive, "Trade is not active");
        require(msg.sender == trade.seller, "Only the trade creator can cancel the trade");

        // Mark the trade as canceled
        trade.isActive = false;
        
        if (trade.ids.length > 0) {
            // Return user's tokens to the user
            if (trade.amounts.length <= 0) {
                for (uint256 i = 0; i < trade.ids.length; i++) {
                    uint256 tokenID = trade.ids[i];
                    IERC721(trade.contractAddress).safeTransferFrom(address(this), msg.sender, tokenID);
                }
            }
            else {
                IERC1155(trade.contractAddress).safeBatchTransferFrom(address(this), msg.sender, trade.ids, trade.amounts, "");
            }
        }
        else if (trade.contractAddress != address(0) && trade.contractAddress != address(this) && trade.amounts.length == 1) {
            // Transfer the coins from the contract to the user
            require(IERC20(trade.contractAddress).transfer(msg.sender, trade.amounts[0]), "Token transfer failed");
        }

        randomCounter--;

        // Emit a TradeCanceled event
        emit TradeCanceled(tradeIndex);
    }

    /**
    @dev Returns an array of active trade indexes created by the specified user.
    @param user The address of the user whose active trades will be retrieved.
    @return result array of active trade indexes created by the specified user.
    */
    function getActiveTradesForUser(address user) public view returns (uint[] memory) {
        uint[] memory activeTradeIndexes = new uint[](trades.length);
        uint numActiveTrades = 0;
        for (uint i = 0; i < trades.length; i++) {
            if (trades[i].isActive && trades[i].seller == user) {
                activeTradeIndexes[numActiveTrades] = i;
                numActiveTrades++;
            }
        }
        uint[] memory result = new uint[](numActiveTrades);
        for (uint i = 0; i < numActiveTrades; i++) {
            result[i] = activeTradeIndexes[i];
        }
        return result;
    }

    /**
    @notice Retrieves an array based on the specified option and trade index.
    @dev This function is used to retrieve specific arrays (`ids`, `amounts`, `For_amounts`, `For_ids`) from the `trades` array.
    @param option The option indicating which array to retrieve:
         - 0: Retrieve `ids` array
         - 1: Retrieve `amounts` array
         - 2: Retrieve `For_amounts` array
         - 3: Retrieve `For_ids` array
    @param index The index of the Trade in the `trades` array.
    @return The array of uint values based on the specified option and trade index.
         If the specified option is invalid or the trade index is out of range, an empty uint array is returned.
    @dev Requirements:
         - The specified trade index must be within the range of existing trades.
    */
    function getTradeArray(uint8 option, uint index) external view returns (uint[] memory) {
        require(index < trades.length, "Index Does Not Exist");
        if (option == 0) {
            //trade.ids
            return trades[index].ids;
        }
        else if (option == 1) {
            //trade.amounts
            return trades[index].amounts;
        }
        else if (option == 2) {
            //trade.For_amounts
            return trades[index].For_amounts;
        }
        else if (option == 3) {
            //trade.For_ids
            return trades[index].For_ids;
        }
        else {
            return new uint[](0);
        } 
    }

    /**
    @dev Sets the address for receiving creator percentage for a specific contract.
    @param _contractAddress The address of the contract to set the routing address for.
    @param _percentage The percentage of the trade price to be added as a fee. Must be 100 or less.
    @param _creatorRouting The address that will receive the creator cut percentage.
    Emits a `CreatorSupportSet` event.
    Requirements:
    - Only the owner of the given contract can call this function.
    - The percentage must be creatorsPercentageMax or less.
    */
    function setCreatorSupport(address _contractAddress, uint256 _percentage, address _creatorRouting) public {
        require(msg.sender == Ownable(_contractAddress).owner(), "Only contract owner can use this function");
        require(_creatorRouting != address(0), "Creator routing address cannot be 0");
        require(_percentage <= creatorsPercentageMax - ((creatorsPercentageMax * subMargin) / creatorsPercentageMax), "Creator percentage must be less or equal to creatorsPercentageMax");
        creatorRouting[_contractAddress] = payable(_creatorRouting);
        creatorSupport[_contractAddress] = _percentage;
        emit CreatorSupportSet(_contractAddress, _percentage, _creatorRouting);
    }

    /**
    @dev Set the minimum and maximum range values.
    @param _minRange The new minimum range value.
    @param _maxRange The new maximum range value.
    */
    function setRange(uint256 _minRange, uint256 _maxRange) public onlyAdmins {
        minRange = _minRange;
        maxRange = _maxRange;
    }

    //determines if user has won
    function isWinner(uint _luckyNumber) internal view returns (bool) {
        return targetNumber == randomNumber(minRange, maxRange, _luckyNumber);
    }

    //"Randomly" returns a number >= _min and <= _max.
    function randomNumber(uint _min, uint _max, uint _luckyNumber) internal view returns (uint256) {
        uint random = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            randomCounter,
            _luckyNumber)
        )) % (_max + 1 - _min) + _min;
        
        return random;
    }

    //Payout the Prize to the winner if the "lucky number" matches the target number
    function payoutPrize(uint256 _luckyNumber) internal returns (bool) {
        if (prizePool != 0 && isWinner(_luckyNumber)) {
            // Calculate the payout as a percentage of the prize pool
            uint256 payout = payoutPrizeEstimate();
            if (payout > 0 && address(this).balance >= payout) {
                prizePool -= payout;
                // Send the payout to the player's address
                bool success = payable(msg.sender).send(payout);
                require(success, "Failed to send payout to player");
                emit PrizePoolWinner(msg.sender, payout);
                return true; // the player won
            }
        }
        return false; // the player lost
    }

    /**
    @dev Estimate the Prize Payout
    */
    function payoutPrizeEstimate() public view returns(uint256) {
        return (prizePool * winningPercentage) / 100;
    }

    /**
    @dev Allows a player to insert coins to participate in the game.
    The function requires the player to have enough coins in their balance to play the specified number of times.
    The function then runs a loop to play the game for the specified number of times, calling the internal
    payoutPrize function to determine whether the player has won a prize. If the player wins a prize, the
    number of coins used is incremented, and the loop is exited. Finally, the function transfers the
    total number of coins used to the contract address.
    @param _luckyNumber The number the player selects as their lucky number to participate in the game.
    @param _plays The number of times the player wishes to play the game.
    */
    function insertCoin(uint256 _luckyNumber, uint256 _plays) public payable nonReentrant {
        require(!isContract(msg.sender), "Function can only be called by a wallet");
        require(_plays > 0, "Number of plays must be greater than 0.");
        require(balanceOf(msg.sender) >= _plays, "You don't have enough coins!");

        uint256 coinsUsed = 0;
        for (uint256 i = 0; i < _plays; i++) {
            coinsUsed = i + 1;
            if (payoutPrize(_luckyNumber)) {
                break;
            }
        }

        transfer(address(this), coinsUsed);
    }

    /**
    @dev Allows the user to buy a specified number of coins from the contract, if any are available.
    The cost of the coins is calculated based on the current rate, and the user must send enough ether
    to cover the cost. Any excess ether sent will be refunded.
    Requirements:
    _numCoins: the number of coins to purchase, must be greater than 0.
    msg.value: the amount of ether sent by the user must be greater than or equal to coinRateMin and the
    cost of the coins (_numCoins * coinRate).
    The contract must have at least _numCoins available to sell.
    Effects:
    The user's account is credited with the purchased coins.
    Any excess ether sent by the user is refunded.
    */
    function buyCoins(uint256 _numCoins) public payable nonReentrant {
        require(!isContract(msg.sender), "Function can only be called by a wallet");
        require(_numCoins > 0, "Number of coins must be greater than 0.");

        // Calculate the cost of the coins based on the current rate
        uint256 cost = _numCoins * coinRate;

        // Ensure the user has sent enough ether to cover the cost
        require(msg.value >= coinRateMin && msg.value >= cost, "Insufficient funds.");

        // Check that the contract has enough coins to sell
        require(balanceOf(address(this)) >= _numCoins, "Not enough coins in contract.");

        // Transfer the coins from the contract to the user
        require(IERC20(address(this)).transfer(msg.sender, _numCoins), "Token transfer failed");

        // Refund any excess sent by the user
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }

    /**
    @dev Allows a user to donate funds to the prize pool with an optional tip for the developer.
    @param _tipPercentage The percentage of the donation to be given as a tip to the developer. Must be between 0 and 99.
    */
    function donateToPrizePoolTipDev(uint8 _tipPercentage) public payable {
        require(msg.value > 0, "Donation amount must be greater than 0.");
        require(_tipPercentage >= 0 && _tipPercentage < 100, "Tip percentage must be less than 100.");

        uint256 _toDev = msg.value * _tipPercentage / 100;
        uint256 _toPrizePool = msg.value - _toDev;

        // Add calculated donation to the prize pool
        prizePool += _toPrizePool;

        // Emit an event to log the donation
        emit DonationReceived(msg.sender, _toPrizePool, _toDev);
    }

    /**
    @dev Admin can set the new service fees, thresholds, etc in WEI.
    @param _option The option to change. 
    0 = listingFee, 
    1 = saleThreshold, 
    2 = targetNumber, 
    3 = winningPercentage, 
    4 = creatorsPercentageMax, 
    5 = coinRate,
    6 = coinRateMin, 
    7 = subMargin, 
    8 = xReq, 
    9 = paused,  
    @param _newValue The new value for the option selected. 0 = pause, 1 = unpaused 
    Note: Use http://etherscan.io/unitconverter for conversions 1 ETH = 10^18 WEI.
    */
    function setOptions(uint256 _option, uint256 _newValue) public onlyAdmins {
        require(_option >= 0 && _option <= 9, "Option Not Found");

        if (_option == 0){
            //Set the price to list a trade.
            listingFee = _newValue;
            return;
        }

        if (_option == 1){
            //Set the sale amount required to subtract prize fee.
            saleThreshold = _newValue;
            return;
        }

        if (_option == 2){
            require(_newValue >= minRange && _newValue <= maxRange, "Out Of Range");
            //Set the target number that will determine the winner.
            targetNumber = _newValue;
            return;
        }

        if (_option == 3){
            require(_newValue >= 0 && _newValue <= 100, "100 Or Less");
            //Set the prize pool percentage the winner will receive.
            winningPercentage = _newValue;
            return;
        }

        if (_option == 4){
            require(_newValue >= 0 && _newValue <= 10**18, "10**18 Or Less");
            //Set the max percentage the creator will receive if support is set.
            creatorsPercentageMax = _newValue;
            return;
        }

        if (_option == 5) {
            require(_newValue >= 0 && _newValue <= 10**18, "10**18 Or Less");
            uint256 _calcCoinRate = payoutPrizeEstimate() * _newValue / 10**18;
            if (_calcCoinRate < coinRateMin) {
                coinRate = coinRateMin;
            }
            else {
                coinRate = _calcCoinRate;
            }
            return;
        }

        if (_option == 6) {
            require(_newValue >= listingFee, "Must Be Listing Fee Or Higher");
            coinRateMin = _newValue;
            return;
        }

        if (_option == 7){
            require(_newValue >= 0 && _newValue <= 10**18, "10**18 Or Less");
            //Set the limit margin for the creators percentage.
            subMargin = _newValue;
            return;
        }

        if (_option == 8){
            //Set the requirement multiplier for the trade listing if no trade is entered
            xReq = _newValue;
            return;
        }

        if (_option == 9){
            //Set the pause state for trading
            require(_newValue == 0 || _newValue == 1, "Value Must Be 0 or 1");
            if (_newValue != 0) {
                // Unpaused
                paused = false;
            }
            else {
                // Paused
                paused = true;
            }
            return;
        }
    }

    /**
    @dev Admin can set the payout address.
    @param _address The address must be a wallet or a payment splitter contract.
    */
    function setPayoutAddress(address _address) external onlyOwner{
        payments = payable(_address);
    }

    /**
    @dev Admin can pull funds to the payout address.
    */
    function withdraw() public onlyAdmins {
        require(payments != address(0), "Admin payment address has not been set");
        uint256 payout = address(this).balance - prizePool;
        (bool success, ) = payable(payments).call{ value: payout } ("");
        require(success, "Failed to send funds to admin");
    }

    /**
    @dev Admin can pull ERC20 funds to the payout address.
    */
    function withdraw(address token, uint256 amount) public onlyAdmins {
        require(token != address(0), "Invalid token address");

        IERC20 erc20Token = IERC20(token);
        uint256 balance = erc20Token.balanceOf(address(this));

        require(amount <= balance, "Insufficient balance");
        require(erc20Token.transfer(payments, amount), "Token transfer failed");
    }

    /**
    @dev Auto send funds to the payout address.
    Triggers only if funds were sent directly to this address from outside the contract.
    */
    receive() external payable {
        require(payments != address(0), "Pay?");
        uint256 payout = msg.value;
        payments.transfer(payout);
    }

    /**
    @dev Throws if called by any account other than the owner or admin.
    */
    modifier onlyAdmins() {
        _checkAdmins();
        _;
    }

    /**
    @dev Throws if the sender is not the owner or admin.
    */
    function _checkAdmins() internal view virtual {
        require(checkIfAdmin(), "!A");
    }

    function checkIfAdmin() public view returns(bool) {
        if (msg.sender == owner() || msg.sender == projectLeader) {
            return true;
        }
        if (admins.length > 0) {
            for (uint256 i = 0; i < admins.length; i++) {
                if (msg.sender == admins[i]) {
                    return true;
                }
            }
        }
        
        // Not an Admin
        return false;
    }

    /**
    @dev Owner and Project Leader can set the addresses as approved Admins.
    Example: ["0xADDRESS1", "0xADDRESS2", "0xADDRESS3"]
    */
    function setAdmins(address[] calldata _users) public onlyAdmins {
        require(msg.sender == owner() || msg.sender == projectLeader, "Not Owner or Project Leader");
        delete admins;
        admins = _users;
    }

    /**
    @dev Owner or Project Leader can set the address as new Project Leader.
    */
    function setProjectLeader(address _user) external {
        require(msg.sender == owner() || msg.sender == projectLeader, "Not Owner or Project Leader");
        projectLeader = _user;
    }

    // Helper function to check if an address is a contract
    function isContract(address _address) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    /**
    @dev Admins can set info at a specific info index.
    */
    function setInfo(uint256 _index, string calldata _text) public onlyAdmins {
        _info[_index] = _text;
    }
}