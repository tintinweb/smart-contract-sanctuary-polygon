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
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.17;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.17;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721AQueryable.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *
     * - `addr = address(0)`
     * - `startTimestamp = 0`
     * - `burned = false`
     * - `extraData = 0`
     *
     * If the `tokenId` is burned:
     *
     * - `addr = <Address of owner before token was burned>`
     * - `startTimestamp = <Timestamp when token was burned>`
     * - `burned = true`
     * - `extraData = <Extra data when token was burned>`
     *
     * Otherwise:
     *
     * - `addr = <Address of owner>`
     * - `startTimestamp = <Timestamp of start of ownership>`
     * - `burned = false`
     * - `extraData = <Extra data at start of ownership>`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start < stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
//   _________                     .__        
//  /   _____/ ____   _____   ____ |__| ____  
//  \_____  \ /  _ \ /     \ /    \|  |/  _ \ 
//  /        (  <_> )  Y Y  \   |  \  (  <_> )
// /_______  /\____/|__|_|  /___|  /__|\____/ 
//         \/             \/     \/     
// Somnio.io

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface GolemContract {
    function upgrade(uint256[] memory _tokensToBurn, address _owner, uint8 _element, uint8 _classTier) external payable returns (uint256);
    function ownerOf(uint _tokenId) external view returns (address);
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

interface ShrineContract {
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

struct GolemResource {
    uint256 tokenId;
    uint8 classTier;
    uint8 element;
}

contract ServiceContract is Ownable {
    using Strings for uint256;

    event Attached(uint256 indexed tokenId, uint256 shrineTokenId, address owner, uint256 timestamp);
    event Detached(uint256 indexed tokenId, uint256 shrineTokenId, address owner, uint256 timestamp);
    event ShrinePlaced(uint256 indexed tokenId, address owner, uint256 timestamp);
    event ShrineRemoved(uint256 indexed tokenId, address owner, uint256 timestamp);

    uint8 constant TOKENS_REQUIRED_FOR_UPGRADE = 4;
    uint8 constant MAX_SHRINE_PLACED_AMOUNT = 5;
    uint8 constant MAX_SHRINE_SLOTS = 4;
    uint8 constant MAX_CLASS_TIER = 5;

    address public golemContractAddress;
    address public shrineContractAddress;

    GolemContract _golemContract;
    ShrineContract _shrineContract;
    bool public paused;

    mapping(uint256 => uint8) public golemTokenIdToClass;
    mapping(uint256 => uint8) public golemTokenIdToElement;
    mapping(uint256 => uint256) public golemTokenIdToShrineTokenId;
    mapping(uint256 => uint256[MAX_SHRINE_SLOTS]) public shrineTokenIdToGolemTokenIds;
    mapping(uint256 => bool) public shrineTokenIdToPlaced;
    mapping(address => uint8) public shrineOwnerToPlacedAmount;
    mapping(uint8 => uint256) public classTierToNumerator;

    constructor(
        address _golemContractAddress,
        address _shrineContractAddress
    ) {
        golemContractAddress = _golemContractAddress;
        shrineContractAddress = _shrineContractAddress;
        _golemContract = GolemContract(golemContractAddress);
        _shrineContract = ShrineContract(shrineContractAddress);
        classTierToNumerator[1] = 3906250000000000;
        classTierToNumerator[2] = 15625000000000000;
        classTierToNumerator[3] = 62500000000000000;
        classTierToNumerator[4] = 250000000000000000;
        classTierToNumerator[5] = 1000000000000000000;
        setPaused(true);
    }

    function getFreeShrineSlots(uint256 _shrineTokenId) public view returns (uint8) {
        uint8 freeSlots = 0;
        for (uint8 i = 0; i < MAX_SHRINE_SLOTS; i++) {
            if (shrineTokenIdToGolemTokenIds[_shrineTokenId][i] == 0) {
                freeSlots++;
            }
        }
        return freeSlots;
    }

    function transferShrineOwnershipStateUpdate(uint256 _shrineTokenId, address _owner) external {
        require(msg.sender == shrineContractAddress, "Sender must be the shrine contract");
        for (uint8 i = 0; i < MAX_SHRINE_SLOTS; i++) {
            shrineTokenIdToGolemTokenIds[_shrineTokenId][i] = 0;
            golemTokenIdToShrineTokenId[shrineTokenIdToGolemTokenIds[_shrineTokenId][i]] = 0;
        }
        shrineOwnerToPlacedAmount[_owner] -= 1;
        shrineTokenIdToPlaced[_shrineTokenId] = false;
        emit ShrineRemoved(_shrineTokenId, _owner, block.timestamp);
    }
    
    function calculateTotalWorth(address _owner) external view returns (uint256) {
         uint256 totalWorth = 0;
         uint256[] memory shrineTokenIds = _shrineContract.tokensOfOwner(_owner);
         for (uint8 i = 0; i < shrineTokenIds.length; i++) {
            totalWorth += calculateShrineWorth(shrineTokenIds[i]);
         }
        return totalWorth;
    }

    function calculateShrineWorth(uint256 _shrineId) public view returns (uint256) {
        uint256 shrineWorth = 0;
        for (uint8 i = 0; i < MAX_SHRINE_SLOTS; i++) {
            if (shrineTokenIdToGolemTokenIds[_shrineId][i] != 0) {
                require(golemTokenIdToClass[shrineTokenIdToGolemTokenIds[_shrineId][i]] > 0, "Invalid golem class tier");
                uint8 golemClassTier = golemTokenIdToClass[shrineTokenIdToGolemTokenIds[_shrineId][i]];
                require(golemClassTier <= MAX_CLASS_TIER, "Invalid golem class tier");
                uint256 golemNumerator = classTierToNumerator[golemClassTier];
                require(golemNumerator > 0, "Invalid golem numerator");
                shrineWorth += (golemNumerator / 100);
            }
        }
        return shrineWorth;
    }


    function detachGolem(uint256 _golemTokenId) public {
        if (!isGolemAttached(_golemTokenId)) {
            revert("ERR: Golem not attached.");
        }
        uint256 shrineTokenId = golemTokenIdToShrineTokenId[_golemTokenId];

        require(shrineTokenIdToPlaced[shrineTokenId], "ERR: Shrine is not placed");
        require(IERC721(golemContractAddress).ownerOf(_golemTokenId) == msg.sender);
        require(IERC721(shrineContractAddress).ownerOf(shrineTokenId) == msg.sender);

        golemTokenIdToShrineTokenId[_golemTokenId] = 0;
        for (uint8 i = 0; i < MAX_SHRINE_SLOTS; i++) {
            if (shrineTokenIdToGolemTokenIds[shrineTokenId][i] == _golemTokenId) {
                shrineTokenIdToGolemTokenIds[shrineTokenId][i] = 0;
            }
        }
        emit Detached(_golemTokenId, shrineTokenId, msg.sender, block.timestamp);
    }

    function isGolemAttached(uint256 _golemTokenId) public view returns (bool) {
        return golemTokenIdToShrineTokenId[_golemTokenId] != 0;
    }

    function attachGolem(uint256 _shrineTokenId, uint256 _golemTokenId) external {
        require(!paused, "ERR: Contract is paused");
        require(IERC721(golemContractAddress).ownerOf(_golemTokenId) == msg.sender, "ERR: You do not own this golem");
        require(IERC721(shrineContractAddress).ownerOf(_shrineTokenId) == msg.sender, "ERR: You do not own this shrine");
        require(shrineTokenIdToPlaced[_shrineTokenId], "ERR: Shrine is not placed");

        uint256 freeSlots = getFreeShrineSlots(_shrineTokenId);
        require(freeSlots > 0, "ERR: No free slots to assign golem on the given shrine!");

        shrineTokenIdToGolemTokenIds[_shrineTokenId][MAX_SHRINE_SLOTS-freeSlots] = _golemTokenId;
        golemTokenIdToShrineTokenId[_golemTokenId] = _shrineTokenId;
        emit Attached(_golemTokenId, _shrineTokenId, msg.sender, block.timestamp);
    }

    function placeShrine(uint256 _shrineTokenId) external {
        require(!paused, "ERR: Contract is paused");
        require(IERC721(shrineContractAddress).ownerOf(_shrineTokenId) == msg.sender, "ERR: You do not own this shrine");
        require(shrineOwnerToPlacedAmount[msg.sender] < MAX_SHRINE_PLACED_AMOUNT, "ERR: Max Shrines are already placed for this wallet");
        require(!shrineTokenIdToPlaced[_shrineTokenId], "ERR: Shrine is already placed");

        shrineOwnerToPlacedAmount[msg.sender] += 1;
        shrineTokenIdToPlaced[_shrineTokenId] = true;
        emit ShrinePlaced(_shrineTokenId, msg.sender, block.timestamp);
    }

    function removeShrine(uint256 _shrineTokenId) external {
        require(!paused, "ERR: Contract is paused");
        require(shrineOwnerToPlacedAmount[msg.sender] > 0, "ERR: You have no shrines placed");
        require(IERC721(shrineContractAddress).ownerOf(_shrineTokenId) == msg.sender, "ERR: You do not own this shrine");

        for (uint8 i = 0; i < shrineTokenIdToGolemTokenIds[_shrineTokenId].length; i++) {
            uint256 golemTokenId = shrineTokenIdToGolemTokenIds[_shrineTokenId][i];
            detachGolem(golemTokenId);
            golemTokenIdToShrineTokenId[golemTokenId] = 0;
        }

        shrineOwnerToPlacedAmount[msg.sender] -= 1;
        shrineTokenIdToPlaced[_shrineTokenId] = false;
        emit ShrineRemoved(_shrineTokenId, msg.sender, block.timestamp);
    }

    function getGolemResource(uint256 _golemTokenId) public view returns (GolemResource memory) {
        GolemResource memory golem;
        golem.tokenId = _golemTokenId;
        golem.classTier = golemTokenIdToClass[_golemTokenId];
        golem.element = golemTokenIdToElement[_golemTokenId];
        return golem;
    }

    /*
        Return the tokenIds attached to a shrine, position 0 is the shrine token ID itself followed by the 4 other token Ids.
        Token ID 0 implies nothing is attached to that slot.
    */
    function shrineToGolemsMapping(uint256 _shrineTokenId) public view returns (uint256[5] memory) {
        require(shrineTokenIdToPlaced[_shrineTokenId], "ERR: Shrine is not placed");

        uint256[5] memory shrineToGolemsConnection;
        shrineToGolemsConnection[0] = _shrineTokenId;
        for (uint8 i = 1; i <= shrineTokenIdToGolemTokenIds[_shrineTokenId].length; i++) {
            shrineToGolemsConnection[i] = shrineTokenIdToGolemTokenIds[_shrineTokenId][i - 1];
        }
        return shrineToGolemsConnection;
    }


    /*
        This is the only entry point to initiate a golem upgrade.
        Request received from client, validate the following before performing upgrade:

        1. All classes are the same
        2. All elements are the same
        3. The owner is the msg sender for all tokens

        Once validation passes perform the following
        
        1. Call upgrade which will raise an upgrade event from within golem contract
        2. Update the internal state mappings
    */
    function upgradeGolem(uint256[] memory _golemTokenIds) public {
        require(!paused, "ERR: Contract is paused");
        uint8 nextClassTier = golemTokenIdToClass[_golemTokenIds[0]] + 1;
        require(nextClassTier >= 2 && nextClassTier <= 5, "ERR: Invalid class tier upgrade");
        require(_golemTokenIds.length == TOKENS_REQUIRED_FOR_UPGRADE, "ERR: Upgrade requires 4 tokens.");
        for (uint256 i = 0; i < _golemTokenIds.length; i++) {
            require(golemTokenIdToElement[_golemTokenIds[i]] == golemTokenIdToElement[_golemTokenIds[0]], "ERR: Elements don't match");
            require(golemTokenIdToClass[_golemTokenIds[i]] == golemTokenIdToClass[_golemTokenIds[0]], "ERR: Classes don't match");
            require(_golemContract.ownerOf(_golemTokenIds[i]) == msg.sender);
        }
        
        uint256 nextTokenId = _golemContract.upgrade(_golemTokenIds, msg.sender, golemTokenIdToElement[_golemTokenIds[0]], nextClassTier);
        stateUpdatePostUpgrade(_golemTokenIds, nextTokenId);
    }

    /*
        This function is responsible for updating internal storage mappings after an upgrade is performed.
        This involves the following:
        
        1. Delete the entries in the class, element, shrine golem mappings. 
            (Note: This won't actually free the memory that was used to store the value, 
            it will just mark the memory as "deleted" and the value will be overwritten with the default value.)
        2. Set the state for the newly minted upgrade token
    */
    function stateUpdatePostUpgrade(uint256[] memory _golemTokenIds, uint256 _upgradedTokenId) internal {
        // Get the element and new class before deletion
        uint8 newClassTier = golemTokenIdToClass[_golemTokenIds[0]] + 1;
        uint8 element = golemTokenIdToElement[_golemTokenIds[0]];

        // Remove the burnt golem tokens from class and element mappings
        for (uint8 i = 0; i < _golemTokenIds.length; i++) {
            delete golemTokenIdToClass[_golemTokenIds[i]];
            delete golemTokenIdToElement[_golemTokenIds[i]];
            for (uint8 k = 0; k < MAX_SHRINE_SLOTS; k++) {
                uint256 shrineId = golemTokenIdToShrineTokenId[_golemTokenIds[i]];
                if (shrineTokenIdToGolemTokenIds[shrineId][k] == _golemTokenIds[i]) {
                    shrineTokenIdToGolemTokenIds[golemTokenIdToShrineTokenId[_golemTokenIds[i]]][k] = 0;
                }
            }
            delete golemTokenIdToShrineTokenId[_golemTokenIds[i]];
        }
        golemTokenIdToClass[_upgradedTokenId] = newClassTier;
        golemTokenIdToElement[_upgradedTokenId] = element;
        golemTokenIdToShrineTokenId[_upgradedTokenId] = 0; 
    }

    /*
        This function is called via the after token transfer hook in the golem contract to set initial state on fresh mints.
    */
    function stateUpdateFreshGolemMint(uint256 _mintedTokenId, uint8 _element) external {
        require(msg.sender == golemContractAddress, "Invalid Caller");
        golemTokenIdToClass[_mintedTokenId] = 1;
        golemTokenIdToElement[_mintedTokenId] = _element;
        golemTokenIdToShrineTokenId[_mintedTokenId] = 0;
    }


    /*
        This function is called via the after token transfer hook in the golem contract to set initial state on fresh mints.
    */
    function stateUpdateFreshShrineMint(uint256 _mintedTokenId) external {
        require(msg.sender == shrineContractAddress, "Sender must be the shrine contract address.");
        for (uint i = 0; i < MAX_SHRINE_SLOTS; i++) {
            shrineTokenIdToGolemTokenIds[_mintedTokenId][i] = 0;
        }
    }

    /*
        When a golem is transferred from person to person, it's class and element will remain the same but the shrine connection
        must be reset.
    */
    function stateUpdateExistingGolemTransfer(uint256 _golemTokenId) external {
        require(msg.sender == golemContractAddress, "Sender must be the golem contract address.");
        uint256 shrineTokenId = golemTokenIdToShrineTokenId[_golemTokenId];
        for (uint8 i = 0; i < MAX_SHRINE_SLOTS; i++) {
            if (shrineTokenIdToGolemTokenIds[shrineTokenId][i] == _golemTokenId) {
                shrineTokenIdToGolemTokenIds[shrineTokenId][i] = 0;
            }
        }
        golemTokenIdToShrineTokenId[_golemTokenId] = 0;
    }

    function getPaused() public view returns (bool) {
        return paused;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function getShrineTokenIdToGolemTokenIds(uint256 _shrineId) external view returns (uint256[4] memory){
        return shrineTokenIdToGolemTokenIds[_shrineId];
    }
}