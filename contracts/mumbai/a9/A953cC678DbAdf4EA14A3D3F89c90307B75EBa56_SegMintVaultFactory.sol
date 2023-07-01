/**
 *Submitted for verification at polygonscan.com on 2023-07-01
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-22
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-19
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

// SegMint NFT Vault Interface
interface SegMintNFTVaultInterface {

    // Batch Import Strcut
    struct BatchNFTsStruct {
        uint256[] tokenIds;
        address contractAddress;
    }

    // import NFT by NFT owner wallet address
    function importNFTs(address contractAddress_, uint256 tokenID_) external;

    // batch import NFTs
    function batchImportNFTs(BatchNFTsStruct[] memory importData_) external;

    // withdraw imported NFT
    function withdrawNFTs(address contractAddress_, uint256 tokenID_) external;

    // batch withdraw imported NFTs
    function batchWithdrawNFTs(BatchNFTsStruct[] memory withdrawData_) external;

    // withdarw ERC20
    function withdrawERC20(address ERC20ContractAddress_, uint256 amount_) external;

    // withdraw ERC721 (except the ones imported)
    function withdrawERC721(address ERC721ContractAddress_, uint256 tokenID_) external;

    // withdraw ERC1155
    function withdrawERC1155(
        address ERC1155ContractAddress_,
        uint256 tokenID_,
        uint256 amount_
    ) external;

    // approve an address as segminter
    function approveSegMinter(
        address approveSegMinterAddress_,
        address contractAddress_,
        uint256 tokenID_
    ) external;

    // cancel the approved segminter
    function renounceApprovedSegMinter(
        address contractAddress_,
        uint256 tokenID_
    ) external returns (bool);

    // segminter locks NFT
    function SegMinterLock(address contractAddress_, uint256 tokenID_) external returns (bool);

    // segminter unlock the locked NFT (reclaiming)
    function SegMinterUnlock(address contractAddress_, uint256 tokenID_) external returns (bool);

    // segminter unlock and transfer the locked NFT (reclaiming)
    function SegMinterUnlockAndTransfer(
        address contractAddress_,
        uint256 tokenID_,
        address transferToAddress_
    ) external returns (bool);

    // approve locker address
    function approveLocker(
        BatchNFTsStruct[] memory data_,
        address approvedLockerAddress_
    ) external;

    // batch Lock NFTs by approved locker
    function batchLockNFTs(BatchNFTsStruct[] memory lockData_) external;

    // batch unlock NFT by locker
    function batchUnlockNFTs(BatchNFTsStruct[] memory lockData_) external;

    // get owner Wallet Address
    function getOwnerWalletAddress() external view returns (address);

    // get SegMint Vault contract address
    function getSegMintNFTVaultAddress() external view returns (address);

    //  isImported NFT
    function isImported(address contractAddress_, uint256 tokenID_)
        external
        view
        returns (bool);

    // get approved segminter address
    function getApprovedSegMinter(address contractAddress_, uint256 tokenID_)
        external
        view
        returns (address);

    // isSegMinterLocked NFT
    function isSegMinterLocked(address contractAddress_, uint256 tokenID_)
        external
        view
        returns (bool);

    // get segminter address
    function getSegMinterAddress(address contractAddress_, uint256 tokenID_)
        external
        view
        returns (address);

    // get segminter Locking date
    function getSegMinterLockingDate(address contractAddress_, uint256 tokenID_)
        external
        view
        returns (uint256);

    // get approved locker address
    function getApprovedLocker(address contractAddress_, uint256 tokenID_)
        external
        view
        returns (address);

    // isLocked NFT
    function isLocked(address contractAddress_, uint256 tokenID_)
        external
        view
        returns (bool);

    // get locker address
    function getLockerAddress(address contractAddress_, uint256 tokenID_)
        external
        view
        returns (address);

    // get locker Locking date
    function getLockerLockingDate(address contractAddress_, uint256 tokenID_)
        external
        view
        returns (uint256);
}

// SegMint NFT Vault
contract SegMintNFTVault is
    ERC721Holder,
    ERC1155Holder,
    SegMintNFTVaultInterface
{
    //////////////////////
    ////    Fields    ////
    //////////////////////

    // owner of NFT wallet address
    address _owner;

    // NFTs Imported: contractAddress => TokenID => timestamp 0(not imported) / <> 0 (imported)
    mapping(address => mapping(uint256 => uint256)) private _importedNFTs;

    ////    SEGMINTING    ////

    // segminting info
    struct SEGMINTINGINFO {
        // address of segminter
        address SegMinterAddress;
        // segminted timestamp
        uint256 SegMinterLockingTimestamp;
    }

    // Mapping from contractAddress => TokenID => segminting Info
    mapping(address => mapping(uint256 => SEGMINTINGINFO)) private _SegMinters;

    // Mapping from contractAddress => TokenID => approved segminters address
    mapping(address => mapping(uint256 => address))
        private _SegMintersApprovals;

    ////    LOCKING (NOT SEGMINTING)   ////

    // locking info
    struct LOCKINGINFO {
        // address of locker
        address lockerAddress;
        // locked timestamp
        uint256 lockedTimestamp;
    }

    // Mapping from contractAddress => TokenID => Locking Info
    mapping(address => mapping(uint256 => LOCKINGINFO)) private _lockers;

    // Mapping from contractAddress => TokenID => approved lockers address
    mapping(address => mapping(uint256 => address)) private _lockersApproval;

    ///////////////////////////
    ////    Constructor    ////
    ///////////////////////////

    // constructor
    constructor(address owner_) {
        // set owner address
        _owner = owner_;
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // Import NFT event
    event ImportNFTsEvent(
        address indexed owner,
        address SegMintNFTVault,
        address indexed contractAddress,
        uint256 tokenID,
        uint256 indexed timestamp
    );

    // Withraw Imported NFT
    event WithrawImportedNFT(
        address indexed owner,
        address indexed contractAddress,
        uint256 tokenID,
        uint256 indexed timestamp
    );

    // withdraw ERC20 event
    event WithdrawERC20Event(
        address indexed owner,
        address indexed ERC20ContractAddress,
        uint256 amount,
        uint256 indexed timestamp
    );

    // withdraw ERC721 event
    event WithdrawERC721Event(
        address indexed owner,
        address indexed ERC721ContractAddress,
        uint256 tokenID,
        uint256 indexed timestamp
    );

    // withdraw ERC1155 event
    event WithdrawERC1155Event(
        address indexed owner,
        address indexed ERC1155ContractAddress,
        uint256 tokenID,
        uint256 amount,
        uint256 indexed timestamp
    );

    // approve segminter events
    event ApproveSegMinterEvent(
        address indexed owner,
        address approvedSegMinterAddress,
        address indexed contractAddress,
        uint256 tokenId,
        uint256 indexed timestamp
    );

    // renouncing approved segminter
    event RenounceSegMinterEvent(
        address indexed owner,
        address approvedSegMinterAddress,
        address indexed contractAddress,
        uint256 tokenID,
        uint256 indexed timestamp
    );

    // segminter lock NFT event
    event SegMinterLockEvent(
        address indexed segminter,
        address indexed contractAddress,
        uint256 tokenID,
        uint256 indexed timestamp
    );

    // segminter unlock event
    event SegMinterUnlockEvent(
        address indexed segminter,
        address indexed contractAddress,
        uint256 tokenID,
        uint256 indexed timestamp
    );

    // segminter unlock and transfer NFT event
    event SegMinterUnlockAndTransferNFTEvent(
        address indexed segminter,
        address toAddress,
        address indexed contractAddress,
        uint256 tokenID,
        uint256 indexed timestamp
    );

    // approve locker
    event ApprovedLockerEvent(
        address indexed owner,
        address approvedLockerAddress,
        address indexed contractAddress,
        uint256 tokenID,
        uint256 indexed timestamp
    );

        // approve locker
    event RenounceLockerEvent(
        address indexed owner,
        address indexed contractAddress,
        uint256 tokenID,
        uint256 indexed timestamp
    );

    // batch lock NFT event
    event BatchLockEvent(
        address indexed locker,
        BatchNFTsStruct[] lockData,
        uint256 indexed timestamp
    );

    event BatchUnlockEvent(
        address indexed sender,
        BatchNFTsStruct[] lockData,
        uint256 indexed timestamp
    );
    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only owner address
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    // only segminter address
    modifier onlySegMinter(address contractAddress_, uint256 tokenID_) {
        _onlySegMinter(contractAddress_, tokenID_);
        _;
    }

    // only approved segminter address
    modifier onlyApprovedSegMinter(address contractAddress_, uint256 tokenID_) {
        _onlyApprovedSegMinter(contractAddress_, tokenID_);
        _;
    }

    // only imported NFT
    modifier onlyImportedNFT(address contractAddress_, uint256 tokenID_) {
        _onlyImportedNFT(contractAddress_, tokenID_);
        _;
    }

    // only not null address
    modifier notNullAddress(address account_, string memory roleName_) {
        _notNullAddress(account_, roleName_);
        _;
    }

    // not locked NFT
    modifier notLockedNFT(address contractAddress_, uint256 tokenID_) {
        // require not locked
        _notLockedNFT(contractAddress_, tokenID_);
        _;
    }

    ////////////////////////////////
    ////    Public Functions    ////
    ////////////////////////////////

    ////    Import and Withdraw NFT    ////

    // import NFT by NFT owner wallet address
    function importNFTs(address contractAddress_, uint256 tokenID_)
        public
        onlyOwner
    {
        // check if the owner of the token ID is the sender
        require(
            IERC721(contractAddress_).ownerOf(tokenID_) == msg.sender,
            "SegMint Vault: Sender is not the owner of the NFT!"
        );

        // check if SegMint Vault contract is approved
        require(
            address(this) == IERC721(contractAddress_).getApproved(tokenID_),
            "SegMint Vault: SegMint Vault is not approved!"
        );

        // safeTransferFrom NFT to SegMintNFTVault contract
        IERC721(contractAddress_).safeTransferFrom(
            msg.sender,
            address(this),
            tokenID_,
            ""
        );

        // add NFT to the importedNFTs
        _importedNFTs[contractAddress_][tokenID_] = block.timestamp;

        // emit Event for safe Transfer
        emit ImportNFTsEvent(
            msg.sender,
            address(this),
            contractAddress_,
            tokenID_,
            block.timestamp
        );
    }

    // batch import NFTs
    function batchImportNFTs(BatchNFTsStruct[] memory importData_)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < importData_.length; i++) {
            // contract address for this batch
            address contractAddress = importData_[i].contractAddress;
            // token Ids for this batch
            uint256[] memory tokenIds = importData_[i].tokenIds;


            // check if SegMintNFTVault contract is approved
            require(
                    IERC721(contractAddress).isApprovedForAll(msg.sender, address(this)) == true,
                    "SegMint Vault: SegMint Vault is not approved!"
                );

            for (uint256 j = 0; j < tokenIds.length; j++) {
                // tokenId
                uint256 tokenId = tokenIds[j];
                // check if the owner of the tokenId is the sender
                require(
                    IERC721(contractAddress).ownerOf(tokenId) == msg.sender,
                    "SegMint Vault: Sender is not the owner of the NFT!"
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
        }
    }

    // withdraw imported NFT
    function withdrawNFTs(address contractAddress_, uint256 tokenID_)
        public
        onlyOwner
        onlyImportedNFT(contractAddress_, tokenID_)
        notLockedNFT(contractAddress_, tokenID_)
    {
        // transfer NFT
        IERC721(contractAddress_).safeTransferFrom(
            address(this),
            _owner,
            tokenID_,
            ""
        );

        // delete NFT from importedNFTs
        _importedNFTs[contractAddress_][tokenID_] = 0;

        // update approved staker / segminter
        _SegMintersApprovals[contractAddress_][tokenID_] = address(0);

        // emit event
        emit WithrawImportedNFT(
            msg.sender,
            contractAddress_,
            tokenID_,
            block.timestamp
        );
    }

    // batch withdraw imported NFTs
    function batchWithdrawNFTs(BatchNFTsStruct[] memory withdrawData_)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < withdrawData_.length; i++) {
            // contract address for this batch
            address contractAddress = withdrawData_[i].contractAddress;
            // token Ids for this batch
            uint256[] memory tokenIds = withdrawData_[i].tokenIds;

            for (uint256 j = 0; j < tokenIds.length; j++) {
                // tokenId
                uint256 tokenId = tokenIds[j];

                // require NFT be imported
                _onlyImportedNFT(contractAddress, tokenId);

                // require NFT not been locked
                _notLockedNFT(contractAddress, tokenId);

                // transfer NFT
                IERC721(contractAddress).safeTransferFrom(
                    address(this),
                    _owner,
                    tokenId,
                    ""
                );

                // delete NFT from importedNFTs
                _importedNFTs[contractAddress][tokenId] = 0;

                // update approved segminter
                _SegMintersApprovals[contractAddress][tokenId] = address(0);

                // emit event
                emit WithrawImportedNFT(
                    msg.sender,
                    contractAddress,
                    tokenId,
                    block.timestamp
                );
            }
        }
    }

    ////    Airdrops/Rewars Withdawal    ////

    // withdarw ERC20
    function withdrawERC20(address ERC20ContractAddress_, uint256 amount_)
        public
        onlyOwner
    {
        // require amount > 0
        require(
            amount_ > 0,
            "SegMint Vault: amount should be greater than zero!"
        );

        // require having enough balance
        require(
            IERC20(ERC20ContractAddress_).balanceOf(address(this)) >= amount_,
            "SegMint Vault: Entered amount is more than the balance!"
        );

        // transfer amount to NFT owner
        IERC20(ERC20ContractAddress_).transferFrom(
            address(this),
            _owner,
            amount_
        );

        // emit event
        emit WithdrawERC20Event(
            msg.sender,
            ERC20ContractAddress_,
            amount_,
            block.timestamp
        );
    }

    // withdraw ERC721 (except the ones imported)
    function withdrawERC721(address ERC721ContractAddress_, uint256 tokenID_)
        public
        onlyOwner
    {
        // require holding that NFT token ID
        require(
            IERC721(ERC721ContractAddress_).ownerOf(tokenID_) == address(this),
            "SegMint Vault: NFT is not held in your SegMint Vault contract!"
        );

        // require this NFT be either Airdrops or Rewards NOT the imported NFTs
        require(
            _importedNFTs[ERC721ContractAddress_][tokenID_] == 0,
            "SegMint Vault: This NFT is not Airdrop nor Reward, this is an imported NFT by owner!"
        );

        // transfer NFT
        IERC721(ERC721ContractAddress_).safeTransferFrom(
            address(this),
            _owner,
            tokenID_,
            ""
        );

        // emit event
        emit WithdrawERC721Event(
            msg.sender,
            ERC721ContractAddress_,
            tokenID_,
            block.timestamp
        );
    }

    // withdraw ERC1155
    function withdrawERC1155(
        address ERC1155ContractAddress_,
        uint256 tokenID_,
        uint256 amount_
    ) public onlyOwner {
        // require amount > 0
        require(
            amount_ > 0,
            "SegMint Vault: amount should be greater than zero!"
        );

        // require having enough balance
        require(
            IERC1155(ERC1155ContractAddress_).balanceOf(
                address(this),
                tokenID_
            ) >= amount_,
            "SegMint Vault: Entered amount is more thant the balance!"
        );

        // transfer amount to NFT owner
        IERC1155(ERC1155ContractAddress_).safeTransferFrom(
            address(this),
            _owner,
            tokenID_,
            amount_,
            ""
        );

        // emit event
        emit WithdrawERC1155Event(
            msg.sender,
            ERC1155ContractAddress_,
            tokenID_,
            amount_,
            block.timestamp
        );
    }

    ////    SEGMINTER    ////

    // approve an address as segminter
    function approveSegMinter(
        address approveSegMinterAddress_,
        address contractAddress_,
        uint256 tokenID_
    )
        public
        onlyOwner
        onlyImportedNFT(contractAddress_, tokenID_)
        notNullAddress(approveSegMinterAddress_, "SegMinter address")
        notLockedNFT(contractAddress_, tokenID_)
    {
        // approveSegMinterAddress_ should not be the current owner
        require(
            msg.sender != approveSegMinterAddress_,
            "SegMint Vault: segminter approval to owner wallet address!"
        );

        // require approveSegMinterAddress_ not be approved
        require(
            _SegMintersApprovals[contractAddress_][tokenID_] == address(0),
            "SegMint Vault: TokenId is already approved for a segminting!"
        );

        // update approved segminter address
        _approveSegMinter(
            msg.sender,
            approveSegMinterAddress_,
            contractAddress_,
            tokenID_
        );
    }

    // cancel the approved segminter
    function renounceApprovedSegMinter(
        address contractAddress_,
        uint256 tokenID_
    )
        public
        onlyOwner
        onlyImportedNFT(contractAddress_, tokenID_)
        notLockedNFT(contractAddress_, tokenID_)
        returns (bool)
    {
        // require approved segminter not be address(0)
        require(
            _SegMintersApprovals[contractAddress_][tokenID_] != address(0),
            "SegMint Vault: No address is approved for segminting!"
        );

        // update approved segminter address
        _renounceSegMinter(
            msg.sender,
            _SegMintersApprovals[contractAddress_][tokenID_],
            contractAddress_,
            tokenID_
        );

        // return
        return true;
    }

    // segminter locks NFT
    function SegMinterLock(address contractAddress_, uint256 tokenID_)
        public
        onlyApprovedSegMinter(contractAddress_, tokenID_)
        onlyImportedNFT(contractAddress_, tokenID_)
        notLockedNFT(contractAddress_, tokenID_)
        returns (bool)
    {
        // update segminter address
        _SegMinters[contractAddress_][tokenID_].SegMinterAddress = msg.sender;

        // update segminted timestamp
        _SegMinters[contractAddress_][tokenID_]
            .SegMinterLockingTimestamp = block.timestamp;

        // update approved segminter to address(0)
        _SegMintersApprovals[contractAddress_][tokenID_] = address(0);

        // emit event
        emit SegMinterLockEvent(
            msg.sender,
            contractAddress_,
            tokenID_,
            block.timestamp
        );

        // return
        return true;
    }

    // segminter unlock the locked NFT (reclaiming)
    function SegMinterUnlock(address contractAddress_, uint256 tokenID_)
        public
        onlySegMinter(contractAddress_, tokenID_)
        onlyImportedNFT(contractAddress_, tokenID_)
        returns (bool)
    {
        // require NFT be locked segminter
        require(
            isSegMinterLocked(contractAddress_, tokenID_),
            "SegMint Vault: NFT not locked by segminter!"
        );

        // update segminter address
        _SegMinters[contractAddress_][tokenID_].SegMinterAddress = address(0);

        // update segminted timestamp
        _SegMinters[contractAddress_][tokenID_].SegMinterLockingTimestamp = 0;

        // emit event
        emit SegMinterUnlockEvent(
            msg.sender,
            contractAddress_,
            tokenID_,
            block.timestamp
        );

        // return
        return true;
    }

    // segminter unlock and transfer the locked NFT (reclaiming)
    function SegMinterUnlockAndTransfer(
        address contractAddress_,
        uint256 tokenID_,
        address transferToAddress_
    )
        public
        onlySegMinter(contractAddress_, tokenID_)
        onlyImportedNFT(contractAddress_, tokenID_)
        returns (bool)
    {
        // require NFT be segminted
        require(
            isSegMinterLocked(contractAddress_, tokenID_),
            "SegMint Vault: NFT is not locked by segminter!"
        );

        // transfer token ID to an address
        IERC721(contractAddress_).safeTransferFrom(
            address(this),
            transferToAddress_,
            tokenID_
        );

        // delete NFT from importedNFTs
        _importedNFTs[contractAddress_][tokenID_] = 0;

        // update segminter address
        _SegMinters[contractAddress_][tokenID_].SegMinterAddress = address(0);

        // update segminted timestamp
        _SegMinters[contractAddress_][tokenID_].SegMinterLockingTimestamp = 0;

        // emit event
        emit SegMinterUnlockAndTransferNFTEvent(
            msg.sender,
            transferToAddress_,
            contractAddress_,
            tokenID_,
            block.timestamp
        );

        // return
        return true;
    }

    ////   BATCH LOCKING   ////

    // approve locker address
    function approveLocker(
        BatchNFTsStruct[] memory data_,
        address approvedLockerAddress_
    )
        public
        onlyOwner
        notNullAddress(approvedLockerAddress_, "Locker address")
    {
        for (uint256 i = 0; i < data_.length; i++) {
            // contract address for this batch
            address contractAddress = data_[i].contractAddress;
            // token Ids for this batch
            uint256[] memory tokenIds = data_[i].tokenIds;

            for (uint256 j = 0; j < tokenIds.length; j++) {
                // tokenId
                uint256 tokenId = tokenIds[j];

                // approve locker address
                _approveLocker(
                    approvedLockerAddress_,
                    contractAddress,
                    tokenId
                );
            }
        }
    }

    function renounceLocker(BatchNFTsStruct[] memory data_)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < data_.length; i++) {
            // contract address for this batch
            address contractAddress = data_[i].contractAddress;
            // token Ids for this batch
            uint256[] memory tokenIds = data_[i].tokenIds;

            for (uint256 j = 0; j < tokenIds.length; j++) {
                // tokenId
                uint256 tokenId = tokenIds[j];

                // approve locker address
                _renounceLocker(
                    contractAddress,
                    tokenId
                );
            }
        }
    }

    // batch Lock NFTs by approved locker
    function batchLockNFTs(BatchNFTsStruct[] memory lockData_) public {
        for (uint256 i = 0; i < lockData_.length; i++) {
            // contract adress
            address contractAddress = lockData_[i].contractAddress;

            for (uint256 j = 0; j < lockData_[i].tokenIds.length; j++) {
                // token ID
                uint256 tokenId = lockData_[i].tokenIds[j];

                // require sender be the approved locker
                require(
                    _lockersApproval[contractAddress][tokenId] == msg.sender,
                    "SegMint Vault: Sender is not the approved locker!"
                );

                // update locker
                _lockers[contractAddress][tokenId].lockerAddress = msg.sender;

                // update locked timestamp
                _lockers[contractAddress][tokenId].lockedTimestamp = block
                    .timestamp;

                // update lockerApproval to address(0)
                _lockersApproval[contractAddress][tokenId] = address(0);
            }
        }

        // emit event
        emit BatchLockEvent(msg.sender, lockData_, block.timestamp);
    }

    // batch unlock NFT by locker
    function batchUnlockNFTs(BatchNFTsStruct[] memory lockData_) public {
        for (uint256 i = 0; i < lockData_.length; i++) {
            // contract address
            address contractAddress = lockData_[i].contractAddress;

            for (uint256 j = 0; j < lockData_[i].tokenIds.length; j++) {
                // token ID
                uint256 tokenId = lockData_[i].tokenIds[j];

                // require sender be the locker address
                require(
                    _lockers[contractAddress][tokenId].lockerAddress ==
                        msg.sender,
                    "SegMint Vault: Sender is not the locker!"
                );

                // update locker
                _lockers[contractAddress][tokenId].lockerAddress = address(0);

                // update locked timestamp
                _lockers[contractAddress][tokenId].lockedTimestamp = 0;
            }

            // emit event
            emit BatchUnlockEvent(msg.sender, lockData_, block.timestamp);
        }
    }

    ////    Getters    ////

    // get owner Wallet Address
    function getOwnerWalletAddress() public view returns (address) {
        return _owner;
    }

    // get SegMint Vault contract address
    function getSegMintNFTVaultAddress() public view returns (address) {
        return address(this);
    }

    //  isImported NFT
    function isImported(address contractAddress_, uint256 tokenID_)
        public
        view
        returns (bool)
    {
        return _importedNFTs[contractAddress_][tokenID_] > 0;
    }

    // get approved segminter address
    function getApprovedSegMinter(address contractAddress_, uint256 tokenID_)
        public
        view
        virtual
        onlyImportedNFT(contractAddress_, tokenID_)
        returns (address)
    {
        // return approved segminter
        return _SegMintersApprovals[contractAddress_][tokenID_];
    }

    // isSegMinterLocked NFT
    function isSegMinterLocked(address contractAddress_, uint256 tokenID_)
        public
        view
        onlyImportedNFT(contractAddress_, tokenID_)
        returns (bool)
    {
        // return
        return _SegMinterLockerOf(contractAddress_, tokenID_) != address(0);
    }

    // get segminter address
    function getSegMinterAddress(address contractAddress_, uint256 tokenID_)
        public
        view
        virtual
        onlyImportedNFT(contractAddress_, tokenID_)
        returns (address)
    {
        // return locker
        return _SegMinterLockerOf(contractAddress_, tokenID_);
    }

    // get segminter Locking date
    function getSegMinterLockingDate(address contractAddress_, uint256 tokenID_)
        public
        view
        onlyImportedNFT(contractAddress_, tokenID_)
        returns (uint256)
    {
        // return segminter locking date
        return
            _SegMinters[contractAddress_][tokenID_].SegMinterLockingTimestamp;
    }

    // get approved locker address
    function getApprovedLocker(address contractAddress_, uint256 tokenID_)
        public
        view
        virtual
        onlyImportedNFT(contractAddress_, tokenID_)
        returns (address)
    {
        // return approved locker
        return _lockersApproval[contractAddress_][tokenID_];
    }

    // isLocked NFT
    function isLocked(address contractAddress_, uint256 tokenID_)
        public
        view
        onlyImportedNFT(contractAddress_, tokenID_)
        returns (bool)
    {
        // return
        return _lockerOf(contractAddress_, tokenID_) != address(0);
    }

    // get locker address
    function getLockerAddress(address contractAddress_, uint256 tokenID_)
        public
        view
        virtual
        onlyImportedNFT(contractAddress_, tokenID_)
        returns (address)
    {
        // return locker
        return _lockerOf(contractAddress_, tokenID_);
    }

    // get locker Locking date
    function getLockerLockingDate(address contractAddress_, uint256 tokenID_)
        public
        view
        onlyImportedNFT(contractAddress_, tokenID_)
        returns (uint256)
    {
        // return segminter locking date
        return _lockers[contractAddress_][tokenID_].lockedTimestamp;
    }

    //////////////////////////////////
    ////    Internal Functions    ////
    //////////////////////////////////

    // only owner address
    function _onlyOwner() internal view virtual {
        require(
            msg.sender == _owner,
            "SegMint Vault: Sender is not owner address!"
        );
    }

    // only segminter address
    function _onlySegMinter(address contractAddress_, uint256 tokenID_)
        internal
        view
        virtual
    {
        require(
            msg.sender == _SegMinterLockerOf(contractAddress_, tokenID_),
            "SegMint Vault: Sender is not segminter address!"
        );
    }

    // only approved segminter address
    function _onlyApprovedSegMinter(address contractAddress_, uint256 tokenID_)
        internal
        view
        virtual
    {
        require(
            msg.sender == _SegMintersApprovals[contractAddress_][tokenID_],
            "SegMint Vault: Sender is not approved segminter address!"
        );
    }

    // only imported NFT
    function _onlyImportedNFT(address contractAddress_, uint256 tokenID_)
        internal
        view
        virtual
    {
        require(
            isImported(contractAddress_, tokenID_),
            string.concat(
                "SegMint Vault: NFT with contract address : ",
                Strings.toHexString(contractAddress_),
                " and token ID : ",
                Strings.toString(tokenID_),
                " is not imported!"
            )
        );
    }

    // only not null address
    function _notNullAddress(address account_, string memory roleName_)
        internal
        view
        virtual
    {
        require(
            account_ != address(0),
            string.concat(
                "SegMint Vault: ",
                roleName_,
                " should not be zero address!"
            )
        );
    }

    // not locked NFT
    function _notLockedNFT(address contractAddress_, uint256 tokenID_)
        internal
        view
        virtual
    {
        // require not locked by segminter
        require(
            _SegMinterLockerOf(contractAddress_, tokenID_) == address(0),
            "SegMint Vault: NFT is locked by segminter!"
        );
        // require not locked
        require(
            _lockerOf(contractAddress_, tokenID_) == address(0),
            "SegMint Vault: NFT is locked by locker!"
        );
    }

    // approve segminter
    function _approveSegMinter(
        address sender_,
        address approveSegMinterAddress_,
        address contractAddress_,
        uint256 tokenID_
    ) internal virtual {
        // update approved segminter
        _SegMintersApprovals[contractAddress_][
            tokenID_
        ] = approveSegMinterAddress_;

        // emit
        emit ApproveSegMinterEvent(
            sender_,
            approveSegMinterAddress_,
            contractAddress_,
            tokenID_,
            block.timestamp
        );
    }

    // approve locker address (not segminting)
    function _approveLocker(
        address approvedLockerAddress_,
        address contractAddress_,
        uint256 tokenID_
    )
        internal
        onlyImportedNFT(contractAddress_, tokenID_)
        notLockedNFT(contractAddress_, tokenID_)
    {
        // update approved locker address
        _lockersApproval[contractAddress_][tokenID_] = approvedLockerAddress_;

        // emit event
        emit ApprovedLockerEvent(
            msg.sender,
            approvedLockerAddress_,
            contractAddress_,
            tokenID_,
            block.timestamp
        );
    }

    function _renounceLocker(
        address contractAddress_,
        uint256 tokenID_
    )
        internal
        onlyImportedNFT(contractAddress_, tokenID_)
        notLockedNFT(contractAddress_, tokenID_)
    {
        // update approved locker address
        _lockersApproval[contractAddress_][tokenID_] = address(0);

        // emit event
        emit RenounceLockerEvent(
            msg.sender,
            contractAddress_,
            tokenID_,
            block.timestamp
        );
    }

    // segminter locker of
    function _SegMinterLockerOf(address contractAddress_, uint256 tokenID_)
        internal
        view
        virtual
        returns (address)
    {
        return _SegMinters[contractAddress_][tokenID_].SegMinterAddress;
    }

    // _locker of
    function _lockerOf(address contractAddress_, uint256 tokenID_)
        internal
        view
        virtual
        returns (address)
    {
        return _lockers[contractAddress_][tokenID_].lockerAddress;
    }

    // renounce segminter
    function _renounceSegMinter(
        address sender_,
        address approvedSegMinterAddress_,
        address contractAddress_,
        uint256 tokenID_
    ) internal virtual {
        // update approved segminter to zero address
        _SegMintersApprovals[contractAddress_][tokenID_] = address(0);

        // emit
        emit RenounceSegMinterEvent(
            sender_,
            approvedSegMinterAddress_,
            contractAddress_,
            tokenID_,
            block.timestamp
        );
    }
}

// SegMint KYC Interface
interface SegMintKYCInterface {
    // get global authorization status
    function getGlobalAuthorizationStatus() external view returns (bool);
    // is authorized address?
    function isAuthorizedAddress(address account_) external view returns (bool);
    // get geo location
    function getUserLocation(address account_) external view returns (string memory);
}

// SegMint Vault Factory
contract SegMintVaultFactory {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    ////////////////////
    ////   Fields   ////
    ////////////////////

    // SegMint Vault Factory Owner Address
    address private _owner;

    // Mapping to store the addresses of deployed SegMint Vault contracts
    mapping(address => address[]) private _deployedSegMintVaultByDeployer;

    // list of All deployed SegMint Vaults
    address[] private _deployedSegMintVaultList;

    // is SegMint Vault
    mapping(address => bool) private _isSegMintVault;

    // list of all restricted SegMint Vault addresses
    address[] private _restrictedDeployedSegMintVaultList;

    // is restricted status check
    mapping(address => bool) private _isRestrictedSegMintVault;

    // kyc contract address
    address private _SegMintKYCContractAddress;

    // SegMint KYC Interface
    SegMintKYCInterface private _SegMintKYC;

    /////////////////////////
    ////   Constructor   ////
    /////////////////////////

    // constructor
    constructor() {
        _owner = msg.sender;
    }

    ////////////////////
    ////   Events   ////
    ////////////////////

    // update Owner address
    event updateOwnerAddressEvent(
        address indexed previousOwner,
        address indexed newOwnerAddress,
        uint256 indexed timestamp
    );

    // update SegMint KYC Contract Address
    event setSegMintKYCAddressEvent(
        address indexed Owner,
        address previousKYCContractAddress,
        address indexed newSegMintKYCContractAddress,
        uint256 indexed timestamp
    );

    // Event to log the deployment of a SegMint Vault contract
    event SegMintVaultDeployed(
        address indexed deployer,
        address indexed deployed,
        uint256 indexed timestamp
    );

    // restrict SegMint Vault Address
    event restrictSegMintVaultAddressEvent(
        address indexed ownerAddress,
        address indexed SegMintERC721Address,
        uint256 indexed timestamp
    );

    // adding SegMint Vault address
    event AddSegMintVaultAddressEvent(
        address indexed ownerAddress,
        address indexed SegMintVaultAddress,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // Modifier to check that the caller is the owner wallet address.
    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "SegMint Vault Factory: Sender is not owner!"
        );
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_, string memory accountName_) {
        // require account not be the zero address
        require(
            account_ != address(0),
            string.concat(
                "SegMint Vault Factory: ",
                accountName_,
                " cannot be the zero address!"
            )
        );
        _;
    }

    // only KYC Authorized Accounts
    modifier onlyKYCAuthorized() {
        // require sender be authorized
        require(
            _SegMintKYC.isAuthorizedAddress(msg.sender) || _SegMintKYC.getGlobalAuthorizationStatus(),
            "SegMint Vault Factory: Sender is not an authorized account!"
        );
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    /**
     * get the owner address
     */

    function getOwnerAddress() public view returns (address) {
        return _owner;
    }

    /*
     * Function to update the owner address
     * @param ownerAddress_ the address of the new owner
     */

    function updateOwnerAddress(address ownerAddress_)
        public
        onlyOwner
        notNullAddress(ownerAddress_, "New Owner")
    {
        // udpate owner address
        _owner = ownerAddress_;

        // emit event
        emit updateOwnerAddressEvent(
            msg.sender,
            ownerAddress_,
            block.timestamp
        );
    }

    // update SegMint KYC address
    function setSegMintKYCAddress(address SegMintKYCContractAddress_)
        public
        onlyOwner
        notNullAddress(SegMintKYCContractAddress_, "SegMint KYC Address")
    {
        // previous address
        address previousKYCContractAddress = _SegMintKYCContractAddress;

        // update address
        _SegMintKYCContractAddress = SegMintKYCContractAddress_;

        // update interface
        _SegMintKYC = SegMintKYCInterface(SegMintKYCContractAddress_);

        // emit event
        emit setSegMintKYCAddressEvent(
            msg.sender,
            previousKYCContractAddress,
            SegMintKYCContractAddress_,
            block.timestamp
        );
    }

    /**
     * Function to deploy a SegMint Vault contract
     */
    function deploySegMintVault() external onlyKYCAuthorized {
        // Deploy the SegMint Vault contract and store its address
        address deployedAddress = address(new SegMintNFTVault(msg.sender));

        // add deployed contract to list of SegMint Vault deployed by an Deployer
        _deployedSegMintVaultByDeployer[msg.sender].push(deployedAddress);

        // udpate is SegMint Vault
        _isSegMintVault[deployedAddress] = true;

        // add deployed contract to all deployed SegMint Vault list
        _deployedSegMintVaultList.push(deployedAddress);

        // Log the deployment of the SegMint Vault contract
        emit SegMintVaultDeployed(msg.sender, deployedAddress, block.timestamp);
    }

    /*
     * Function to restrict a SegMint Vault Contract Address
     * @params SegMintVaultAddress the address of contract to be restricted
     */

    function restrictSegMintVaultAddress(address SegMintVaultAddress_)
        public
        onlyOwner
    {
        // require address be a SegMint Vault
        require(
            _isSegMintVault[SegMintVaultAddress_] && (!_isRestrictedSegMintVault[SegMintVaultAddress_]),
            "SegMint Vault Factory: Address is not a SegMint Vault Contract or already restricted!"
        );

        // add to restricted SegMint Vault
        _restrictedDeployedSegMintVaultList.push(SegMintVaultAddress_);

        // update is restricted
        _isRestrictedSegMintVault[SegMintVaultAddress_] = true;

        // emit event
        emit restrictSegMintVaultAddressEvent(
            msg.sender,
            SegMintVaultAddress_,
            block.timestamp
        );
    }

    /*
     * Function to manually add or unrestrict an address to SegMint Vault List
     * @params SegMintVaultAddress the address of contract to be added
     */
    function AddOrUnrestrictSegMintVaultAddress(address SegMintVaultAddress_)
        public
        onlyOwner
    {
        // require address not be in the SegMint Vault list
        require(
            !_isSegMintVault[SegMintVaultAddress_],
            "SegMint Vault Factory: Address is already in SegMint"
        );


        // add to all deployed SegMint Vault if not restricted
        if(_isRestrictedSegMintVault[SegMintVaultAddress_]) {
            
            // remove from restricted list and update is restricted status to false
            _removeAddressFromRestrictedSegMintVault(SegMintVaultAddress_);

        } else {
            
            // add contract address to all deployed SegMint Vault list
            _deployedSegMintVaultList.push(SegMintVaultAddress_);

        }

        // udpate is SegMint Vault
        _isSegMintVault[SegMintVaultAddress_] = true;

        // emit event
        emit AddSegMintVaultAddressEvent(
            msg.sender,
            SegMintVaultAddress_,
            block.timestamp
        );
    }

    /**
     * Function to get the address of a deployed SegMint Vault contract
     *
     * @param deployer - the address of the deployer
     * @return the addresses of the deployed SegMint Vault contract
     */

    function getSegMintVaultDeployedAddressByDeployer(address deployer)
        public
        view
        returns (address[] memory)
    {
        return _deployedSegMintVaultByDeployer[deployer];
    }

    /**
     * Function to get the address of a deployed SegMint Vault contract
     *
     * @return the address of the deployed SegMint Vault contract
     */
    function getSegMintVaultDeployedAddress()
        public
        view
        returns (address[] memory)
    {
        return _deployedSegMintVaultList;
    }

    /**
     * @dev Returns a boolean indicating whether the specified contract address is registered as a Segmint Vault contract.
     * @param contractAddress_ The address of the contract to check.
     * @return A boolean value indicating whether the specified contract address is registered as a Segmint Vault contract.
     */

    function isSegMintVault(address contractAddress_)
        public
        view
        returns (bool)
    {
        return _isSegMintVault[contractAddress_];
    }

    /**
     * Function to get the address of a Restricted SegMint Vault contract
     *
     * @return the address of the restricted SegMint Vault contract
     */
    function getRestrictedSegMintVaultDeployedAddress()
        public
        view
        returns (address[] memory)
    {
        return _restrictedDeployedSegMintVaultList;
    }

    /**
     * Function to check if an addresss is a restricted SegMint ERC721 contract
     *
     * @dev Returns a boolean indicating whether the specified contract address is registered as a restricted Segmint NFT ERC721 contract.
     * @param contractAddress_ The address of the contract to check.
     * @return A boolean value indicating whether the specified contract address is registered as a Segmint NFT ERC721 contract.
     */

    function isRestrictedSegMintVault(address contractAddress_)
        public
        view
        returns (bool)
    {
        return _isRestrictedSegMintVault[contractAddress_];
    }

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////

    /*
     * Internal Function to remove Address from restricted SegMint Vault List
     * @params SegMintVaultAddress_ the contract address to be removed
     */

    function _removeAddressFromRestrictedSegMintVault(address SegMintVaultAddress_)
        private
    {
        if (_isRestrictedSegMintVault[SegMintVaultAddress_]) {
            for (uint256 i = 0; i < _restrictedDeployedSegMintVaultList.length; i++) {
                if (_restrictedDeployedSegMintVaultList[i] == SegMintVaultAddress_) {
                    _restrictedDeployedSegMintVaultList[i] = _restrictedDeployedSegMintVaultList[
                        _restrictedDeployedSegMintVaultList.length - 1
                    ];
                    _restrictedDeployedSegMintVaultList.pop();
                    // update status
                    _isRestrictedSegMintVault[SegMintVaultAddress_] = false;
                    break;
                }
            }
        }
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////
}