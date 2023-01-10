// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./interface/IBadgeSet.sol";
import "./BitMaps.sol";

/**
* @title BadgeSet
* @author Brian Watroba
* @notice Non-transferrable ERC1155 Token standard for accomplishments, certifications, and proof of completion
* @dev Standard ERC1155 approval and transfer functions are overridden to revert
* @custom:version 1.0.4
*/
contract BadgeSet is
    Context,
    ERC165,
    IERC1155,
    IBadgeSet,
    Ownable,
    IERC1155MetadataURI
{
    using BitMaps for BitMaps.BitMap;

    address public walletRegistry;
    uint96 public maxBadgeType;
    string public contractURI;
    string private _uri;
    mapping(address => BitMaps.BitMap) private _balances;
    mapping(uint256 => uint256) private _expiries;
    address private constant ZERO_ADDRESS = address(0);
    uint256 private constant BITMAP_SIZE = 256;

    constructor(
       
    ) {
        // walletRegistry = _walletRegistry;
        // setURI(
        //     string.concat(
        //         _baseUri,
        //         Strings.toHexString(uint160(address(this)), 20),
        //         "/"
        //     )
        // ); // base + address(this) + /
        // setContractURI(
        //     string.concat(
        //         _baseUri,
        //         Strings.toHexString(uint160(address(this)), 20),
        //         "/"
        //     )
        // ); // base + address(this) + /
        // transferOwnership(_owner);
    }

    /**
     * @notice Get token metadata URI
     * @param id token id
     * @return URI string
     */
    function uri(uint256 id) external view returns (string memory) {
        return string.concat(_uri, Strings.toString(id));
    }

    /**
     * @notice Get token expiry timestamp (unix)
     * @param tokenId token id
     * @return expiry timestamp (unix)
     */
    function expiryOf(uint256 tokenId) external view returns (uint256) {
        return _expiries[tokenId];
    }

    /**
     * @notice Get balances for a list of token/address pairs
     * @param accounts account addresses
     * @param ids token ids
     * @return array of balances for each token/address pair
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) external view returns (uint256[] memory) {
        uint256 count = accounts.length;
        if (count != ids.length) revert ArrayParamsUnequalLength();
        uint256[] memory batchBalances = new uint256[](count);
        for (uint256 i = 0; i < count; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }

    /**
     * @notice Mint token to an account address
     * @dev Checks if "to" address param has an associated linked wallet (in WalletRegistry). If yes, mints to that address. If no, mints to the "to" address. Only callable by contract owner.
     * @param to Address to mint to
     * @param badgeType Desired badge type to mint (must not currently own)
     * @param expiry Token expiration timestamp (unix). If no expiry, input "0"
     * @return tokenId Token id of successfully minted token
     */
    function mint(
        address to,
        uint96 badgeType,
        uint256 expiry
    ) external onlyOwner returns (uint256 tokenId) {
        address user = to; //getUser(to);

        tokenId = _mint(user, badgeType, expiry);

        emit TransferSingle(_msgSender(), ZERO_ADDRESS, user, tokenId, 1);
        _doSafeTransferAcceptanceCheck(
            _msgSender(),
            ZERO_ADDRESS,
            user,
            tokenId,
            1,
            ""
        );
    }

    /**
     * @notice Mint multiple tokens to an account address
     * @dev Checks if "to" address param has an associated linked wallet (in WalletRegistry). If yes, mints to that address. If no, mints to the "to" address. Only callable by contract owner.
     * @param account Address to mint to
     * @param badgeTypes Badge types to mint
     * @param expiries Token expiration timestamps (unix). If no expiries, input array of "0" (matching badgeTypes length)
     * @return tokenIds Token ids of successfully minted tokens
     */
    function mintBatch(
        address account,
        uint96[] memory badgeTypes,
        uint256[] memory expiries
    ) external onlyOwner returns (uint256[] memory tokenIds) {
        if (badgeTypes.length != expiries.length)
            revert ArrayParamsUnequalLength();
        address user = account;//getUser(account);
        uint256 mintCount = badgeTypes.length;

        tokenIds = new uint[](mintCount);
        uint[] memory amounts = new uint[](mintCount); // used in event

        for (uint256 i = 0; i < mintCount; i++) {
            uint256 tokenId = _mint(user, badgeTypes[i], expiries[i]);
            tokenIds[i] = tokenId;
            amounts[i] = 1;
        }

        emit TransferBatch(_msgSender(), ZERO_ADDRESS, user, tokenIds, amounts);
        _doSafeBatchTransferAcceptanceCheck(
            _msgSender(),
            ZERO_ADDRESS,
            user,
            tokenIds,
            amounts,
            ""
        );
    }

    /**
     * @notice Revoke (burn) a token from an account address
     * @dev Checks if "account" address param has an associated linked wallet (in WalletRegistry). If yes, revokes from that address. If no, revokes from the "account" address. Only callable by contract owner. Deletes token expiry.
     * @param account Address to revoke from
     * @param badgeType Badge type to revoke (must currently own)
     * @return tokenId Token id of successfully revoked token
     */
    function revoke(
        address account,
        uint96 badgeType
    ) external onlyOwner returns (uint256 tokenId) {
        address user = account;//getUser(account);
        tokenId = _revoke(user, badgeType);
        emit TransferSingle(_msgSender(), user, ZERO_ADDRESS, tokenId, 1);
    }

    /**
     * @notice Revoke (burn) multiple tokens from an account address
     * @dev Checks if "account" address param has an associated linked wallet (in WalletRegistry). If yes, revokes from that address. If no, revokes from the "account" address. Only callable by contract owner. Deletes token expiry.
     * @param account Address to revoke from
     * @param badgeTypes Desired badge types to revoke (must currently own)
     * @return tokenIds Token ids of successfully revoked tokens
     */
    function revokeBatch(
        address account,
        uint96[] memory badgeTypes
    ) external onlyOwner returns (uint[] memory tokenIds) {
        address user = account;//getUser(account);
        uint256 revokeCount = badgeTypes.length;

        tokenIds = new uint[](revokeCount); // used in event, return value
        uint[] memory amounts = new uint[](revokeCount); // used in event

        for (uint256 i = 0; i < revokeCount; i++) {
            uint256 tokenId = _revoke(user, badgeTypes[i]);
            tokenIds[i] = tokenId;
            amounts[i] = 1;
        }

        emit TransferBatch(_msgSender(), user, ZERO_ADDRESS, tokenIds, amounts);
    }

    // TODO: this should have a return check value
    /**
     * @notice Transition tokens from a lite wallet to a linked real wallet
     * @dev Badge (token) ownership state is stored in bitmaps. To save gas, this function copies over the "from" address's bitmap state (1 uint256 for each 256 token types) to the "to" address, and emits individual transfer events in a loop.
     * @param from Address to transiton all tokens from
     * @param to Address to transition all tokens to
     */
    function moveUserTokensToWallet(address from, address to) external {
       // if (getUser(from) != to) revert WalletNotLinked(to);
        uint256 bitmapCount = maxBadgeType / BITMAP_SIZE;
        for (uint256 i = 0; i <= bitmapCount; i++) {
            uint256 bitmap = _balances[from]._data[i];
            if (bitmap != 0) {
                emitTransferEvents(bitmap, from, to);
                _balances[to]._data[i] = bitmap; // copy over ownership bitmap
                delete _balances[from]._data[i]; // delete old ownership bitmap
            }
        }
        emit TransitionWallet(from, to);
    }

    // No-Ops for ERC1155 transfer and approval functions. BadgeSet tokens are Soulbound and cannot be transferred. Functions are included for ERC1155 interface compliance

    /** 
     * @notice will revert. Soulbound tokens cannot be transferred.
    */
    function setApprovalForAll(address operator, bool approved) external pure {
        revert SoulboundTokenNoSetApprovalForAll(operator, approved);
    }

    /** 
     * @notice will revert. Soulbound tokens cannot be transferred.
    */
    function isApprovedForAll(
        address account,
        address operator
    ) external pure returns (bool) {
        revert SoulboundTokenNoIsApprovedForAll(account, operator);
    }

    /** 
     * @notice will revert. Soulbound tokens cannot be transferred.
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external pure {
        revert SoulboundTokenNoSafeTransferFrom(from, to, id, amount, data);
    }

    /** 
     * @notice will revert. Soulbound tokens cannot be transferred.
    */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external pure {
        revert SoulboundTokenNoSafeBatchTransferFrom(
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @notice Update token metadata base URI
     * @param newuri New URI
     */
    function setURI(string memory newuri) public onlyOwner {
        _uri = newuri;
    }

    /**
     * @notice Update contract metadata URI
     * @param newuri New URI
     */
    function setContractURI(string memory newuri) public onlyOwner {
        contractURI = newuri;
    }

    /**
     * @notice Get token balance of an account address
     * @param account Account address
     * @param id Token id
     * @return balance Token balance (1 or 0)
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view returns (uint256 balance) {
        (uint96 _badgeType, address _account) = decodeTokenId(id);
        address user =  account;//getUser(_account);
        if (user != account) return 0;
        BitMaps.BitMap storage bitmap = _balances[user];
        bool owned = BitMaps.get(bitmap, _badgeType);
        return owned ? 1 : 0;
    }

    /**
     * @notice Returns a serialized token id based on a badgeType and owner account address
     * @dev Each user can only own one of each badge type. Serializing ids based on a badgeType and owner address allows us to have both shared, badgeType level metadata as well as individual token data (e.g. expiry timestamp). First 12 bytes = badgeType (uint96), next 20 bytes = owner address.
     * @param badgeType Badge type
     * @param account Owner account address
     * @return tokenId Serialized token id
     */
    function encodeTokenId(
        uint96 badgeType,
        address account
    ) public pure returns (uint256 tokenId) {
        tokenId = uint256(bytes32(abi.encodePacked(badgeType, account)));
    }

    /**
     * @notice Decodes a serialized token id to reveal its badgeType and owner account address
     * @param tokenId Serialized token id
     * @return badgeType Badge type
     * @return account Owner account address
     */
    function decodeTokenId(
        uint256 tokenId
    ) public pure returns (uint96 badgeType, address account) {
        badgeType = uint96(tokenId >> 160);
        account = address(uint160(uint256(((bytes32(tokenId) << 96) >> 96))));
    }

    /** 
     * @dev Verifies contract supports the standard ERC1155 interface
    */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /** 
     * @dev Internal shared function to mint tokens and set expiries
    */
    function _mint(
        address user,
        uint96 badgeType,
        uint256 expiry
    ) internal returns (uint256 tokenId) {
        tokenId = encodeTokenId(badgeType, user);

        bool isExpired = expiry > 0 && expiry <= block.timestamp;
        uint256 priorBalance = balanceOf(user, tokenId);
        if (isExpired) revert IncorrectExpiry(user, badgeType, expiry);
        if (priorBalance > 0)
            revert IncorrectBalance(user, badgeType, priorBalance); // token already owned

        BitMaps.BitMap storage balances = _balances[user];
        BitMaps.set(balances, badgeType);
        _expiries[tokenId] = expiry;

        uint96 nextPossibleNewBadgeType = uint96(maxBadgeType) + 1; // ensure new badgeTypes are one greater, pack bitmaps sequentially
        if (badgeType > nextPossibleNewBadgeType)
            revert NewBadgeTypeNotIncremental(badgeType, maxBadgeType);
        if (badgeType == nextPossibleNewBadgeType) maxBadgeType = badgeType;
    }

    /** 
     * @dev Internal shared function to revoke (burn) tokens and delete associated expiries
    */
    function _revoke(
        address user,
        uint96 badgeType
    ) internal returns (uint256 tokenId) {
        tokenId = encodeTokenId(badgeType, user);

        uint256 priorBalance = balanceOf(user, tokenId);
        if (priorBalance == 0)
            revert IncorrectBalance(user, badgeType, priorBalance); // token not owned

        BitMaps.BitMap storage balances = _balances[user];
        BitMaps.unset(balances, badgeType);
        delete _expiries[tokenId];
    }

    // /** 
    //  * @dev Checks if an account address has an associated linked real wallet in WalletRegistry. If so, returns it. Otherwise, returns original account address param value
    // */
    // function getUser(address account) internal view returns (address) {
    //     return IWalletRegistry(walletRegistry).getLinkedWallet(account);
    // }

    /** 
     * @dev Internal function to emit transfer events for each owned badge (used in transitioning tokens after wallet linking)
    */
    function emitTransferEvents(
        uint256 bitmap,
        address from,
        address to
    ) private {
        for (uint256 i = 0; i < BITMAP_SIZE; i++) {
            if (bitmap & (1 << i) > 0) {
                // token type is owned
                emit TransferSingle(
                    _msgSender(),
                    from,
                    to,
                    encodeTokenId(uint96(i), from),
                    1
                );
            }
        }
    }

    /** 
     * @dev ERC1155 receiver check to ensure a "to" address can receive the ERC1155 token standard, used in single mint
    */
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            // check if contract
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert ERC1155ReceiverRejectedTokens();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155ReceiverNotImplemented();
            }
        }
    }

    /** 
     * @dev ERC1155 receiver check to ensure a "to" address can receive the ERC1155 token standard, used in batch mint
    */
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.code.length > 0) {
            // check if contract
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert ERC1155ReceiverRejectedTokens();
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert ERC1155ReceiverNotImplemented();
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.9;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(
        BitMap storage bitmap,
        uint256 index
    ) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBadgeSet {
    error IncorrectExpiry(address user, uint96 badgeType, uint256 expiry);
    error IncorrectBalance(address user, uint96 badgeType, uint256 balance);
    error NewBadgeTypeNotIncremental(uint96 badgeType, uint256 maxBadgeType);
    error ArrayParamsUnequalLength();
    error WalletNotLinked(address walletAddress);
    error SoulboundTokenNoSetApprovalForAll(address operator, bool approved);
    error SoulboundTokenNoIsApprovedForAll(address account, address operator);
    error SoulboundTokenNoSafeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes data
    );
    error SoulboundTokenNoSafeBatchTransferFrom(
        address from,
        address to,
        uint256[] ids,
        uint256[] amounts,
        bytes data
    );
    error ERC1155ReceiverNotImplemented();
    error ERC1155ReceiverRejectedTokens();

    event TransitionWallet(
        address indexed kycAddress,
        address indexed walletAddress
    );

    function setURI(string memory newuri) external;

    function setContractURI(string memory newuri) external;

    function expiryOf(uint256 tokenId) external view returns (uint256);

    function mint(
        address account,
        uint96 badgeType,
        uint256 expiryTimestamp
    ) external returns (uint256 tokenId);

    function mintBatch(
        address to,
        uint96[] memory badgeTypes,
        uint256[] memory expiryTimestamps
    ) external returns (uint256[] memory tokenIds);

    function revoke(
        address account,
        uint96 badgeType
    ) external returns (uint256 tokenId);

    function revokeBatch(
        address to,
        uint96[] memory badgeTypes
    ) external returns (uint256[] memory tokenIds);

    function moveUserTokensToWallet(
        address kycAddress,
        address walletAddress
    ) external;

    function encodeTokenId(
        uint96 badgeType,
        address account
    ) external pure returns (uint256 tokenId);

    function decodeTokenId(
        uint256 tokenId
    ) external pure returns (uint96 badgeType, address account);
}