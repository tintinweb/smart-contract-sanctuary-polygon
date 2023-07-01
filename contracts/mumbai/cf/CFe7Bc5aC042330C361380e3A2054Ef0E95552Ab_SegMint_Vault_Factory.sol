/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

////////////////////////////////
////    Import libraries    ////
////////////////////////////////

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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
    function sqrt(uint256 a, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = sqrt(a);
            return
                result +
                (rounding == Rounding.Up && result * result < a ? 1 : 0);
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
    function log2(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log2(value);
            return
                result +
                (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
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
    function log10(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
    function log256(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

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
        return
            string(
                abi.encodePacked(
                    value < 0 ? "-" : "",
                    toString(SignedMath.abs(value))
                )
            );
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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
    function equal(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

interface ISegMintVault {

    function approveStaker(
        address stakerAddress,
        address contractAddress,
        uint256 tokenId
    ) external;

    function renounceApprovedStaker(
        address contractAddress,
        uint256 tokenId
    ) external;

    function approveFractioner(address approveFractionerAddress, address contractAddress, uint256 tokenId) external;
    function renounceApprovedFractioner(address contractAddress, uint256 tokenId) external returns (bool);
    function importNFTs(address contractAddress, uint256 tokenId) external;
    function withdrawNFTs(address contractAddress, uint256 tokenId) external;
    function withdrawERC20(address ERC20ContractAddress, uint256 amount) external;
    function withdrawERC721(address ERC721ContractAddress, uint256 tokenId) external;
    function withdrawERC1155(address ERC1155ContractAddress, uint256 tokenId, uint256 amount) external;
    function stakerLock(address contractAddress, uint256 tokenId, uint256 endDate) external;
    function stakerUnlock(address contractAddress, uint256 tokenId) external;
    function stakerUnlockAndTransfer(address contractAddress, uint256 tokenId) external;
    function fractionerLock(address contractAddress, uint256 tokenId) external returns(bool);
    function fractionerUnlock(address contractAddress, uint256 tokenId) external returns(bool);
    function fractionerUnlockAndTransfer(address contractAddress, uint256 tokenId, address _transferToAddress) external returns(bool);

    function getOwnerWalletAddress() external view returns (address);
    function getSegMintNFTVaultAddress() external view returns (address);
    function isImported(address contractAddress, uint256 tokenId) external view returns (bool);
    function isStaked(address contractAddress, uint256 tokenId) external view returns (bool);
    function getStakerAddress(address contractAddress, uint256 tokenId) external view returns (address);
    function getApprovedStaker(address contractAddress, uint256 tokenId) external view returns (address);
    function getStakingStartDate(address contractAddress, uint256 tokenId) external view returns (uint256);
    function getStakingEndDate(address contractAddress, uint256 tokenId) external view returns (uint256);
    function isFractioned(address contractAddress, uint256 tokenId) external view returns (bool);
    function getFractionerAddress(address contractAddress, uint256 tokenId) external view returns (address);
    function getApprovedFractioner(address contractAddress, uint256 tokenId) external view returns (address);
    function getFractionedDate(address contractAddress, uint256 tokenId) external view returns (uint256);

}

///////////////////////////////////////////////////////////
////    SegMintNFTVault: Single contract per user    ////
///////////////////////////////////////////////////////////

contract SegMintNFTVault is ERC721Holder, ERC1155Holder, ISegMintVault {
    //////////////////////
    ////    Fields    ////
    //////////////////////

    // owner of NFT wallet address
    address _ownerWalletAddress;

    // staking info
    struct STAKINGINFO {
        // address of staker
        address stakerAddress;
        // staking start date
        uint256 stakingStartDate;
        // stakind end date
        uint256 stakingEndDate;
    }

    // fractioning info
    struct FRACTIONINGINFO {
        // address of fractioner
        address fractionerAddress;
        // fractioned date
        uint256 fractionedDate;
    }

    // NFTs Imported: contractAddress => TokenID => timestamp 0(not imported) / <> 0 (imported)
    mapping(address => mapping(uint256 => uint256)) private _importedNFTs;

    // Mapping from contractAddress => TokenID => Staking Info
    mapping(address => mapping(uint256 => STAKINGINFO)) private _stakers;

    // Mapping contractAddress =>  TokenID => approved Stakers address
    mapping(address => mapping(uint256 => address)) private _stakersApprovals;

    // Mapping from contractAddress => TokenID => Fractioning Info
    mapping(address => mapping(uint256 => FRACTIONINGINFO))
        private _fractioners;

    // Mapping from contractAddress => TokenID => approved Fractioner address
    mapping(address => mapping(uint256 => address))
        private _fractionersApprovals;

    ///////////////////////////
    ////    Constructor    ////
    ///////////////////////////

    constructor(address owner) {
        _ownerWalletAddress = owner;
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // Import NFT event
    event ImportNFTsEvent(
        address indexed sender,
        address SegMintNFTVault,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 indexed timestamp
    );

    // Withraw Imported NFT
    event WithrawImportedNFT(
        address indexed sender,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 indexed timestamp
    );

    // approve staking events
    event ApproveStakerEvent(
        address indexed sender,
        address approvedStakerAddress,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 indexed timestamp
    );

    // renouncing approved staker
    event RenounceStakerEvent(
        address indexed sender,
        address approvedStakerAddress,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 indexed timestamp
    );

    // start staking event
    event StartStakingEvent(
        address indexed sender,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 indexed timestamp
    );

    // end staking event
    event EndStakingEvent(
        address indexed sender,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 indexed timestamp
    );

    // end staking and transfer NFT event
    event EndStakingAndTransferNFTEvent(
        address indexed sender,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 indexed timestamp
    );

    // approve fractioner events
    event ApproveFractionerEvent(
        address indexed sender,
        address approvedFractionerAddress,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 indexed timestamp
    );

    // renouncing approved fractioner
    event RenounceFractionerEvent(
        address indexed sender,
        address approvedFractionerAddress,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 indexed timestamp
    );

    // fractioner lock NFT event
    event FractionerLockEvent(
        address indexed sender,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 indexed timestamp
    );

    // fractioner unlock event
    event FractionerUnlockEvent(
        address indexed sender,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 indexed timestamp
    );

    // fractioner unlock and transfer NFT event
    event FractionerUnlockAndTransferNFTEvent(
        address indexed sender,
        address to,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 indexed timestamp
    );

    // withdraw ERC20 event
    event WithdrawERC20Event(
        address indexed sender,
        address indexed ERC20ContractAddress,
        uint256 amount,
        uint256 indexed timestamp
    );

    // withdraw ERC721 event
    event WithdrawERC721Event(
        address indexed sender,
        address indexed ERC721ContractAddress,
        uint256 tokenId,
        uint256 indexed timestamp
    );

    // withdraw ERC1155 event
    event WithdrawERC1155Event(
        address indexed sender,
        address indexed ERC1155ContractAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only owner address
    modifier onlyOwner() {
        require(
            msg.sender == _ownerWalletAddress,
            "Sender is not owner address!"
        );
        _;
    }

    // only staker address
    modifier onlyStaker(address contractAddress, uint256 tokenId) {
        require(
            msg.sender == _stakerOf(contractAddress, tokenId),
            "Sender is not staker address!"
        );
        _;
    }

    // only fractioner address
    modifier onlyFractioner(address contractAddress, uint256 tokenId) {
        require(
            msg.sender == _fractionerOf(contractAddress, tokenId),
            "Sender is not fractioner address!"
        );
        _;
    }

    // only approved staker address
    modifier onlyApprovedStaker(address contractAddress, uint256 tokenId) {
        require(
            msg.sender == _stakersApprovals[contractAddress][tokenId],
            "Sender is not approved staker address!"
        );
        _;
    }

    // only approved fractioner address
    modifier onlyApprovedFractioner(address contractAddress, uint256 tokenId) {
        require(
            msg.sender == _fractionersApprovals[contractAddress][tokenId],
            "Sender is not approved fractioner address!"
        );
        _;
    }

    // only imported NFT
    modifier onlyImportedNFT(address contractAddress, uint256 tokenId) {
        require(
            isImported(contractAddress, tokenId),
            string.concat(
                "NFT with contract address : ",
                Strings.toHexString(contractAddress),
                " and token ID : ",
                Strings.toString(tokenId),
                " is not imported!"
            )
        );
        _;
    }

    // only not null address
    modifier notNullAddress(address account, string memory roleName) {
        require(
            account != address(0),
            string.concat(roleName, " should not be zero address!")
        );
        _;
    }

    // not locked NFT
    modifier notLockedNFT(address contractAddress, uint256 tokenId) {
        // require not staked
        require(
            _stakerOf(contractAddress, tokenId) == address(0),
            "NFT is locked! Status : Staked!"
        );

        // require not fractioned
        require(
            _fractionerOf(contractAddress, tokenId) == address(0),
            "NFT is locked! Status : Fractioned!"
        );
        _;
    }

    ////////////////////////////////
    ////    Public Functions    ////
    ////////////////////////////////

    ////    Staking Specific TokenID   ////

    // approve an address as the staker
    function approveStaker(
        address stakerAddress,
        address contractAddress,
        uint256 tokenId
    )
        public
        onlyOwner
        onlyImportedNFT(contractAddress, tokenId)
        notNullAddress(stakerAddress, "Staker address")
        notLockedNFT(contractAddress, tokenId)
    {
        // sender should not be the stakerAddress (do not approve owner)
        require(
            msg.sender != stakerAddress,
            "ERC721: staker approval to owner, approved, or operator"
        );

        // address of current approved staker should be address(0)
        require(
            address(_stakersApprovals[contractAddress][tokenId]) == address(0),
            "Cannot overwrite the current approved staker for this NFT!"
        );

        // require address of current approved fractioner be address(0)
        require(
            _fractionersApprovals[contractAddress][tokenId] == address(0),
            "There is a non-zero address approved for fractioning!"
        );

        // update approved staker address
        _approveStaker(msg.sender, stakerAddress, contractAddress, tokenId);
    }

    // cancel the approved staker
    function renounceApprovedStaker(address contractAddress, uint256 tokenId)
        public
        onlyOwner
        onlyImportedNFT(contractAddress, tokenId)
        notLockedNFT(contractAddress, tokenId)
    {
        // require approved staker not be address(0)
        require(
            _stakersApprovals[contractAddress][tokenId] != address(0),
            "No address is approved for staking!"
        );

        // update approved staker address to address(0) ==> cancel approved staker
        _renounceStaker(
            msg.sender,
            _stakersApprovals[contractAddress][tokenId],
            contractAddress,
            tokenId
        );
    }

    ////    Fractioner Vault Specific TokenID   ////

    // approve an address as fractioner
    function approveFractioner(
        address approveFractionerAddress,
        address contractAddress,
        uint256 tokenId
    )
        public
        onlyOwner
        onlyImportedNFT(contractAddress, tokenId)
        notNullAddress(approveFractionerAddress, "Fractioner address")
        notLockedNFT(contractAddress, tokenId)
    {
        // approveFractionerAddress should not be the current owner
        require(
            msg.sender != approveFractionerAddress,
            "ERC721: fractioner approval to owner wallet address!"
        );

        // require currentApprovedStaker not be securedly approved
        require(
            _stakersApprovals[contractAddress][tokenId] == address(0),
            "TokenId is already approved for a staker!"
        );

        // require approveFractionerAddress not be approved
        require(
            _fractionersApprovals[contractAddress][tokenId] == address(0),
            "TokenId is already approved for a fractioner"
        );

        // update approved fractioner address
        _approveFractioner(
            msg.sender,
            approveFractionerAddress,
            contractAddress,
            tokenId
        );
    }

    // cancel the approed fractioner
    function renounceApprovedFractioner(
        address contractAddress,
        uint256 tokenId
    )
        public
        onlyOwner
        onlyImportedNFT(contractAddress, tokenId)
        notLockedNFT(contractAddress, tokenId)
        returns (bool)
    {
        // require approved fractioner not be address(0)
        require(
            _fractionersApprovals[contractAddress][tokenId] != address(0),
            "No address is approved for fractioning!"
        );

        // update approved fractioner address
        _renounceFractioner(
            msg.sender,
            _fractionersApprovals[contractAddress][tokenId],
            contractAddress,
            tokenId
        );

        // return
        return true;
    }

    ////    Import and Withdraw NFT    ////

    // import NFT by NFT owner wallet address
    function importNFTs(address contractAddress, uint256 tokenId)
        public
        onlyOwner
    {
        // check if the owner of the tokenId is the sender
        require(
            IERC721(contractAddress).ownerOf(tokenId) == msg.sender,
            "Sender is not the owner of the NFT!"
        );

        // check if SegMintNFTVault contract is approved
        require(
            address(this) == IERC721(contractAddress).getApproved(tokenId),
            "SegMintNFTVault is not approved!"
        );

        // safeTransferFrom NFT to SegMintNFTVault contract
        IERC721(contractAddress).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            ""
        );

        // add NFT to the importedNFTs
        _importedNFTs[contractAddress][tokenId] = block.timestamp;

        // emit Event for safe Transfer
        emit ImportNFTsEvent(
            msg.sender,
            address(this),
            contractAddress,
            tokenId,
            block.timestamp
        );
    }

    // withdraw imported NFT
    function withdrawNFTs(address contractAddress, uint256 tokenId)
        public
        onlyOwner
        onlyImportedNFT(contractAddress, tokenId)
        notLockedNFT(contractAddress, tokenId)
    {
        // transfer NFT
        IERC721(contractAddress).safeTransferFrom(
            address(this),
            _ownerWalletAddress,
            tokenId,
            ""
        );

        // delete NFT from importedNFTs
        _importedNFTs[contractAddress][tokenId] = 0;

        // update approved staker
        _stakersApprovals[contractAddress][tokenId] = address(0);

        // update approved staker / fractioner
        _fractionersApprovals[contractAddress][tokenId] = address(0);

        // emit event
        emit WithrawImportedNFT(
            msg.sender,
            contractAddress,
            tokenId,
            block.timestamp
        );
    }

    ////    Airdrops/Rewars Withdawal    ////

    // withdarw ERC20
    function withdrawERC20(address ERC20ContractAddress, uint256 amount)
        public
        onlyOwner
    {
        // require amount > 0
        require(amount > 0, "amount should be greater than zero!");

        // require having enough balance
        require(
            IERC20(ERC20ContractAddress).balanceOf(address(this)) >= amount,
            "Entered amount is more than the balance!"
        );

        // transfer amount to NFT owner
        IERC20(ERC20ContractAddress).transferFrom(
            address(this),
            _ownerWalletAddress,
            amount
        );

        // emit event
        emit WithdrawERC20Event(
            msg.sender,
            ERC20ContractAddress,
            amount,
            block.timestamp
        );
    }

    // withdraw ERC721 (except the ones imported)
    function withdrawERC721(address ERC721ContractAddress, uint256 tokenId)
        public
        onlyOwner
    {
        // require holding that NFT tokenId
        require(
            IERC721(ERC721ContractAddress).ownerOf(tokenId) == address(this),
            "NFT is not held in your SegMintNFTVault contract!"
        );

        // require this NFT is either Airdrops or Rewards NOT the imported NFTs
        require(
            _importedNFTs[ERC721ContractAddress][tokenId] == 0,
            "This NFT is not Airdrop nor Reward, this is an imported NFT by owner!"
        );

        // transfer NFT
        IERC721(ERC721ContractAddress).safeTransferFrom(
            address(this),
            _ownerWalletAddress,
            tokenId,
            ""
        );

        // emit event
        emit WithdrawERC721Event(
            msg.sender,
            ERC721ContractAddress,
            tokenId,
            block.timestamp
        );
    }

    // withdraw ERC1155
    function withdrawERC1155(
        address ERC1155ContractAddress,
        uint256 tokenId,
        uint256 amount
    ) public onlyOwner {
        // require amount > 0
        require(amount > 0, "amount should be greater than zero!");

        // require having enough balance
        require(
            IERC1155(ERC1155ContractAddress).balanceOf(
                address(this),
                tokenId
            ) >= amount,
            "Entered amount is more thant the balance!"
        );

        // transfer amount to NFT owner
        IERC1155(ERC1155ContractAddress).safeTransferFrom(
            address(this),
            _ownerWalletAddress,
            tokenId,
            amount,
            ""
        );

        // emit event
        emit WithdrawERC1155Event(
            msg.sender,
            ERC1155ContractAddress,
            tokenId,
            amount,
            block.timestamp
        );
    }

    ////    Staking tokenId   ////

    // staker wallet locks an NFT
    function stakerLock(
        address contractAddress,
        uint256 tokenId,
        uint256 endDate
    )
        public
        onlyApprovedStaker(contractAddress, tokenId)
        onlyImportedNFT(contractAddress, tokenId)
        notLockedNFT(contractAddress, tokenId)
    {
        // update _stakers
        _stakers[contractAddress][tokenId].stakerAddress = msg.sender;
        _stakers[contractAddress][tokenId].stakingStartDate = block.timestamp;
        _stakers[contractAddress][tokenId].stakingEndDate = uint256(endDate);

        // update approvedStaker to address(0)
        _stakersApprovals[contractAddress][tokenId] = address(0);

        // emit event
        emit StartStakingEvent(
            msg.sender,
            contractAddress,
            tokenId,
            block.timestamp
        );
    }

    // unlocking an NFT (NFT stays in the locking contract)
    function stakerUnlock(address contractAddress, uint256 tokenId)
        public
        onlyImportedNFT(contractAddress, tokenId)
    {
        // require NFT be staked
        require(isStaked(contractAddress, tokenId), "NFT is not staked!");

        // before end date only staker can unstake and
        // afeter end date owner/approved/operator can unstake
        if (
            _stakers[contractAddress][tokenId].stakingEndDate <= block.timestamp
        ) {
            // require sender be the owner
            require(
                msg.sender == _ownerWalletAddress ||
                    msg.sender == _stakerOf(contractAddress, tokenId),
                "Sender is not the owner or staker!"
            );
        } else {
            // require sender be the staker for the tokenId
            require(
                msg.sender == _stakerOf(contractAddress, tokenId),
                "Sender is not the staker!"
            );
        }

        // update staking info ==> Unstake or remove staker
        _stakers[contractAddress][tokenId].stakerAddress = address(0);
        _stakers[contractAddress][tokenId].stakingStartDate = 0;
        _stakers[contractAddress][tokenId].stakingEndDate = 0;

        // emit event
        emit EndStakingEvent(
            msg.sender,
            contractAddress,
            tokenId,
            block.timestamp
        );
    }

    // unlocking an NFT and transfering it to the NFT owner wallet
    function stakerUnlockAndTransfer(address contractAddress, uint256 tokenId)
        public
        onlyImportedNFT(contractAddress, tokenId)
    {
        // require NFT be staked
        require(isStaked(contractAddress, tokenId), "NFT is not staked!");

        // before end date only staker can unstake and
        // after end date owner/approved/operator can unstake
        if (
            _stakers[contractAddress][tokenId].stakingEndDate <= block.timestamp
        ) {
            // require sender be the owner
            require(
                msg.sender == _ownerWalletAddress ||
                    msg.sender == _stakerOf(contractAddress, tokenId),
                "Sender is not the owner or staker!"
            );
        } else {
            // require sender be the staker for the tokenId
            require(
                msg.sender == _stakerOf(contractAddress, tokenId),
                "Sender is not the staker!"
            );
        }

        // transfer tokenId to owner wallet address
        IERC721(contractAddress).safeTransferFrom(
            address(this),
            _ownerWalletAddress,
            tokenId
        );

        // update staking info ==> Unstake or remove staker
        _stakers[contractAddress][tokenId].stakerAddress = address(0);
        _stakers[contractAddress][tokenId].stakingStartDate = 0;
        _stakers[contractAddress][tokenId].stakingEndDate = 0;

        // emit event
        emit EndStakingAndTransferNFTEvent(
            msg.sender,
            contractAddress,
            tokenId,
            block.timestamp
        );
    }

    ////    fractioner Lock/Unlock tokenId     ////

    // to be called by exchange and only owner
    function fractionerLock(address contractAddress, uint256 tokenId)
        public
        onlyApprovedFractioner(contractAddress, tokenId)
        onlyImportedNFT(contractAddress, tokenId)
        notLockedNFT(contractAddress, tokenId)
        returns(bool)
    {
        // update _fractioner
        _fractioners[contractAddress][tokenId].fractionerAddress = msg.sender;
        _fractioners[contractAddress][tokenId].fractionedDate = block.timestamp;

        // update approvedFractioner to address(0)
        _fractionersApprovals[contractAddress][tokenId] = address(0);

        // emit event
        emit FractionerLockEvent(
            msg.sender,
            contractAddress,
            tokenId,
            block.timestamp
        );

        // return
        return true;
    }

    // unlocking an NFT (NFT stays in the locking contract)
    function fractionerUnlock(address contractAddress, uint256 tokenId)
        public
        onlyFractioner(contractAddress, tokenId)
        onlyImportedNFT(contractAddress, tokenId)
        returns(bool)
    {
        // require NFT be fractioned
        require(
            isFractioned(contractAddress, tokenId),
            "NFT is not fractioned!"
        );

        // update fractioner
        _fractioners[contractAddress][tokenId].fractionerAddress = address(0);
        _fractioners[contractAddress][tokenId].fractionedDate = 0;

        // emit event
        emit FractionerUnlockEvent(
            msg.sender,
            contractAddress,
            tokenId,
            block.timestamp
        );

        // return
        return true;
    }

    // unlocking an NFT and transfering it to an address (claiming NFT)
    function fractionerUnlockAndTransfer(
        address contractAddress,
        uint256 tokenId,
        address _transferToAddress
    )
        public
        onlyFractioner(contractAddress, tokenId)
        onlyImportedNFT(contractAddress, tokenId)
        returns(bool)
    {
        // require NFT be fractioned
        require(
            isFractioned(contractAddress, tokenId),
            "NFT is not fractioned!"
        );

        // transfer tokenId to an address
        IERC721(contractAddress).safeTransferFrom(
            address(this),
            _transferToAddress,
            tokenId
        );

        // delete NFT from importedNFTs
        _importedNFTs[contractAddress][tokenId] = 0;

        // update fractioner
        _fractioners[contractAddress][tokenId].fractionerAddress = address(0);
        _fractioners[contractAddress][tokenId].fractionedDate = 0;

        // emit event
        emit FractionerUnlockAndTransferNFTEvent(
            msg.sender,
            _transferToAddress,
            contractAddress,
            tokenId,
            block.timestamp
        );

        // return
        return true;
    }

    ////    Getters    ////

    // get owner Wallet Address
    function getOwnerWalletAddress() public view returns (address) {
        return _ownerWalletAddress;
    }

    // get SegMint Vault contract address
    function getSegMintNFTVaultAddress() public view returns (address) {
        return address(this);
    }

    //  isImported NFT
    function isImported(address contractAddress, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return _importedNFTs[contractAddress][tokenId] > 0;
    }

    // isStaked NFT
    function isStaked(address contractAddress, uint256 tokenId)
        public
        view
        onlyImportedNFT(contractAddress, tokenId)
        returns (bool)
    {
        // return _importedNFTs[contractAddress][tokenId].isStaked;
        return _stakerOf(contractAddress, tokenId) != address(0);
    }

    // get staker address
    function getStakerAddress(address contractAddress, uint256 tokenId)
        public
        view
        virtual
        onlyImportedNFT(contractAddress, tokenId)
        returns (address)
    {
        // return staker
        return _stakerOf(contractAddress, tokenId);
    }

    // get approved staker address
    function getApprovedStaker(address contractAddress, uint256 tokenId)
        public
        view
        virtual
        onlyImportedNFT(contractAddress, tokenId)
        returns (address)
    {
        // return approved staker
        return _stakersApprovals[contractAddress][tokenId];
    }

    // get staked NFT start date
    function getStakingStartDate(address contractAddress, uint256 tokenId)
        public
        view
        onlyImportedNFT(contractAddress, tokenId)
        returns (uint256)
    {
        // return _importedNFTs[contractAddress][tokenId].stakingInfo.stakingStartDate;
        return _stakers[contractAddress][tokenId].stakingStartDate;
    }

    // get staked NFT end date
    function getStakingEndDate(address contractAddress, uint256 tokenId)
        public
        view
        onlyImportedNFT(contractAddress, tokenId)
        returns (uint256)
    {
        // return staking end date
        return _stakers[contractAddress][tokenId].stakingEndDate;
    }

    // isFractioned NFT
    function isFractioned(address contractAddress, uint256 tokenId)
        public
        view
        onlyImportedNFT(contractAddress, tokenId)
        returns (bool)
    {
        // return
        return _fractionerOf(contractAddress, tokenId) != address(0);
    }

    // get fractioner address
    function getFractionerAddress(address contractAddress, uint256 tokenId)
        public
        view
        virtual
        onlyImportedNFT(contractAddress, tokenId)
        returns (address)
    {
        // return locker
        return _fractionerOf(contractAddress, tokenId);
    }

    // get approved fractioner address
    function getApprovedFractioner(address contractAddress, uint256 tokenId)
        public
        view
        virtual
        onlyImportedNFT(contractAddress, tokenId)
        returns (address)
    {
        // return approved fractioner
        return _fractionersApprovals[contractAddress][tokenId];
    }

    // get fractioned date
    function getFractionedDate(address contractAddress, uint256 tokenId)
        public
        view
        onlyImportedNFT(contractAddress, tokenId)
        returns (uint256)
    {
        // return fractioned date
        return _fractioners[contractAddress][tokenId].fractionedDate;
    }

    /////////////////////////////////
    ////    Private Functions    ////
    /////////////////////////////////

    // _stakerOf
    function _stakerOf(address contractAddress, uint256 tokenId)
        internal
        view
        virtual
        returns (address)
    {
        return _stakers[contractAddress][tokenId].stakerAddress;
    }

    // approve staker
    function _approveStaker(
        address sender,
        address approveStakerAddress,
        address contractAddress,
        uint256 tokenId
    ) internal virtual {
        // update approved staker
        _stakersApprovals[contractAddress][tokenId] = approveStakerAddress;

        // emit
        emit ApproveStakerEvent(
            sender,
            approveStakerAddress,
            contractAddress,
            tokenId,
            block.timestamp
        );
    }

    // renounce staker
    function _renounceStaker(
        address sender,
        address approvedStakerAddress,
        address contractAddress,
        uint256 tokenId
    ) internal virtual {
        // update approved staker to zero address
        _stakersApprovals[contractAddress][tokenId] = address(0);

        // emit
        emit RenounceStakerEvent(
            sender,
            approvedStakerAddress,
            contractAddress,
            tokenId,
            block.timestamp
        );
    }

    // _fractionerOf
    function _fractionerOf(address contractAddress, uint256 tokenId)
        internal
        view
        virtual
        returns (address)
    {
        return _fractioners[contractAddress][tokenId].fractionerAddress;
    }

    // approve fractioner
    function _approveFractioner(
        address sender,
        address approveFractionerAddress,
        address contractAddress,
        uint256 tokenId
    ) internal virtual {
        // update approved fractioner
        _fractionersApprovals[contractAddress][
            tokenId
        ] = approveFractionerAddress;

        // emit
        emit ApproveFractionerEvent(
            sender,
            approveFractionerAddress,
            contractAddress,
            tokenId,
            block.timestamp
        );
    }

    // renounce fractioner
    function _renounceFractioner(
        address sender,
        address approvedFractionerAddress,
        address contractAddress,
        uint256 tokenId
    ) internal virtual {
        // update approved fractioner to zero address
        _fractionersApprovals[contractAddress][tokenId] = address(0);

        // emit
        emit RenounceFractionerEvent(
            sender,
            approvedFractionerAddress,
            contractAddress,
            tokenId,
            block.timestamp
        );
    }
}


contract SegMint_Vault_Factory {


    ////////////////////
    ////   Fields   ////
    ////////////////////

    // SegMint Factory Owner Address
    address private _owner;

    // Mapping to store the addresses of deployed SegMint Vault contracts
    mapping(address => address) private deployedSegmintVault;

    mapping(address => bool) private _isSegMintERC721;

    // Event to log the deployment of a SegMint Vault contract
    event SegMintVaultDeployed(address deployer, address deployed);


    ////////////////////
    ////   Events   ////
    ////////////////////

    // update Owner address 
    event updateOwnerAddressEvent(
        address indexed previousOwner,
        address indexed newOwnerAddress,
        uint256 indexed timestamp
    );
    /////////////////////////
    ////   Constructor   ////
    /////////////////////////

    // constructor
    constructor(){
        _owner = msg.sender;
    }


    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // Modifier to check that the caller is the owner wallet address.
    modifier onlyOwner() {
        require(msg.sender == _owner, "SegMint ERC721 Factory: Sender is not owner!");
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    /**
     * get the owner address
     */
    
    function getOwnerAddress() public view returns(address){
        return _owner;
    }

    /*
     * Function to update the owner address
     * @param ownerAddress_ the address of the new owner
     */
    
    function updateOwnerAddress(address ownerAddress_) public onlyOwner {

        // require new address not be zero address
        require(ownerAddress_ != address(0), "SegMint ERC721 Factory: new owner address cannot be zero address!");

        // udpate owner address
        _owner = ownerAddress_;

        // emit event
        emit updateOwnerAddressEvent(
            msg.sender,
            ownerAddress_,
            block.timestamp
        );
    }

    /**
     * Function to deploy a SegMint Vault contract
     */
    function deploySegMintVault() public {
        // Ensure that the deployer hasn't already deployed a SegMint Vault contract
        require(deployedSegmintVault[msg.sender] == address(0), "Already deployed");

        // Deploy the SegMint Vault contract and store its address
        address deployedAddress = address(new SegMintNFTVault(msg.sender));
        deployedSegmintVault[msg.sender] = deployedAddress;

        // Log the deployment of the SegMint Vault contract
        emit SegMintVaultDeployed(msg.sender, deployedAddress);
    }

    /**
     * Function to get the address of a deployed SegMint Vault contract
     *
     * @param deployer the address of the deployer
     * @return the address of the deployed SegMint Vault contract
     */
    function getSegMintVaultDeployedAddress(address deployer) public view returns (address) {
        return deployedSegmintVault[deployer];
    }
    
    /**
    * @dev Returns a boolean indicating whether the specified contract address is registered as a Segmint NFT ERC721 contract.
    * @param contractAddress The address of the contract to check.
    * @return A boolean value indicating whether the specified contract address is registered as a Segmint NFT ERC721 contract.
    */

    function isSegmintERC721(address contractAddress) public view returns(bool) {
        return _isSegMintERC721[contractAddress];
    }
}