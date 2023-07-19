/**
 *Submitted for verification at polygonscan.com on 2023-07-18
*/

// Sources flattened with hardhat v2.16.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

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
interface IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

  
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]

  
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/utils/[email protected]

  
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


// File @openzeppelin/contracts/access/[email protected]

  
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


// File @openzeppelin/contracts/utils/introspection/[email protected]

  
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


// File @openzeppelin/contracts/token/ERC721/[email protected]

  
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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


// File @openzeppelin/contracts/utils/math/[email protected]

  
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


// File @openzeppelin/contracts/utils/[email protected]

  
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

  
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File contracts/aco2/interfaces/IAco2.sol

  
pragma solidity ^0.8.17;

interface IAco2 is IERC20 {

  function treeRewardPerMin() external view returns(uint256);

  function minAco2Claim() external view returns (uint256);

  function decimals() external view returns (uint256);

  function mint(address to, uint256 amount) external;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]

  
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// File contracts/trees/Interfaces/INftree.sol

  
pragma solidity ^0.8.17;


interface INftree is IERC721EnumerableUpgradeable {

    // Struct of a batch of trees with all the attributes
    struct Batch {
        uint256 no;
        uint256 initialSupply;
        uint256 plantTime;
        string baseURI;
        string baseExtension;
    }

    function initialize(Batch memory, address admin, address treesFactory) external;
    
    function isBlacklisted(uint256 tokenId) external view returns (uint256);
    
    function isUpgraded(uint256 tokenId) external view returns (bool);

    function getBatchDetails() external view returns (Batch memory);

    function balanceOfTree(uint256 tokenId) external view returns(uint256);

    function tokensOfOwner(address _owner) external view returns(uint256[] memory);
}


// File contracts/staking/interfaces/IStake.sol

  
pragma solidity ^0.8.17;

interface IStake {
	enum PlotType { STANDARD, PREMIUM, GENESIS }
	struct PlotDetails {
		uint256 id;
		uint256 maxStake;
		uint256 rewardPrcnt;
		uint256 stakeTreesBonusPrcnt;
		uint256 totalStaked;
	}
	struct StakeInfo {
		string plotType;
		uint256 plotId;
		uint256 timeStaked;
		uint256 timeLastClaim;
		uint256 cbyLocked;
	}

	function treeStakingInfo(uint256 batchNo, uint256 tokenId) external view returns (StakeInfo memory);

	function totalStakedOnStandard(uint256 plotId) external view returns (uint256);

	function totalStakedOnPremium(uint256 plotId) external view returns (uint256);

	function totalStakedOnGenesis(uint256 plotId) external view returns (uint256);

}


// File contracts/trees/Interfaces/ICbyPriceProxy.sol

  
pragma solidity ^0.8.17;

interface ICbyPriceProxy {
    
    function fetchCbyPrice() external view returns (uint256);

    function calculateCbyValue() external view returns (uint256);
}


// File contracts/trees/Interfaces/ITree.sol

  
pragma solidity ^0.8.17;

interface ITree is IERC721EnumerableUpgradeable {
    struct Batch {
      uint256 no;
      uint256 maxSupply;
      uint256 plantTime;
      string baseURI;
      string baseExtension;
    }
    
  function initialize(Batch calldata _batch, address admin, address _treesFactory) external;

  function baseURI() external view returns (string memory);

  function getBatchDetails() external view returns (Batch memory);
  
  function safeMint(address to, uint256 tokenId) external;
  
  function burn(uint256 tokenId) external;
}


// File contracts/trees/Interfaces/ITreesFactory.sol

  
pragma solidity ^0.8.17;





interface ITreesFactory {

  struct Trees {
    INftree nftree;
    ITree staking;
    ITree ecoEmpire;
    ITree backup;
  }

  function MAX_FEE() external view returns (uint256);

  function FEE_DECIMALS() external view returns (uint256);

  function UNSTAKE_FEE_WALLET() external view returns (address);

  function cby() external view returns (IERC20);

  function batchMintLimit() external view returns (uint256);

  function stakeContract() external returns (IStake);

  function cbyPriceProxy() external returns (ICbyPriceProxy);

  function nftreeSupply() external view returns (uint256);

  function stakingSupply() external view returns (uint256);

  function ecoEmpireSupply() external view returns (uint256);

  function backupSupply() external view returns (uint256);

  function batchExsist(uint256 batchNo) external view returns (Trees memory);

  function getNftreeOfBatch(uint256 batchNo) external view returns (INftree);

  function getStakingOfBatch(uint256 batchNo) external view returns (ITree);

  function getEcoEmpireOfBatch(uint256 batchNo) external view returns (ITree);

  function getBackupOfBatch(uint256 batchNo) external view returns (ITree);

  function totalNftrees() external view returns (uint256);

  function addNftreeBatch(uint256 batchNo, uint256 totalSupply, uint256 plantTime, string memory baseURI, string memory baseExtension) external;

}


// File contracts/staking/StakeV3.sol

  
pragma solidity ^0.8.17;






contract Stake is Ownable {
    event Staked (uint256 plotId, uint256 indexed batchNo, uint256 indexed tokenId, uint256 timestamp, string indexed plotType);
    event UnStaked (uint256 plotId, uint256 indexed batchNo, uint256 indexed tokenId, uint256 timestamp, string indexed plotType);

	enum PlotType { STANDARD, PREMIUM, GENESIS }
	struct PlotDetails {
		uint256 maxStake;
		uint256 rewardPrcnt;
		uint256 stakeTreesBonusPrcnt;
		uint256 totalStaked;
	}

	struct StakeInfo {
		string plotType;
		uint256 plotId;
		uint256 timeStaked;
		uint256 timeLastClaim;
	}
	uint8 internal constant MINS_IN_HOUR = 60;
	
	// Treasury wallet
    address public constant FOUNDATION_WALLET = 0x3e41ABe38f68223e43F52688C48EF85D2F10E030;


	// Mapping to convert enum plot values to string
	mapping (uint256 => string) private _enumToString;

	// Mapping stores plot specific details
	mapping (PlotType => PlotDetails) private _plot;

	// Plot => batch no. + token id => Staking struct
	mapping (PlotType => mapping (bytes32 => bool)) private _isStakedOnPlot;

	// Mapping from plottype to plot id to amount of trees staked
	mapping (PlotType => mapping (uint256 => uint256)) private _totalStakedOnPlot;
	mapping (bytes32 => StakeInfo) private _isStaked;
	mapping (bytes32 => uint256) private _unclaimedRewards;

	// Mapping to instances of plots contracts
	mapping (PlotType => IERC721) private _plotContract;
	IAco2 public aco2;
	ITreesFactory public treesFactory;
	bool public isprogramPaused;

	modifier onlyExsistentNftreeBatch(uint256 batchNo) {
		address nftree = address(treesFactory.getNftreeOfBatch(batchNo));
        require (nftree != address(0), string.concat("Batch no. ", Strings.toString(batchNo), " does not exsist"));	
		_;
	}

	constructor (address _aco2, address _treesFactory, address _standard, address _premium, address _genesis) {
		
		// Setting plots ids
		_plot[PlotType.STANDARD] = PlotDetails(15, 80, 20, 0);
		_plot[PlotType.PREMIUM] = PlotDetails(30, 90, 30, 0);
		_plot[PlotType.GENESIS] = PlotDetails(50, 100, 50, 0);
		
		_plotContract[PlotType.STANDARD] = IERC721(_standard);
		_plotContract[PlotType.PREMIUM] = IERC721(_premium);
		_plotContract[PlotType.GENESIS] = IERC721(_genesis);

		// Setting factory and cby instances
		aco2 = IAco2(_aco2);
		treesFactory = ITreesFactory(_treesFactory);

		_enumToString[uint256(PlotType.STANDARD)] = "STANDARD";
        _enumToString[uint256(PlotType.PREMIUM)] = "PREMIUM";
        _enumToString[uint256(PlotType.GENESIS)] = "GENESIS";
	}

    function setTreeFactory(address _treesFactory) external onlyOwner {
        require (_treesFactory != address(0), "Cannot set Tree Factory to 0 address");

        treesFactory = ITreesFactory(_treesFactory);
    }

    function setAco2(address _aco2) external onlyOwner {
        require (_aco2 != address(0), "Cannot set ACO2 to 0 address");

        aco2 = IAco2(_aco2);
    }

	function toggleProgramPause() external onlyOwner {
		isprogramPaused = !isprogramPaused;
	}

	function standardPlotDetails() external view returns (PlotDetails memory) {
		return _plot[PlotType.STANDARD];
	}

	function premiumPlotDetails() external view returns (PlotDetails memory) {
		return _plot[PlotType.PREMIUM];
	}

	function genesisPlotDetails() external view returns (PlotDetails memory) {
		return _plot[PlotType.GENESIS];
	}

	//function setMinStakePrice()

	function totalStakedOnStandard(uint256 plotId) external view returns (uint256) {
		return _totalStakedOnPlot[PlotType.STANDARD][plotId];
	}

	function totalStakedOnPremium(uint256 plotId) external view returns (uint256) {
		return _totalStakedOnPlot[PlotType.PREMIUM][plotId];
	}

	function totalStakedOnGenesis(uint256 plotId) external view returns (uint256) {
		return _totalStakedOnPlot[PlotType.GENESIS][plotId];
	}

	function isTreeStakedOnStandard(uint256 batchNo, uint256 tokenId) external view returns (bool) {
		return _isStakedOnPlot[PlotType.STANDARD][_generateKey(batchNo, tokenId)];
	}

	function isTreeStakedOnPremium(uint256 batchNo, uint256 tokenId) external view returns (bool) {
		return _isStakedOnPlot[PlotType.PREMIUM][_generateKey(batchNo, tokenId)];
	}

	function isTreeStakedOnGenesis(uint256 batchNo, uint256 tokenId) external view returns (bool) {
		return _isStakedOnPlot[PlotType.GENESIS][_generateKey(batchNo, tokenId)];
	}

	function treeStakingInfo(uint256 batchNo, uint256[] memory tokenId) external view returns (StakeInfo[] memory result) {
		uint256 tokenCount = tokenId.length;
		result = new StakeInfo[](tokenCount);
		for (uint256 i = 0; i < tokenCount; i++) {
			result[i] = _isStaked[_generateKey(batchNo, tokenId[i])];
		} 
	}

	function stakeOnStandard(uint256 plotId, uint256 batchNo, uint256[] calldata tokenId) external onlyExsistentNftreeBatch(batchNo) {
		_stake(PlotType.STANDARD, plotId, batchNo, tokenId);
	}

	function stakeOnPremium(uint256 plotId, uint256 batchNo, uint256[] calldata tokenId) external onlyExsistentNftreeBatch(batchNo) {
		_stake(PlotType.PREMIUM, plotId, batchNo, tokenId);
	}

	function stakeOnGenesis(uint256 plotId, uint256 batchNo, uint256[] calldata tokenId) external onlyExsistentNftreeBatch(batchNo) {
		_stake(PlotType.GENESIS, plotId, batchNo, tokenId);
	}

	function unstakeOnStandard(uint256 plotId, uint256 batchNo, uint256[] calldata tokenId) external onlyExsistentNftreeBatch(batchNo) {
		_unstake(PlotType.STANDARD, plotId, batchNo, tokenId);
	}

	function unstakeOnPremium(uint256 plotId, uint256 batchNo, uint256[] calldata tokenId) external onlyExsistentNftreeBatch(batchNo) {
		_unstake(PlotType.PREMIUM, plotId, batchNo, tokenId);
	}

	function unstakeOnGenesis(uint256 plotId, uint256 batchNo, uint256[] calldata tokenId) external onlyExsistentNftreeBatch(batchNo) {
		_unstake(PlotType.GENESIS, plotId, batchNo, tokenId);
	}

    function _enumToStringConverter(PlotType plot) internal view returns (string memory) {
        return _enumToString[uint256(plot)];
    }

	function _generateKey(uint256 batchNo, uint256 tokenId) internal pure returns (bytes32) {
    	return keccak256(abi.encode(batchNo, tokenId));
	}

	function _generateKey(address user, uint256 batchNo) internal pure returns (bytes32) {
    	return keccak256(abi.encode(user, batchNo));
	}

	function _beforeTokenStake(PlotType plot, uint256 plotId, uint256 batchNo, uint256 tokenId) internal view {
		require (_isStaked[_generateKey(batchNo, tokenId)].timeStaked == 0, string.concat("Token Id ", Strings.toString(tokenId), " is already staked on Plot. ", _enumToString[uint256(plot)], " Id. ", Strings.toString(plotId)));

		INftree nftree = treesFactory.getNftreeOfBatch(batchNo);
		address tokenOwner = nftree.ownerOf(tokenId);
		require (tokenOwner == _msgSender() || nftree.isApprovedForAll(tokenOwner, _msgSender()) || _msgSender() == nftree.getApproved(tokenId), string.concat("Caller is not Owner/Approved for Token Id. ", Strings.toString(tokenId)));
		require (nftree.isBlacklisted(tokenId) == 0, "Tree is blacklisted and cannot be staked");
		require (nftree.isUpgraded(tokenId), "Tree not eligible to stake. Please upgrade the tree in order to stake");
	}

	function _stake(PlotType plot, uint256 plotId, uint256 batchNo, uint256[] calldata tokenId) internal {
		require (!isprogramPaused, "Staking program is currently paused by Admin");
		
		uint256 totalTokens = tokenId.length;
        require (totalTokens != 0, "No token Ids provided");

		address plotOwner = _plotContract[plot].ownerOf(plotId);

		// Check if nftrees are less than max limit of staking on plots
		require (_msgSender() == plotOwner, "Caller not the plot Owner");
		require (_totalStakedOnPlot[plot][plotId] + totalTokens <= _plot[plot].maxStake, string.concat("Not enough space available on Plot ", Strings.toString(plotId)));

		_totalStakedOnPlot[plot][plotId] += totalTokens;
		_plot[plot].totalStaked += totalTokens;
		for(uint256 i = 0; i < totalTokens; i++) {
			_beforeTokenStake(plot, plotId, batchNo, tokenId[i]);
			StakeInfo memory st = StakeInfo(_enumToString[uint256(plot)], plotId, block.timestamp, block.timestamp);
			_isStaked[_generateKey(batchNo, tokenId[i])] = st;
			_isStakedOnPlot[plot][_generateKey(batchNo, tokenId[i])] = true;

			emit Staked (plotId, batchNo, tokenId[i], block.timestamp, _enumToStringConverter(plot));
		}
	}

	function _unstake(PlotType plot, uint256 plotId, uint256 batchNo, uint256[] calldata tokenId) internal {
		require (!isprogramPaused, "Staking program is currently paused by Admin");

		uint256 totalTokens = tokenId.length;
        require (totalTokens != 0, "No token Ids provided");

		INftree nftree = treesFactory.getNftreeOfBatch(batchNo);
		for (uint256 i = 0; i < totalTokens; i++) {
			require (_isStakedOnPlot[plot][_generateKey(batchNo, tokenId[i])], string.concat("Token Id. ", Strings.toString(tokenId[i]), "not staked on plot type: ", _enumToStringConverter(plot)));
			
			address tokenOwner = nftree.ownerOf(tokenId[i]);
			require (_msgSender() == tokenOwner || nftree.isApprovedForAll(tokenOwner, _msgSender()) || _msgSender() == nftree.getApproved(tokenId[i]), string.concat("Caller is not Owner/Approved for Token Id. ", Strings.toString(tokenId[i])));
			
			delete _isStaked[_generateKey(batchNo, tokenId[i])];
			delete _isStakedOnPlot[plot][_generateKey(batchNo, tokenId[i])];

			uint256 totalReward;
			uint256 carbifyReward;
			(totalReward, carbifyReward) = _calculateStakeReward(plot, batchNo, tokenId[i]);
			_unclaimedRewards[_generateKey(batchNo, tokenId[i])] = totalReward;

			emit UnStaked(plotId, batchNo, tokenId[i], block.timestamp, _enumToStringConverter(plot));
		}
		_totalStakedOnPlot[plot][plotId] -= totalTokens;
		_plot[plot].totalStaked -= totalTokens;
	}

	function unclaimedReward(uint256 batchNo, uint256[] memory tokenId) external view returns (uint256[] memory) {
		uint256 tokenCount = tokenId.length;
		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			for (uint256 index; index < tokenCount; index++) {
				result[index] = _unclaimedRewards[_generateKey(batchNo, tokenId[index])];
			}
			return result;
		}
	}

	function claimUnclaimedReward(uint256 batchNo, uint256[] memory tokenId) external {
		uint256 totalReward;
		uint256 tokenCount = tokenId.length;
		require (tokenCount != 0, "Token array empty");

		uint256[] memory result = new uint256[](tokenCount);
		for (uint256 i; i < tokenCount; i++) {
			address tokenOwner = treesFactory.getNftreeOfBatch(batchNo).ownerOf(tokenId[i]) ;
			require (tokenOwner == _msgSender(), string.concat("Caller is not the owner of token Id. ", Strings.toString(tokenId[i])));
			result[i] = _unclaimedRewards[_generateKey(batchNo, tokenId[i])];
			totalReward += result[i];
		}
		
		require (totalReward >= aco2.minAco2Claim(), "Claimable rewards are less than minimum claimable amount");
		aco2.mint(_msgSender(), totalReward);
	}

	function stakeRewardStandard(uint256 batchNo, uint256[] memory tokenId) public view returns (uint256 reward) {
		uint256 totalTokens = tokenId.length;
		for (uint256 i = 0; i < totalTokens; i++) {
			require (_isStakedOnPlot[PlotType.STANDARD][_generateKey(batchNo, tokenId[i])], string.concat("Token Id. ", Strings.toString(tokenId[i]), " is not staked on plot type: ", _enumToStringConverter(PlotType.STANDARD)));
			
			uint256 totalReward;
			uint256 carbifyReward;
			(totalReward, carbifyReward) = _calculateStakeReward(PlotType.STANDARD, batchNo, tokenId[i]);
			reward += totalReward;
		}
	}

	function stakeRewardPremium(uint256 batchNo, uint256[] memory tokenId) public view returns (uint256 reward) {
		uint256 totalTokens = tokenId.length;
		for (uint256 i = 0; i < totalTokens; i++) {
			require (_isStakedOnPlot[PlotType.PREMIUM][_generateKey(batchNo, tokenId[i])], string.concat("Token Id. ", Strings.toString(tokenId[i]), " is not staked on plot type: ", _enumToStringConverter(PlotType.PREMIUM)));
			
			uint256 totalReward;
			uint256 carbifyReward;
			(totalReward, carbifyReward) = _calculateStakeReward(PlotType.PREMIUM, batchNo, tokenId[i]);
			reward += totalReward;
		}
	}

	function stakeRewardGenesis(uint256 batchNo, uint256[] memory tokenId) public view returns (uint256 reward) {
		uint256 totalTokens = tokenId.length;
		for (uint256 i = 0; i < totalTokens; i++) {
			require (_isStakedOnPlot[PlotType.GENESIS][_generateKey(batchNo, tokenId[i])], string.concat("Token Id. ", Strings.toString(tokenId[i]), " is not staked on plot type: ", _enumToStringConverter(PlotType.GENESIS)));
			uint256 totalReward;
			uint256 carbifyReward;
			(totalReward, carbifyReward) = _calculateStakeReward(PlotType.GENESIS, batchNo, tokenId[i]);
			reward += totalReward;
		}
	}
	
	function claimStakeRewardStandard(uint256 batchNo, uint256[] memory tokenId) external {
		uint256 totalReward;
		uint256 carbifyReward;
		(totalReward, carbifyReward) =_claimStakeRewardPlot(PlotType.STANDARD, batchNo, tokenId);
		require (totalReward >= aco2.minAco2Claim(), "Claimable rewards are less than minimum claimable amount");

		if (carbifyReward != 0) {
			aco2.mint(FOUNDATION_WALLET, carbifyReward);
		}
		aco2.mint(_msgSender(), totalReward);
	}

	function claimStakeRewardPremium(uint256 batchNo, uint256[] memory tokenId) external {
		uint256 totalReward;
		uint256 carbifyReward;
		(totalReward, carbifyReward) =_claimStakeRewardPlot(PlotType.PREMIUM, batchNo, tokenId);
		require (totalReward >= aco2.minAco2Claim(), "Claimable rewards are less than minimum claimable amount");
		
		if (carbifyReward != 0) {
			aco2.mint(FOUNDATION_WALLET, carbifyReward);
		}
		aco2.mint(_msgSender(), totalReward);
	}

	function claimStakeRewardGenesis(uint256 batchNo, uint256[] memory tokenId) external {
		uint256 totalReward;
		uint256 carbifyReward;
		(totalReward, carbifyReward) =_claimStakeRewardPlot(PlotType.GENESIS, batchNo, tokenId);
		require (totalReward >= aco2.minAco2Claim(), "Claimable rewards are less than minimum claimable amount");
		
		if (carbifyReward != 0) {
			aco2.mint(FOUNDATION_WALLET, carbifyReward);
		}
		aco2.mint(_msgSender(), totalReward);
	}

	function _claimStakeRewardPlot(PlotType plot, uint256 batchNo, uint256[] memory tokenId) internal returns (uint256 totalReward, uint256 remainingReward) {
		uint256 totalTokens = tokenId.length;
		require (totalTokens !=0, "No tokens provided");
		
		for (uint256 i = 0; i < totalTokens; i++) {
			address tokenOwner = treesFactory.getNftreeOfBatch(batchNo).ownerOf(tokenId[i]) ;
			require (tokenOwner == _msgSender(), string.concat("Caller is not the owner of token Id. ", Strings.toString(tokenId[i])));
			require (_isStakedOnPlot[plot][_generateKey(batchNo, tokenId[i])], string.concat("Token Id. ", Strings.toString(tokenId[i]), " is not staked on plot type: ", _enumToStringConverter(plot)));
			
			uint256 treeReward;
			uint256 carbifyReward;
			(treeReward, carbifyReward) = _calculateStakeReward(plot, batchNo, tokenId[i]);
			totalReward += treeReward;
			remainingReward += carbifyReward;
			_isStaked[_generateKey(batchNo, tokenId[i])].timeLastClaim = block.timestamp;
		}
	}

	function _calculateStakeReward(PlotType plot, uint256 batchNo, uint256 tokenId) internal view returns (uint256 treeReward, uint256 remainingReward) {
		uint256 timeLastClaim = _isStaked[_generateKey(batchNo, tokenId)].timeLastClaim;
		treeReward = (block.timestamp - timeLastClaim) * aco2.treeRewardPerMin() * _plot[plot].rewardPrcnt / MINS_IN_HOUR / 100;
		remainingReward = ((block.timestamp - timeLastClaim) * aco2.treeRewardPerMin() * 100 / MINS_IN_HOUR / 100) - treeReward;
		
		return (treeReward, remainingReward);
	}

	function totalUnstakedNftrees() public view returns (uint256 amount) {
		uint256 totalStaked;
		totalStaked += _plot[PlotType.STANDARD].totalStaked;
		totalStaked += _plot[PlotType.PREMIUM].totalStaked;
		totalStaked += _plot[PlotType.GENESIS].totalStaked;
		amount = treesFactory.totalNftrees() - totalStaked;
	}
	
	// function _calculateUnstakedTreeRewards(PlotType plot, uint256 batchNo, uint256 tokenId) internal view returns (uint256 treeReward, uint256 remainingReward) {
	// 	uint256 timeLastClaim = _isStaked[_generateKey(batchNo, tokenId)].timeLastClaim;
	// 	uint256 unstakedTrees = totalUnstakedNftrees();

	// 	treeReward = (block.timestamp - timeLastClaim) * aco2.treeRewardPerMin() * unstakedTrees * _plot[plot].stakeTreesBonusPrcnt / MINS_IN_HOUR / 100;
	// 	uint256 perTreeReward = treeReward / _plot[plot].totalStaked;
	// 	return perTreeReward;
	// }

	// function unstakedBonusOnGenesis(uint256 timeLastClaim) public view returns (uint256 rewardPerTree) {
	// 	uint256 unstakedTrees = totalUnstakedNftrees();
	// 	uint256 totalReward = (block.timestamp - timeLastClaim) * aco2.treeRewardPerMin() * unstakedTrees * _plot[PlotType.GENESIS].stakeTreesBonusPrcnt / MINS_IN_HOUR / 100;
	// 	rewardPerTree = totalReward / _plot[PlotType.GENESIS].totalStaked;
	// }

	// function unstakedBonusOnPremium(uint256 timeLastClaim) public view returns (uint256 rewardPerTree) {
	// 	uint256 genesisReward = unstakedBonusOnGenesis(timeLastClaim);
	// 	uint256 unstakedTrees = totalUnstakedNftrees();
	// 	uint256 totalReward = (block.timestamp - timeLastClaim) * aco2.treeRewardPerMin() * unstakedTrees * _plot[PlotType.PREMIUM].stakeTreesBonusPrcnt / MINS_IN_HOUR / 100;
	// 	rewardPerTree = totalReward / _plot[PlotType.GENESIS].totalStaked;
	// }
}