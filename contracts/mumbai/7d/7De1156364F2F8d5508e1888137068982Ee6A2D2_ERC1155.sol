/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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
        address sender,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external payable;
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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

// SegMing ERC1155 DB Interface
interface SegMintERC1155DBInterface {
    // update owner address
    function setOwnerAddress(address owner_) external;

    // get owner address
    function getOwner() external view returns (address);

    // set SegMint ERC. 1155 Platform Management Contract Address
    function setSegMintERC1155PlatformManagementContractAddress(
        address SegMintERC1155PlatformManagementContractAddress_
    ) external;

    // get SegMint Platform Management Contract Address
    function getSegMintPlatformManagementContractAddress()
        external
        view
        returns (address);

    // set SegMintERC1155ContractAddress address
    function setSegMintERC1155ContractAddress(
        address SegMintERC1155ContractAddress_
    ) external;

    // get SegMintERC1155ContractAddress address
    function getSegMintERC1155ContractAddress() external view returns (address);

    // set meta data
    function setMetaData(
        uint256 TokenID_,
        string memory name_,
        string memory symbol_,
        string memory description_,
        address minter_
    ) external;

    // increase total Supply
    function increaseTokenIDTotalSupply(uint256 TokenID_, uint256 amount_)
        external;

    // decrease total supply
    function decreaseTokenIDTotalSupply(uint256 TokenID_, uint256 amount_)
        external;

    // function set Balance
    function setTokenIDBalance(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) external;

    // function add balance
    function addBalance(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) external;

    // function deduct balance
    function deductBalance(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) external;

    // function lock ERC1155 TokenID for an account (for listing)
    function lockToken(
        uint256 TokenID_,
        address holder_,
        // address locker_,
        uint256 amount_
    ) external returns (bool);

    // function unlock locked ERC1155 TokenID balance (delisting / sales)
    function unlockToken(
        uint256 TokenID_,
        address holder_,
        // address locker_,
        uint256 amount_
    ) external returns (bool);

    // set approval for all
    function setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) external;

    // add account to holders
    function appendToHolders(uint256 TokenID_, address account_) external;

    // remove account from holders
    function removeFromHolders(uint256 TokenID_, address account_) external;

    // set locker info
    function setLockerInfo(
        uint256 TokenID_,
        address holder_,
        address locker_,
        uint256 amount_
    ) external;

    // add account to lockers of token id by owner
    function appendToLockersOfTokenIDByOwner(
        uint256 TokenID_,
        address holder_,
        address locker_
    ) external;

    // remove account from lockers of token id by owner
    function removeFromLockersOfTokenIDByOwner(
        uint256 TokenID_,
        address holder_,
        address locker_
    ) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    // get metadata
    function getMetaData(uint256 TokenID_)
        external
        view
        returns (
            string memory name_,
            string memory symbol_,
            string memory description_,
            address minter_,
            uint256 totalSupply_
        );

    // get balance Of
    function getBalanceOf(uint256 TokenID_, address account_)
        external
        view
        returns (uint256);

    // get locked balance
    function getLockedBalance(uint256 TokenID_, address account_)
        external
        view
        returns (uint256);

    // get available balance
    function getAvailableBalance(uint256 TokenID_, address account_)
        external
        view
        returns (uint256);

    // Sender has sufficient unlocked balance
    function HaveSufficientUnlockedBalance(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) external view;

    // check if an address is locker of a token id for a holder
    function isLocker(
        uint256 TokenID_,
        address holder_,
        address locker_,
        uint256 lockedAmount_
    ) external view returns (bool);

    // returns array of token holders of specific TokenID
    function getTokenIDHolders(uint256 TokenID_)
        external
        view
        returns (address[] memory);

    // is minted
    function isMinted(uint256 TokenID_) external view returns (bool);
}

// SegMint ERC1155 Fee Management Interface
interface SegMintERC1155FeeManagementInterface {
    // Set Fee Manager Address
    function setFeeManager(address feeManager_) external;

    // get Fee Manager address
    function getFeeManager() external view returns (address);

    // Set Treasurer Address
    function setTreasurer(address treasurer_) external;

    // get treasurer address
    function getTreasurer() external view returns (address);

    // set fees decimal
    function setFeesDecimal(uint256 value_) external;

    // get Fees decimal
    function getFeesDecimal() external view returns (uint256);

    // set segminting fees
    function setSegmintingFees(uint256 value_) external;

    // get segminting fees
    function getSegmintingFees() external view returns (uint256);

    // set reclaiming fees
    function setReclaimingFees(uint256 value_) external;

    // get reclaiming fees
    function getReclaimingFees() external view returns (uint256);

    // get transfer fees
    function getTransferFees() external view returns (uint256);
}

// SegMint Whitelist Management Interface
interface SegMintERC1155WhitelistInterface {
    // get contract version
    function getContractVersion() external view returns (uint256);

    // set Owner Address
    function setOwnerAddress(address owner_) external;

    // get owner address
    function getOwnerAddress() external view returns (address);

    // set whitelist manager address
    function setWhitelistManagerAddress(address whitelistManager_) external;

    // get whitelist manager address
    function getWhitelistManagerAddress() external view returns (address);

    // add or remove an account in global whitelisted address
    function modifyGlobalWhitelistAddresses(address account_, bool status_)
        external;

    // add or remove an account in global Segminting whitelisted address
    function modifyGlobalSegmintingWhitelistAddresses(
        address account_,
        bool status_
    ) external;

    // add or remove an account in global reclaiming whitelisted address
    function modifyGlobalReclaimingwhitelistAddresses(
        address account_,
        bool status_
    ) external;

    // add or remove an account in TokenID reclaiming whitelisted address
    function modifyTokenIDReclaimingwhitelistAddresses(
        uint256 TokenID_,
        address account_,
        bool status_
    ) external;

    // add or remove an account in global transfer whitelisted address
    function modifyGlobalTransferAddresses(address account_, bool status_)
        external;

    // add or remove an account as TokenID transfer whitelisted address
    function modifyTokenIDTransferAddresses(
        uint256 TokenID_,
        address account_,
        bool status_
    ) external;

    // is global whitelisted
    function isGlobalWhitelisted(address account_) external view returns (bool);

    // get global whitelist addresses
    function getGlobalWhitelistAddresses()
        external
        view
        returns (address[] memory);

    // isGlobalSegmintingWhitelisted
    function isGlobalSegmintingWhitelisted(address account_)
        external
        view
        returns (bool);

    // get global segminting whitelist addresses
    function getGlobalSegmintingWhitelistAddresses()
        external
        view
        returns (address[] memory);

    // isGlobalReclaimingWhitelisted
    function isGlobalReclaimingWhitelisted(address account_)
        external
        view
        returns (bool);

    // get global reclaiming whitelist addresses
    function getGlobalReclaimingWhitelistAddresses()
        external
        view
        returns (address[] memory);

    // isTokenIDReclaimingWhitelisted
    function isTokenIDReclaimingWhitelisted(address account_, uint256 TokenID_)
        external
        view
        returns (bool);

    // get TokenID reclaiming whitelist addresses
    function getTokenIDReclaimingWhitelistAddresses(uint256 TokenID_)
        external
        view
        returns (address[] memory);

    // isGlobalTransferWhitelisted
    function isGlobalTransferWhitelisted(address account_)
        external
        view
        returns (bool);

    // get global transfer whitelist addresses
    function getGlobalTransferWhitelistAddresses()
        external
        view
        returns (address[] memory);

    // isTokenIDTransferWhitelisted
    function isTokenIDTransferWhitelisted(address account_, uint256 TokenID_)
        external
        view
        returns (bool);

    // get TokenID transfer whitelist addresses
    function getTokenIDTransferWhitelistAddresses(uint256 TokenID_)
        external
        view
        returns (address[] memory);
}

// SegMint ERC1155 Platform Management Interface
interface SegMintERC1155PlatformManagementInterface {
    // get contract version
    function getContractVersion() external view returns (uint256);

    // set Owner Address
    function setOwnerAddress(address owner_) external;

    // get owner address
    function getOwnerAddress() external view returns (address);

    // set SegMint ERC1155 DB Contract Address
    function setSegMintERC1155DBContractAddress(
        address SegMintERC1155DBContractAddress_
    ) external;

    // get SegMint ERC1155 DB Contract Address
    function getSegMintERC1155DBAddress() external view returns (address);

    // set SegMint Exchange Contract Address
    function setSegMintExchangeAddress(address SegMintExchangeAddress_)
        external;

    // get exchange contract
    function getSegmintExchangeContractAddress()
        external
        view
        returns (address);

    // set SegMint ERC1155 Contract Address
    function setSegMintERC1155Address(address SegMintERC1155Address_) external;

    // get ERC1155 contract
    function getSegmintERC1155ContractAddress() external view returns (address);

    // update _globalTradingPlatfromRestriction
    function updateGlobalTradingPlatfromRestriction(bool status_) external;

    // get global trading platform restriction status
    function getGlobalTradingPlatformRestrictionStatus()
        external
        view
        returns (bool);

    // add ERC1155 Token ID to _unrestrictedToSegMintPlatformTokenIDs if already not in the array
    // alow Token ID to be tradable on other platforms
    function addERC1155TokenIDToUnrestrictedToSegMintPlatformTokenIDs(
        uint256 ERC1155TokenID_
    ) external;

    // remove ERC1155 Token ID fom _unrestrictedToSegMintPlatformTokenIDs if already in the array
    // restrict the Token ID to be tradable ONLY on SegMint platform
    function removeERC1155TokenIDToUnrestrictedToSegMintPlatformTokenIDs(
        uint256 ERC1155TokenID_
    ) external;

    // get unrestricted ERC1155 Token IDs to trade on any platform
    function getUnrestrictedERC1155TokenIDs()
        external
        view
        returns (uint256[] memory);

    // is restricted to SegMint Platform
    function isRestrictedToSegMintPlatform(uint256 ERC1155TokenID_)
        external
        view
        returns (bool);

    // freeze global transactions
    function freezeGlobalTransactions() external;

    // unfreeze global transactions
    function unFreezeGlobalTransactions() external;

    // get global transaction freeze status
    function getGlobalTransactionsFreezeStatus() external view returns (bool);

    // freeze global transaction for specific TokenID
    function freezeGlobalTransactionsSpecificTokenID(uint256 TokenID_) external;

    // unfreeze global transaction for specific TokenID
    function unFreezeGlobalTransactionsSpecificTokenID(uint256 TokenID_)
        external;

    // get global transaction status for Specific TokenID
    function getGlobalTransactionsFreezeStatusSpecificTokenID(uint256 TokenID_)
        external
        view
        returns (bool);

    // function to lock tokens while listing the NFT
    function lockToken(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) external returns (bool);

    // function to un lock tokens while de-listing the NFT
    function unlockToken(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) external returns (bool);

    // unfreeze tokens and transfer to buyer
    function unLockAndTransferToken(
        uint256 TokenID_,
        address seller,
        address buyer,
        uint256 amount_
    ) external returns (bool);

    // buyout Price for all holders for ERC1155 Token ID
    function getBuyoutPriceFromAllHolders(
        address buyer,
        address creator,
        uint256 TokenID_,
        uint256 buyOutPricePerFraction,
        uint256 reservePricePerFraction
    ) external view returns (uint256);

    // buyout price for buying from specific holders of ERC1155 Token ID
    function getBuyOutPriceFromSpecificHolders(
        address buyer,
        address[] memory holders,
        address creator,
        uint256 TokenID_,
        uint256 buyOutPricePerFraction,
        uint256 reservePricePerFraction
    ) external view returns (uint256);

    // Buyout all fractions from all holders of ERC1155 Token ID
    function BuyoutFromAllHolders(
        address buyer,
        address creator,
        uint256 TokenID_,
        uint256 buyOutPricePerFraction,
        uint256 reservePricePerFraction
    ) external payable returns (bool);

    // buyout all fractions from specific holders of ERC1155 Token ID
    function BuyoutFromSpecificHolders(
        address buyer,
        address[] memory holders,
        address creator,
        uint256 TokenID_,
        uint256 buyOutPricePerFraction,
        uint256 reservePricePerFraction
    ) external payable returns (bool);
}

// SegMint ERC1155 Asset Protection Interface
interface SegMintERC1155AssetProtectionInterface {
    // get contract version
    function getContractVersion() external view returns (uint256);

    // set asset prtection address
    function setAssetProtection(address assetProtection_) external;

    // get asset protection address
    function getAssetProtection() external view returns (address);

    // set SegMint ERC1155 Contract Address
    function setSegMintERC1155ContractAddress(
        address SegMintERC1155ContractAddress_
    ) external;

    // get SegMint ERC1155 Contract Address
    function getSegMintERC1155ContractAddress() external view returns (address);

    // set SegMint ERC1155 DB Contract Address
    function setSegMintERC1155DBContractAddress(
        address SegMintERC1155DBContractAddress_
    ) external;

    // get SegMint ERC1155 DB Contract Address
    function getSegMintERC1155DBAddress() external view returns (address);

    // freeze account for trading all TokenIDs
    function freezeAccount(address account_) external;

    // unfreeze account for trading all TokenIDs
    function unFreezeAccount(address account_) external;

    // get account freeze status
    function isAccountFreezed(address account_) external view returns (bool);

    // freeze an account for trading a specific TokenID
    function freezeAccountTransactionsSpecificTokenID(
        address account_,
        uint256 TokenID_
    ) external;

    // unfreeze an account for trading a specific TokenID
    function unFreezeAccountTransactionsSpecificTokenID(
        address account_,
        uint256 TokenID_
    ) external;

    // get freeze status of an account for a specific TokenID
    function isAccountFreezedForSpecificTokenID(
        address account_,
        uint256 TokenID_
    ) external view returns (bool);

    // wipe frozen account for specific TokenID
    function wipeFrozenAccountSpecificTokenID(
        address account_,
        uint256 TokenID_
    ) external returns (bool);

    // wipe and freez account for specific TokenID
    function wipeAndFreezeAccountSpecificTokenID(
        address account_,
        uint256 TokenID_
    ) external returns (bool);

    // wipe, freeze account and transfer balance to An Account for specific TokenID
    function WipeFreezeAndTransferAccountSpecificTokenID(
        address account_,
        uint256 TokenID_,
        address receiverAccount_
    ) external returns (bool);
}

// SegMint ERC1155 Interface
interface SegMintERC1155Interface {
    // update owner address
    function updateOwnerAddress(address owner_) external;

    // get owner address
    function getOwner() external view returns (address);

    // set SegMint ERC1155 DB Contract Address
    function setSegMintERC1155DBContractAddress(
        address SegMintERC1155DBContractAddress_
    ) external;

    // get SegMint ERC1155 DB Contract Address
    function getSegMintERC1155DBAddress() external view returns (address);

    // set SegMint ERC1155 Fee Management Contract Address
    function setSegMintERC1155FeeManagementContractAddress(
        address SegMintERC1155FeeManagementContractAddress_
    ) external;

    // get SegMint ERC1155 Fee Management Contract Address
    function getSegMintERC1155FeeManagementAddress()
        external
        view
        returns (address);

    // set SegMint ERC1155 Whitelist Management Contract Address
    function setSegMintERC1155WhitelistManagementContractAddress(
        address SegMintERC1155WhitelistManagementContractAddress_
    ) external;

    // get SegMint ERC1155 Whitelist Management Contract Address
    function getSegMintERC1155WhitelistManagementAddress()
        external
        view
        returns (address);

    // set SegMint ERC1155 Asset Protection Contract Address
    function setSegMintERC1155AssetProtectionAddress(
        address SegMintERC1155AssetProtectionContractAddres_
    ) external;

    // get SegMint ERC1155 Asset Protection Contract Address
    function getSegMintERC1155AssetProtectionContractAddress()
        external
        view
        returns (address);

    // set SegMint ERC1155 Platform Management Contract Address
    function setSegMintERC1155PlatformManagementAddress(
        address SegMintERC1155PlatformManagementContractAddress_
    ) external;

    // get SegMint ERC1155 Platform Management Contract Address
    function getSegMintERC1155PlatformManagementContractAddress()
        external
        view
        returns (address);

    // set SegMint Exchange Contract Address
    function setSegMintExchangeAddress(address SegMintExchangeContractAddress_)
        external;

    // get exchange contract
    function getSegmintExchangeContractAddress()
        external
        view
        returns (address);

    // support interface
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // balance of
    function balanceOf(address account_, uint256 TokenID_)
        external
        view
        returns (uint256);

    // balance of batch
    function balanceOfBatch(
        address[] memory accounts_,
        uint256[] memory TokenIDs_
    ) external view returns (uint256[] memory);

    // set approval for all
    function setApprovalForAll(address operator_, bool approved_) external;

    // is approved for all
    function isApprovedForAll(address account_, address operator_)
        external
        view
        returns (bool);

    // safe transfer from
    function safeTransferFrom(
        address sender,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external payable;

    // mint (only Exchange)
    function mint(
        address account_,
        uint256 amount_,
        bytes memory data_,
        string memory name_,
        string memory symbol_,
        string memory description_
    ) external payable returns (bool);

    // burn (only Exchange)
    function burn(
        address account_,
        uint256 TokenID_,
        uint256 amount_
    ) external payable returns (bool);

    // mint to already existing Token ID (only Asset Protection)
    function mintKey(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) external returns (bool);

    // burn by asset protection
    function burnKeys(
        address account_,
        uint256 TokenID_,
        uint256 amount_
    ) external returns (bool);

    // for buyout transfer balance (with locked balance) (only Platform Management)
    function safeTransferFromBuyOut(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    // get name
    function getName() external view returns (string memory);

    // get symbol
    function getSymbol() external view returns (string memory);

    // get contract version
    function getContractVersion() external view returns (uint256);

    // get the TokenID counter
    function getTokenIDCounter() external view returns (uint256);
}

// SegMint ERC1155 Contract
contract ERC1155 is ERC165, IERC1155 {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    // Address
    using Address for address;

    // Strings
    using Strings for string;

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // owner
    address private _owner;

    // name
    string public name;

    // symbol
    string public symbol;

    // contract version
    uint256 private _contractVersion = 0;

    // SegMint ERC1155 DB Contract Address
    address private _SegMintERC1155DBContractAddress;

    // SegMint ERC1155 DB Contract Interface
    SegMintERC1155DBInterface SegMintERC1155DB;

    // SegMint ERC1155 Fee Management Contract Address
    address private _SegMintERC1155FeeManagementAddress;

    // SegMint ERC1155 Fee Management Contract Interface
    SegMintERC1155FeeManagementInterface SegMintERC1155FeeManagement;

    // SegMint ERC1155 Whitelist Management Contract Address
    address private _SegMintERC1155WhitelistManagementAddress;

    // SegMint ERC1155 Whitelist Management Contract Interface
    SegMintERC1155WhitelistInterface SegMintERC1155WhitelistManagement;

    // SegMint ERC1155 Asset Protection Contract Address
    address private _SegMintERC1155AssetProtectionContractAddress;

    // SegMint ERc1155 Asset Protection Contract Interface
    SegMintERC1155AssetProtectionInterface SegMintERC1155AssetProtection;

    // SegMint ERC1155 Platform Management Contract Address
    address private _SegMintERC1155PlatformManagementContractAddress;

    // SegMint ERC1155 Platform Management Contract Interface
    SegMintERC1155PlatformManagementInterface SegMintERC1155PlatformManagement;

    // exchange smart contract address
    address private _SegMintExchangeContractAddress;

    // SegMint Key Generator Contract Address
    address private _SegMintKeyGeneratorContractAddress;
    // tokenId counter
    uint256 private tokenIdCounter = 1;

    ////////////////////////
    ///    Constructor   ///
    ////////////////////////

    constructor(string memory name_, string memory symbol_) {
        _owner = msg.sender;
        name = name_;
        symbol = symbol_;
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // update owner address
    event updateOwnerAddressEvent(
        address indexed OwnerAddress,
        address previousOwnerAddress,
        address indexed newOwnerAddress,
        uint256 indexed timestamp
    );

    // set SegMint ERC1155 DB Contract Address
    event setSegMintERC1155DBContractAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintERC1155DBContractAddress,
        address indexed newSegMintERC1155DBContractAddress,
        uint256 indexed timestamp
    );

    // set SegMint ERC1155 Fee Management Contract Address
    event setSegMintERC1155FeeManagementContractAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintERC1155FeeManagementContractAddress,
        address indexed newSegMintERC1155FeeManagementContractAddress,
        uint256 indexed timestamp
    );

    // set SegMint ERC1155 Whitelist Management Contract Address
    event setSegMintERC1155WhitelistManagementContractAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintERC1155WhietlistManagementContractAddress,
        address indexed newSegMintERC1155WhietlistManagementContractAddress,
        uint256 indexed timestamp
    );

    // set SegMint ERC1155 Asset Protection Contract Address
    event setSegMintERC1155AssetProtectionAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintERC1155AssetProtectionContractAddress,
        address indexed newSegMintERC1155AssetProtectionContractAddress,
        uint256 indexed timestamp
    );

    // set SegMint ERC1155 Platform Management Contract Addres
    event setSegMintERC1155PlatformManagementAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintERC1155PlatformManagementContractAddress,
        address indexed newSegMintERC1155PlatformManagementContractAddress,
        uint256 indexed timestamp
    );

    // set SegMint Exchange Contract Address
    event setSegMintExchangeAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintExchangeContractAddress,
        address indexed newSegMintExchangeContractAddress,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    ////    SegMint Modifiers    ////

    // generic only role
    modifier onlyRole(string memory RoleName_) {
        // role address
        address RoleAddress;

        if (Strings.equal(RoleName_, "owner")) {
            RoleAddress = _owner;
        } else if (Strings.equal(RoleName_, "Asset Protection")) {
            RoleAddress = _SegMintERC1155AssetProtectionContractAddress;
        } else if (Strings.equal(RoleName_, "Exchange")) {
            RoleAddress = _SegMintExchangeContractAddress;
        } else if (Strings.equal(RoleName_, "Platform Management")) {
            RoleAddress = _SegMintERC1155PlatformManagementContractAddress;
        } else if (Strings.equal(RoleName_, "Key Generator")) {
            RoleAddress = _SegMintKeyGeneratorContractAddress;
        } else {
            RoleAddress = _owner;
        }

        // require sender be the role specified
        require(
            msg.sender == RoleAddress,
            string.concat(
                "SegMint ERC1155: ",
                "Sender ",
                Strings.toHexString(msg.sender),
                " is not the ",
                RoleName_,
                " address!"
            )
        );
        _;
    }

    // not Null address
    modifier notNullAddress(address address_, string memory accountName_) {
        // require address not be the zero address
        require(
            address_ != address(0),
            string.concat(
                "SegMint ERC115: ",
                accountName_,
                " ",
                Strings.toHexString(address_),
                " should not be the zero address!"
            )
        );
        _;
    }

    // only minted TokenID
    modifier onlyMinted(uint256 TokenID_) {
        // require TokenID be minted
        require(
            SegMintERC1155DB.isMinted(TokenID_),
            string.concat(
                "SegMint ERC1155: ",
                "TokenID ",
                Strings.toString(TokenID_),
                " is not minted!"
            )
        );
        _;
    }

    // only when all transaction are not freezed (all Token IDs)
    modifier onlyNotGlobalFreeze() {
        require(
            !SegMintERC1155PlatformManagement
                .getGlobalTransactionsFreezeStatus(),
            "SegMint ERC1155: All Transactions are freezed!"
        );
        _;
    }

    // only when all transaction of a Token ID is not freezed
    modifier onlyNotGlobalTokenIDFreeze(uint256 TokenID_) {
        require(
            !SegMintERC1155PlatformManagement
                .getGlobalTransactionsFreezeStatusSpecificTokenID(TokenID_),
            string.concat(
                "SegMint ERC1155: ",
                "All transactions for TokenID ",
                Strings.toString(TokenID_),
                " are freezed!"
            )
        );
        _;
    }

    // only when an account not freezed (all Token IDs)
    modifier onlyNotAccountFreeze(address from, address to) {
        if (to != address(0)) {
            require(
                !SegMintERC1155AssetProtection.isAccountFreezed(from),
                string.concat(
                    "SegMint ERC155: ",
                    "Transactions from account ",
                    Strings.toHexString(from),
                    " are freezed!"
                )
            );
            require(
                !SegMintERC1155AssetProtection.isAccountFreezed(to),
                string.concat(
                    "SegMint ERC155: ",
                    "Transactions to account ",
                    Strings.toHexString(to),
                    " are freezed!"
                )
            );
        }
        _;
    }

    // only when an account not freezed for a specific Token ID
    modifier onlyNotAccountTokenIDFreeze(
        address from,
        address to,
        uint256 TokenID_
    ) {
        if (from != address(0)) {
            require(
                !SegMintERC1155AssetProtection
                    .isAccountFreezedForSpecificTokenID(from, TokenID_),
                string.concat(
                    "SegMint ERC155: ",
                    "Transactions from account ",
                    Strings.toHexString(from),
                    " for ERC1155 Token ID ",
                    Strings.toString(TokenID_),
                    " are freezed!"
                )
            );
            require(
                !SegMintERC1155AssetProtection
                    .isAccountFreezedForSpecificTokenID(to, TokenID_),
                string.concat(
                    "SegMint ERC155: ",
                    "Transactions to account ",
                    Strings.toHexString(to),
                    " for ERC1155 Token ID ",
                    Strings.toString(TokenID_),
                    " are freezed!"
                )
            );
        }
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    ///    Setting Addresses   ///

    // update owner address
    function updateOwnerAddress(address owner_)
        public
        onlyRole("owner")
        notNullAddress(owner_, "Owner Address")
    {
        // previous owner
        address previousOwnerAddress = _owner;

        // update owner
        _owner = owner_;

        // emit event
        emit updateOwnerAddressEvent(
            msg.sender,
            previousOwnerAddress,
            owner_,
            block.timestamp
        );
    }

    // get owner address
    function getOwner() public view returns (address) {
        return _owner;
    }

    // set SegMint ERC1155 DB Contract Address
    function setSegMintERC1155DBContractAddress(
        address SegMintERC1155DBContractAddress_
    )
        public
        onlyRole("owner")
        notNullAddress(
            SegMintERC1155DBContractAddress_,
            "SegMint ERC1155 DB Contract Address"
        )
    {
        // previous SegMint ERC1155 DB Contract Address
        address previousSegMintERC1155DBContractAddress = _SegMintERC1155DBContractAddress;

        // update contract
        _SegMintERC1155DBContractAddress = SegMintERC1155DBContractAddress_;

        // update interface
        SegMintERC1155DB = SegMintERC1155DBInterface(
            SegMintERC1155DBContractAddress_
        );

        // emit event
        emit setSegMintERC1155DBContractAddressEvent(
            msg.sender,
            previousSegMintERC1155DBContractAddress,
            SegMintERC1155DBContractAddress_,
            block.timestamp
        );
    }

    // get SegMint ERC1155 DB Contract Address
    function getSegMintERC1155DBAddress() public view returns (address) {
        return _SegMintERC1155DBContractAddress;
    }

    // set SegMint ERC1155 Fee Management Contract Address
    function setSegMintERC1155FeeManagementContractAddress(
        address SegMintERC1155FeeManagementContractAddress_
    )
        public
        onlyRole("owner")
        notNullAddress(
            SegMintERC1155FeeManagementContractAddress_,
            "SegMint ERC1155 Fee Management Address"
        )
    {
        // previous Contract Address
        address previousSegMintERC1155FeeManagementContractAddress = _SegMintERC1155FeeManagementAddress;

        // update contract
        _SegMintERC1155FeeManagementAddress = SegMintERC1155FeeManagementContractAddress_;

        // update interface
        SegMintERC1155FeeManagement = SegMintERC1155FeeManagementInterface(
            SegMintERC1155FeeManagementContractAddress_
        );

        // emit event
        emit setSegMintERC1155FeeManagementContractAddressEvent(
            msg.sender,
            previousSegMintERC1155FeeManagementContractAddress,
            SegMintERC1155FeeManagementContractAddress_,
            block.timestamp
        );
    }

    // get SegMint ERC1155 Fee Management Contract Address
    function getSegMintERC1155FeeManagementAddress()
        public
        view
        returns (address)
    {
        return _SegMintERC1155FeeManagementAddress;
    }

    // set SegMint ERC1155 Whitelist Management Contract Address
    function setSegMintERC1155WhitelistManagementContractAddress(
        address SegMintERC1155WhitelistManagementContractAddress_
    )
        public
        onlyRole("owner")
        notNullAddress(
            SegMintERC1155WhitelistManagementContractAddress_,
            "SegMint ERC1155 Whitelist Management Address"
        )
    {
        // previous Contract Address
        address previousSegMintERC1155WhietlistManagementContractAddress = _SegMintERC1155WhitelistManagementAddress;

        // update contract
        _SegMintERC1155WhitelistManagementAddress = SegMintERC1155WhitelistManagementContractAddress_;

        // update interface
        SegMintERC1155WhitelistManagement = SegMintERC1155WhitelistInterface(
            SegMintERC1155WhitelistManagementContractAddress_
        );

        // emit event
        emit setSegMintERC1155WhitelistManagementContractAddressEvent(
            msg.sender,
            previousSegMintERC1155WhietlistManagementContractAddress,
            SegMintERC1155WhitelistManagementContractAddress_,
            block.timestamp
        );
    }

    // get SegMint ERC1155 Whitelist Management Contract Address
    function getSegMintERC1155WhitelistManagementAddress()
        public
        view
        returns (address)
    {
        return _SegMintERC1155WhitelistManagementAddress;
    }

    // set SegMint ERC1155 Asset Protection Contract Address
    function setSegMintERC1155AssetProtectionAddress(
        address SegMintERC1155AssetProtectionContractAddres_
    )
        public
        notNullAddress(
            SegMintERC1155AssetProtectionContractAddres_,
            "Asset Protection Contract Address"
        )
        onlyRole("owner")
    {
        // previous address
        address previousSegMintERC1155AssetProtectionContractAddress = _SegMintERC1155AssetProtectionContractAddress;

        // update
        _SegMintERC1155AssetProtectionContractAddress = SegMintERC1155AssetProtectionContractAddres_;

        // update interface
        SegMintERC1155AssetProtection = SegMintERC1155AssetProtectionInterface(
            SegMintERC1155AssetProtectionContractAddres_
        );

        // emit event
        emit setSegMintERC1155AssetProtectionAddressEvent(
            msg.sender,
            previousSegMintERC1155AssetProtectionContractAddress,
            SegMintERC1155AssetProtectionContractAddres_,
            block.timestamp
        );
    }

    // get SegMint ERC1155 Asset Protection Contract Address
    function getSegMintERC1155AssetProtectionContractAddress()
        public
        view
        returns (address)
    {
        return _SegMintERC1155AssetProtectionContractAddress;
    }

    // set SegMint ERC1155 Platform Management Contract Address
    function setSegMintERC1155PlatformManagementAddress(
        address SegMintERC1155PlatformManagementContractAddress_
    )
        public
        notNullAddress(
            SegMintERC1155PlatformManagementContractAddress_,
            "Platform Management Address"
        )
        onlyRole("owner")
    {
        // previous address
        address previousSegMintERC1155PlatformManagementContractAddress = _SegMintERC1155PlatformManagementContractAddress;

        // update
        _SegMintERC1155PlatformManagementContractAddress = SegMintERC1155PlatformManagementContractAddress_;

        // set interface
        SegMintERC1155PlatformManagement = SegMintERC1155PlatformManagementInterface(
            SegMintERC1155PlatformManagementContractAddress_
        );

        // emit event
        emit setSegMintERC1155PlatformManagementAddressEvent(
            msg.sender,
            previousSegMintERC1155PlatformManagementContractAddress,
            SegMintERC1155PlatformManagementContractAddress_,
            block.timestamp
        );
    }

    // get SegMint ERC1155 Platform Management Contract Address
    function getSegMintERC1155PlatformManagementContractAddress()
        public
        view
        returns (address)
    {
        return _SegMintERC1155PlatformManagementContractAddress;
    }

    // set SegMint Exchange Contract Address
    function setSegMintExchangeAddress(address SegMintExchangeContractAddress_, address SegMintKeyGeneratorContractAddress_)
        public
        onlyRole("owner")
        notNullAddress(
            SegMintExchangeContractAddress_,
            "SegMint Exchange Contract Address"
        )
    {
        // previous SegMint Exchange Address
        address previousExchangeContractAddress = _SegMintExchangeContractAddress;

        // update
        _SegMintExchangeContractAddress = SegMintExchangeContractAddress_;

        _SegMintKeyGeneratorContractAddress = SegMintKeyGeneratorContractAddress_;

        // emit event
        emit setSegMintExchangeAddressEvent(
            msg.sender,
            previousExchangeContractAddress,
            SegMintExchangeContractAddress_,
            block.timestamp
        );
    }


    // get exchange contract
    function getSegmintExchangeContractAddress() public view returns (address) {
        return _SegMintExchangeContractAddress;
    }

    function getSegmintKeyGeneratorContractAddress() public view returns (address) {
        return _SegMintKeyGeneratorContractAddress;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account_, uint256 TokenID_)
        public
        view
        virtual
        override
        notNullAddress(account_, "Account")
        returns (uint256)
    {
        return SegMintERC1155DB.getBalanceOf(TokenID_, account_);
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts_,
        uint256[] memory TokenIDs_
    ) public view virtual override returns (uint256[] memory) {
        require(
            accounts_.length == TokenIDs_.length,
            "SegMint ERC1155: accounts and TokenIDs length mismatch!"
        );

        uint256[] memory batchBalances = new uint256[](accounts_.length);

        for (uint256 i = 0; i < accounts_.length; ++i) {
            batchBalances[i] = balanceOf(accounts_[i], TokenIDs_[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator_, bool approved_)
        public
        virtual
        override
    {
        // set approval
        SegMintERC1155DB.setApprovalForAll(msg.sender, operator_, approved_);

        // emit event
        emit ApprovalForAll(msg.sender, operator_, approved_);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account_, address operator_)
        public
        view
        virtual
        override
        returns (bool)
    {
        return SegMintERC1155DB.isApprovedForAll(account_, operator_);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address sender,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        payable
        virtual
        override
        onlyMinted(id)
        notNullAddress(from, "From Address")
        notNullAddress(to, "To Address")
    {
        // Token ID trade restricted to SegMint Platfrom
        if (
            SegMintERC1155PlatformManagement.isRestrictedToSegMintPlatform(id)
        ) {
            // sender should be the SegMint Exchange
            require(
                msg.sender == getSegmintExchangeContractAddress(),
                string.concat(
                    "SegMint ERC1155: ",
                    "Sender Address ",
                    Strings.toHexString(msg.sender),
                    " is not the SegMing Exchange Platform!"
                )
            );

            // require sender be either owner or approved
            require(
                from == sender ||
                    SegMintERC1155DB.isApprovedForAll(from, sender),
                "SegMint ERC1155: caller is not token owner or approved"
            );
        } else {
            require(
                from == msg.sender ||
                    SegMintERC1155DB.isApprovedForAll(from, msg.sender),
                "SegMint ERC1155: caller is not token owner or approved"
            );
        }

        // collect fees if from address is not in  global / global transfer or token id transfer whitelists
        if (
            !(SegMintERC1155WhitelistManagement.isGlobalWhitelisted(from) ||
                SegMintERC1155WhitelistManagement.isGlobalTransferWhitelisted(
                    from
                ) ||
                SegMintERC1155WhitelistManagement.isTokenIDTransferWhitelisted(
                    from,
                    id
                ))
        ) {
            require(
                msg.value == SegMintERC1155FeeManagement.getTransferFees(),
                "SegMint ERC1155: Please send correct transfer fee amount!"
            );
            payable(SegMintERC1155FeeManagement.getTreasurer()).transfer(
                msg.value
            );
        }

        _safeTransferFrom(from, to, id, amount, data);
    }

    //// SegMint Public Functions   ////

    // mint new Token ID
    function mint(
        address account_,
        uint256 amount_,
        bytes memory data_,
        string memory name_,
        string memory symbol_,
        string memory description_
    ) public payable onlyRole("Key Generator") returns (bool) {
        //collect fees
        if (
            !(SegMintERC1155WhitelistManagement.isGlobalWhitelisted(account_) ||
                SegMintERC1155WhitelistManagement.isGlobalSegmintingWhitelisted(
                        account_
                    ))
        ) {
            require(
                msg.value == SegMintERC1155FeeManagement.getSegmintingFees(),
                "SegMint ERC1155: Please send correct SegMintation fee!"
            );
            payable(SegMintERC1155FeeManagement.getTreasurer()).transfer(
                msg.value
            );
        }

        uint256 TokenID = tokenIdCounter;
        tokenIdCounter++;
        // mint
        _mint(account_, TokenID, amount_, data_);

        // update onwer of the TokenID
        SegMintERC1155DB.appendToHolders(TokenID, account_);

        // set name , symbol, description and minter
        SegMintERC1155DB.setMetaData(
            TokenID,
            name_,
            symbol_,
            description_,
            account_
        );

        // return
        return true;
    }

    // burn
    function burn(
        address account_,
        uint256 TokenID_,
        uint256 amount_
    ) public payable onlyRole("Key Generator") returns (bool) {
        //collect fees
        if (
            !(SegMintERC1155WhitelistManagement.isGlobalWhitelisted(account_) ||
                SegMintERC1155WhitelistManagement.isGlobalReclaimingWhitelisted(
                        account_
                    ) ||
                SegMintERC1155WhitelistManagement
                    .isTokenIDReclaimingWhitelisted(account_, TokenID_))
        ) {
            require(
                msg.value == SegMintERC1155FeeManagement.getReclaimingFees(),
                "SegMint ERC1155: Please send Reclaiming fees"
            );
            payable(SegMintERC1155FeeManagement.getTreasurer()).transfer(
                msg.value
            );
        }

        // get balance of the account
        uint256 currentBalance = SegMintERC1155DB.getBalanceOf(
            TokenID_,
            account_
        );

        // burn
        _burn(account_, TokenID_, amount_);

        // update the owner of the TokenID
        if (amount_ == currentBalance) {
            // remove address fro the holdersOfTokenID list
            SegMintERC1155DB.removeFromHolders(TokenID_, account_);
        }

        // return
        return true;
    }

    // mint to already existing Token ID
    function mintKey(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) public onlyRole("Asset Protection") returns (bool) {
        // mint
        _mint(account_, TokenID_, amount_, "");

        // update onwer of the TokenID
        SegMintERC1155DB.appendToHolders(TokenID_, account_);

        // return
        return true;
    }

    // burn by asset protection
    function burnKeys(
        address account_,
        uint256 TokenID_,
        uint256 amount_
    ) public onlyRole("Asset Protection") returns (bool) {
        // get balance of the account
        uint256 currentBalance = SegMintERC1155DB.getBalanceOf(
            TokenID_,
            account_
        );

        // burn
        _burn(account_, TokenID_, amount_);

        // update the owner of the TokenID
        if (amount_ == currentBalance) {
            // remove address fro the holdersOfTokenID list
            SegMintERC1155DB.removeFromHolders(TokenID_, account_);
        }

        // return
        return true;
    }

    // for buyout transfer balance (with locked balance)
    function safeTransferFromBuyOut(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        external
        onlyRole("Platform Management")
    // notNullAddress(from, "From Address")
    // notNullAddress(to, "To Address")
    {
        // require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = SegMintERC1155DB.getBalanceOf(id, from);

        unchecked {
            SegMintERC1155DB.setTokenIDBalance(id, from, fromBalance - amount);
        }

        uint256 toBalance = SegMintERC1155DB.getBalanceOf(id, to);
        SegMintERC1155DB.setTokenIDBalance(id, to, toBalance + amount);

        // update onwer of the TokenID
        SegMintERC1155DB.appendToHolders(id, to);

        // remove from address if balance is 0
        if (SegMintERC1155DB.getBalanceOf(id, to) == 0) {
            SegMintERC1155DB.removeFromHolders(id, from);
        }

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /////////////////////////////////////
    /////////////////////////////////////

    /* Getters */

    // get name
    function getName() public view returns (string memory) {
        return name;
    }

    // get symbol
    function getSymbol() public view returns (string memory) {
        return symbol;
    }

    // get contract version
    function getContractVersion() public view returns (uint256) {
        // return version
        return _contractVersion;
    }

    // get the TokenID counter
    function getTokenIDCounter() public view returns (uint256) {
        return tokenIdCounter;
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    ////   Standard ERC1155 Functions    ////

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(
            to != address(0),
            "SegMint ERC1155: transfer to the zero address"
        );

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = SegMintERC1155DB.getBalanceOf(id, from); // _balances[id][from];
        // require(
        //     fromBalance >= amount,
        //     "ERC1155: insufficient balance for transfer"
        // );
        // require owner have sufficient balance
        SegMintERC1155DB.HaveSufficientUnlockedBalance(id, from, amount);

        unchecked {
            SegMintERC1155DB.setTokenIDBalance(id, from, fromBalance - amount);
            // _balances[id][from] = fromBalance - amount;
        }
        SegMintERC1155DB.setTokenIDBalance(
            id,
            to,
            SegMintERC1155DB.getBalanceOf(id, to) + amount
        );
        // _balances[id][to] += amount;

        // update onwer of the TokenID
        SegMintERC1155DB.appendToHolders(id, to);

        // remove from address if balance is 0
        if (SegMintERC1155DB.getBalanceOf(id, to) == 0) {
            SegMintERC1155DB.removeFromHolders(id, from);
        }

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "SegMint ERC1155: mint to the zero address");

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        SegMintERC1155DB.setTokenIDBalance(
            id,
            to,
            SegMintERC1155DB.getBalanceOf(id, to) + amount
        );
        SegMintERC1155DB.increaseTokenIDTotalSupply(id, amount);
        // _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(
            from != address(0),
            "SegMint ERC1155: burn from the zero address"
        );

        address operator = msg.sender;
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = SegMintERC1155DB.getBalanceOf(id, from); // _balances[id][from];
        require(
            fromBalance >= amount,
            "SegMint ERC1155: burn amount exceeds balance"
        );
        unchecked {
            SegMintERC1155DB.setTokenIDBalance(
                id,
                from,
                SegMintERC1155DB.getBalanceOf(id, from) - amount
            );
            SegMintERC1155DB.decreaseTokenIDTotalSupply(id, amount);
            // _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */

    function beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual onlyNotGlobalFreeze onlyNotAccountFreeze(from, to) {
        for (uint256 i = 0; i < ids.length; i++) {
            _isAccountTokenIDAllowed(from, to, ids[i]);
        }

        // just to avoid compiler warning
        beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _isAccountTokenIDAllowed(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        onlyNotAccountTokenIDFreeze(from, to, tokenId)
        onlyNotGlobalTokenIDFreeze(tokenId)
    {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
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
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}