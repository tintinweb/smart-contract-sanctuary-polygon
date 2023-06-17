/**
 *Submitted for verification at polygonscan.com on 2023-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
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


interface ISegMintERC721 {

    function approveStaker(address approveStakerAddress, uint256 tokenId) external returns (bool);
    function stakerOf(uint256 tokenId) external view returns (address);
    function stakingStartDate(uint256 tokenId) external view returns (uint256);
    function stakingEndDate(uint256 tokenId) external view returns (uint256);
    function getApprovedStaker(uint256 tokenId) external view returns (address);
    function renounceApprovedStaker(uint256 tokenId) external returns (bool);
    function approveFractioner(address approveFractionerAddress, uint256 tokenId) external returns (bool);
    function fractionerOf(uint256 tokenId) external view returns (address);
    function getApprovedFractioner(uint256 tokenId) external view returns (address);
    function renounceApprovedFractioner(uint256 tokenId) external returns (bool);
    function getFractionerAddress(uint256 tokenId) external view returns (address);
    function getFractionedDate(uint256 tokenId) external view returns (uint256);
    function stakerLock(uint256 tokenId, uint256 endDate) external returns (bool);
    function stakerUnlock(uint256 tokenId) external returns (bool);
    function fractionerLock(uint256 tokenId) external returns (bool);
    function fractionerUnlock(uint256 tokenId) external returns (bool);
    function fractionerUnlockAndTransfer(uint256 tokenId, address _transferToAddress) external returns (bool);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

}
// SegMint Lockable ERC721
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, ISegMintERC721 {
    ////////////////////
    ////   Fields   ////
    ////////////////////

    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;

    // TokenId
    Counters.Counter private _tokenIds;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURIextended;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

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

    // Mapping from token ID to staker address (stakers can lock)
    mapping(uint256 => STAKINGINFO) private _stakers;

    // Mapping from token ID to approved Stakers address
    mapping(uint256 => address) private _stakersApprovals;

    // Mapping from token ID to approved for all Stakers address
    // mapping(address => mapping(address => bool)) private _stakersApprovalForAll;

    // Mapping from token ID to fractioner address (fractioner can lock/unlock and transfer)
    mapping(uint256 => FRACTIONINGINFO) private _fractioners;

    // Mapping from token ID to approved fractioners address
    mapping(uint256 => address) private _fractionersApprovals;

    // Mapping from token ID to approved for fractioners address
    // mapping(address => mapping(address => bool)) private _fractionersApprovalForAll;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 tokenNumber_,
        string memory tokenUrl_
    ) {
        _name = name_;
        _symbol = symbol_;
        for (uint256 i = 0; i < tokenNumber_; i++) {
            safeMint(_msgSender(), tokenUrl_);
        }
    }

    ////////////////////
    ////   Events   ////
    ////////////////////

    // Staking events //
    event ApproveStakerEvent(
        address sender,
        address approvedStakerAddress,
        uint256 tokenId
    );

    // event ApprovalForAllStakerEvent(address sender, address approveForAllStakerAddress, bool approved);

    event StartStakingEvent(address sender, uint256 tokenId);

    event EndStakingEvent(address sender, uint256 tokenId);

    // Fractioning events //
    event ApproveFractionerEvent(
        address sender,
        address approvedFractionerAddress,
        uint256 tokenId
    );

    // event ApprovalForAllFractionerEvent(address sender, address approveForAllFractionerAddress, bool approved);

    event FractionerLockEvent(address sender, uint256 tokenId);

    event FractionerUnlockEvent(address sender, uint256 tokenId);

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // Modifier to check that the caller is the owner wallet address.
    modifier onlyOwner(uint256 tokenId) {
        require(_msgSender() == _owners[tokenId], "Not owner!");
        _;
    }

    // Modifier to check that the caller is the staker .
    modifier onlyStaker(uint256 tokenId) {
        require(_msgSender() == _stakerOf(tokenId), "Not staker!");
        _;
    }

    // Modifier to check that the caller is the fractioner .
    modifier onlyFractioner(uint256 tokenId) {
        require(_msgSender() == _fractionerOf(tokenId), "Not fractioner!");
        _;
    }

    // Modifier to check that the caller is the approved staker .
    modifier onlyApprovedStaker(uint256 tokenId) {
        require(
            _msgSender() == _stakersApprovals[tokenId],
            "Not approved staker!"
        );
        _;
    }

    // Modifier to check that the caller is the approved fractioner .
    modifier onlyApprovedFractioner(uint256 tokenId) {
        require(
            _msgSender() == _fractionersApprovals[tokenId],
            "Not approved fractioner!"
        );
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    ////    Staking Specific TokenID   ////

    function approveStaker(address approveStakerAddress, uint256 tokenId)
        public
        returns (bool)
    {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // require approveStakerAddress not be 0 address
        require(
            approveStakerAddress != address(0),
            "Cannot approve address(0)"
        );

        // require sender be the owner/approved/operator
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Sender is not owner, approved, or operator"
        );

        // require not staked
        _requireNotStaked(tokenId);

        // require not fractioned
        _requireNotFractioned(tokenId);

        // approveStakerAddress should not be the current owner/approved/operator
        require(
            _msgSender() != approveStakerAddress,
            "ERC721: staker approval to owner, approved, or operator"
        );

        // address of the approved staker
        address currentApprovedStaker = _stakersApprovals[tokenId];

        // address of current approved staker should be address(0)
        require(
            currentApprovedStaker == address(0),
            "TokenId is currently approved for a staker"
        );

        // address of the approved fractioner
        address currentApprovedFractioner = _fractionersApprovals[tokenId];

        // require address of current approved fractioner be address(0)
        require(
            currentApprovedFractioner == address(0),
            "TokenId is currently approved for a fractioner"
        );

        // update approved staker address
        _approveStaker(_msgSender(), approveStakerAddress, tokenId);

        // return
        return true;
    }

    function stakerOf(uint256 tokenId) public view virtual returns (address) {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // address of tokenId  staker
        address staker = _stakerOf(tokenId);

        // return staker
        return staker;
    }

    function stakingStartDate(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // start Date of staking
        uint256 StartDate = _stakingStartDate(tokenId);

        // return
        return StartDate;
    }

    function stakingEndDate(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // end Date of staking
        uint256 EndDate = _stakingEndDate(tokenId);

        // return
        return EndDate;
    }

    function getApprovedStaker(uint256 tokenId)
        public
        view
        virtual
        returns (address)
    {
        // require tokenId be minted.
        _requireMinted(tokenId);

        return _stakersApprovals[tokenId];
    }

    function renounceApprovedStaker(uint256 tokenId) public returns (bool) {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // require sender be the owner/approved/operator
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Sender is not the owner, approved, or operator"
        );

        // require approved staker != address(0)
        require(
            _stakersApprovals[tokenId] != address(0),
            "No address is approved staker!"
        );

        // require not staked
        _requireNotStaked(tokenId);

        // require not fractioned
        _requireNotFractioned(tokenId);

        // update approved staker address to address(0) ==> renouncing
        _approveStaker(_msgSender(), address(0), tokenId);

        // return
        return true;
    }

    ////    Fractioner Locking Specific TokenID   ////

    function approveFractioner(
        address approveFractionerAddress,
        uint256 tokenId
    ) public returns (bool) {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // require approveFractionerAddress not be 0 address
        require(
            approveFractionerAddress != address(0),
            "Cannot approve address(0)"
        );

        // require sender be the owner/approved/operator
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Sender is not the owner, approved, or operator"
        );

        // require not fractioned
        _requireNotFractioned(tokenId);

        // require not staked
        _requireNotStaked(tokenId);

        // approveFractionerAddress should not be the current owner
        require(
            _msgSender() != approveFractionerAddress,
            "ERC721: fractioner approval to owner, approved, or operator"
        );

        // address of the approved staker
        address currentApprovedStaker = _stakersApprovals[tokenId];

        // require currentApprovedStaker not be securedly approved
        require(
            currentApprovedStaker == address(0),
            "TokenId is already approved for a staker"
        );

        // address of the approved fractioner
        address currentApprovedFractioner = _fractionersApprovals[tokenId];

        // require approveFractionerAddress not be approved
        require(
            currentApprovedFractioner == address(0),
            "TokenId is already approved for a fractioner"
        );

        // update approved fractioner address
        _approveFractioner(_msgSender(), approveFractionerAddress, tokenId);

        // return
        return true;
    }

    function fractionerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address)
    {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // address of tokenId locker
        address fractioner = _fractionerOf(tokenId);

        // return locker
        return fractioner;
    }

    function getApprovedFractioner(uint256 tokenId)
        public
        view
        virtual
        returns (address)
    {
        // require tokenId be minted.
        _requireMinted(tokenId);

        return _fractionersApprovals[tokenId];
    }

    function renounceApprovedFractioner(uint256 tokenId) public returns (bool) {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // require approved fractioner != address(0)
        require(
            _fractionersApprovals[tokenId] != address(0),
            "No address is approved for fractioning!"
        );

        // require sender be the owner, approved, or operator
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Sender is not the owner, approved, or operator"
        );

        // require not staked
        _requireNotStaked(tokenId);

        // require not fractioned
        _requireNotFractioned(tokenId);

        // update approved fractioner address
        _approveFractioner(_msgSender(), address(0), tokenId);

        // return
        return true;
    }

    // get fractioner address
    function getFractionerAddress(uint256 tokenId)
        public
        view
        returns (address)
    {
        return _fractioners[tokenId].fractionerAddress;
    }

    // get fractioned date
    function getFractionedDate(uint256 tokenId) public view returns (uint256) {
        return _fractioners[tokenId].fractionedDate;
    }

    ////    Staking tokenId   ////

    function stakerLock(uint256 tokenId, uint256 endDate)
        public
        returns (bool)
    {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // require not staked
        _requireNotStaked(tokenId);

        // require not fractioned
        _requireNotFractioned(tokenId);

        // require sender be an approved staker for the tokenId
        require(
            _msgSender() == getApprovedStaker(tokenId),
            "Sender is not approved as a staker"
        );

        // update _stakers
        _stakers[tokenId].stakerAddress = _msgSender();
        _stakers[tokenId].stakingStartDate = block.timestamp;
        _stakers[tokenId].stakingEndDate = uint256(endDate);

        // update approvedStaker to address(0)
        _stakersApprovals[tokenId] = address(0);

        // emit event
        emit StartStakingEvent(_msgSender(), tokenId);

        // return
        return true;
    }

    function stakerUnlock(uint256 tokenId) public returns (bool) {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // require NFT be staked
        require(_stakerOf(tokenId) != address(0), "NFT is not staked!");

        // before end date only staker can unstake and
        // afeter end date owner/approved/operator can unstake
        if (_stakers[tokenId].stakingEndDate <= block.timestamp) {
            // require sender be the owner, approved, or operator
            require(
                _isApprovedOrOwner(_msgSender(), tokenId) ||
                    _msgSender() == _stakerOf(tokenId),
                "Sender is not the owner, approved, or operator"
            );
        } else {
            // require sender be the staker for the tokenId
            require(
                _msgSender() == _stakerOf(tokenId),
                "Sender is not the staker"
            );
        }

        // update staking info
        _stakers[tokenId].stakerAddress = address(0);
        _stakers[tokenId].stakingStartDate = 0;
        _stakers[tokenId].stakingEndDate = 0;

        // emit event
        emit EndStakingEvent(_msgSender(), tokenId);

        // return
        return true;
    }

    ////    fractioner Lock/Unlock tokenId     ////
    function fractionerLock(uint256 tokenId) public returns (bool) {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // require not staked
        _requireNotStaked(tokenId);

        // require not fractioned
        _requireNotFractioned(tokenId);

        // require sender be a fractioner approved for the tokenId
        require(
            _msgSender() == getApprovedFractioner(tokenId),
            "Sender is not approved as an fractioner"
        );

        // update _fractioner
        // _fractioners[tokenId] = _msgSender();
        _fractioners[tokenId].fractionerAddress = msg.sender;
        _fractioners[tokenId].fractionedDate = block.timestamp;

        // update approvedFractioner to address(0)
        _fractionersApprovals[tokenId] = address(0);

        // emit event
        emit FractionerLockEvent(_msgSender(), tokenId);

        // return
        return true;
    }

    function fractionerUnlock(uint256 tokenId) public returns (bool) {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // require fractioned
        require(
            _fractionerOf(tokenId) != address(0),
            "TokenId is not fractioned!"
        );

        // require sender be the fractioner for the tokenId
        require(
            _msgSender() == _fractionerOf(tokenId),
            "Sender is not the fractioner"
        );

        // update fractioner to address(0)
        _fractioners[tokenId].fractionerAddress = address(0);
        _fractioners[tokenId].fractionedDate = 0;

        // emit event
        emit FractionerUnlockEvent(_msgSender(), tokenId);

        // return
        return true;
    }

    function fractionerUnlockAndTransfer(
        uint256 tokenId,
        address _transferToAddress
    ) public returns (bool) {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // require fractioned
        require(
            _fractionerOf(tokenId) != address(0),
            "TokenId is not fractioned!"
        );

        // require sender be the fractioner for the tokenId
        require(
            _msgSender() == _fractionerOf(tokenId),
            "Sender is not the fractioner"
        );

        // update fractioner to address(0)
        _fractioners[tokenId].fractionerAddress = address(0);
        _fractioners[tokenId].fractionedDate = 0;

        // transfer tokenId to an address
        ERC721._transfer(_ownerOf(tokenId), _transferToAddress, tokenId);

        // emit event
        emit FractionerUnlockEvent(_msgSender(), tokenId);

        // return
        return true;
    }

    // ////    Staking/Fractioning Approval For All TokenIDs    ////

    // function setApprovalForAllStaker(address approveForAllStakerAddress, bool approved) public virtual {
    //     _setApprovalForAllStaker(_msgSender(), approveForAllStakerAddress, approved);
    // }

    // function isApprovedForAllStaker(address owner, address staker) public view virtual returns (bool) {
    //     return _stakersApprovalForAll[owner][staker];
    // }

    // function setApprovalForAllFractioner(address approveForAllFractionerAddress, bool approved) public virtual {
    //     _setApprovalForAllFractioner(_msgSender(), approveForAllFractionerAddress, approved);
    // }

    // function isApprovedForAllFractioner(address owner, address fractioner) public view virtual returns (bool) {
    //     return _fractionersApprovalForAll[owner][fractioner];
    // }

    ////    NFT public functions    ////

    function safeMint(address to, string memory TokenURI) public {
        //  tokenId
        uint256 TokenID = _tokenIds.current();

        // increment tokenId
        _tokenIds.increment();

        // safe mint
        _safeMint(to, TokenID);

        //set token URI
        _setTokenURI(TokenID, TokenURI);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165, ISegMintERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner)
        public
        view
        virtual
        override(IERC721, ISegMintERC721)
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override(IERC721, ISegMintERC721)
        returns (address)
    {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function approve(address to, uint256 tokenId) public virtual override(IERC721, ISegMintERC721)
 {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override(IERC721, ISegMintERC721)
        returns (address)
    {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override(IERC721, ISegMintERC721)
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(IERC721, ISegMintERC721)
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(IERC721, ISegMintERC721) {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // require not staked
        _requireNotStaked(tokenId);

        // require not fractioned
        _requireNotFractioned(tokenId);

        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

        _transfer(from, to, tokenId);

        // reset staker and fractioner to address(0)
        _stakersApprovals[tokenId] = address(0);
        _fractionersApprovals[tokenId] = address(0);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(IERC721, ISegMintERC721) {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // require not staked
        _requireNotStaked(tokenId);

        // require not fractioned
        _requireNotFractioned(tokenId);

        // safe transfer
        safeTransferFrom(from, to, tokenId, "");

        // reset staker and fractioner to address(0)
        _stakersApprovals[tokenId] = address(0);
        _fractionersApprovals[tokenId] = address(0);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // require not staked
        _requireNotStaked(tokenId);

        // require not fractioned
        _requireNotFractioned(tokenId);

        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _safeTransfer(from, to, tokenId, data);

        // reset staker and fractioner to address(0)
        _stakersApprovals[tokenId] = address(0);
        _fractionersApprovals[tokenId] = address(0);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(IERC721Metadata, ISegMintERC721)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function isSegMintERC721() public pure returns (bool) {
        return true;
    }

    ////////////////////////////////
    ////   Internal Functions   ////
    ////////////////////////////////

    function _requireNotStaked(uint256 tokenId) internal view virtual {
        require(_stakerOf(tokenId) == address(0), "TokenId is staked");
    }

    function _requireNotFractioned(uint256 tokenId) internal view virtual {
        require(
            _fractionerOf(tokenId) == address(0),
            "TokenId is locked by fractioner"
        );
    }

    function _requireNotMinted(uint256 tokenId) internal view virtual {
        require(!_exists(tokenId), "ERC721: TokenId already minted");
    }

    function _approveStaker(
        address sender,
        address approveStakerAddress,
        uint256 tokenId
    ) internal virtual {
        // update approved staker
        _stakersApprovals[tokenId] = approveStakerAddress;

        // emit
        emit ApproveStakerEvent(sender, approveStakerAddress, tokenId);
    }

    // function _setApprovalForAllStaker(address owner, address approveForAllStakerAddress, bool approved) internal virtual {

    //     // do not allow owner to be the address approved for all staker
    //     require(owner != approveForAllStakerAddress, "ERC721: cannot approve to owner to be the approved for all staker");

    //     // update approval
    //     _stakersApprovalForAll[owner][approveForAllStakerAddress] = approved;

    //     // emit event
    //     emit ApprovalForAllStakerEvent(owner, approveForAllStakerAddress, approved);
    // }

    function _stakerOf(uint256 tokenId)
        internal
        view
        virtual
        returns (address)
    {
        return _stakers[tokenId].stakerAddress;
    }

    function _stakingStartDate(uint256 tokenId)
        internal
        view
        virtual
        returns (uint256)
    {
        return _stakers[tokenId].stakingStartDate;
    }

    function _stakingEndDate(uint256 tokenId)
        internal
        view
        virtual
        returns (uint256)
    {
        return _stakers[tokenId].stakingEndDate;
    }

    function _approveFractioner(
        address sender,
        address approveFractionerAddress,
        uint256 tokenId
    ) internal virtual {
        // update approved fractioner
        _fractionersApprovals[tokenId] = approveFractionerAddress;

        // emit
        emit ApproveFractionerEvent(sender, approveFractionerAddress, tokenId);
    }

    // function _setApprovalForAllFractioner(address owner, address approveForAllFractionerAddress, bool approved) internal virtual {

    //     // do not allow owner to be the address approved for all fractioner
    //     require(owner != approveForAllFractionerAddress, "ERC721: cannot approve to owner to be the approved for all fractioner");

    //     // update approval
    //     _fractionersApprovalForAll[owner][approveForAllFractionerAddress] = approved;

    //     // emit event
    //     emit ApprovalForAllFractionerEvent(owner, approveForAllFractionerAddress, approved);
    // }

    function _fractionerOf(uint256 tokenId)
        internal
        view
        virtual
        returns (address)
    {
        return _fractioners[tokenId].fractionerAddress;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return _baseURIextended;
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        // require tokenId be minted.
        _requireMinted(tokenId);

        // require not staked
        _requireNotStaked(tokenId);

        // require not fractioned
        _requireNotFractioned(tokenId);

        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _beforeConsecutiveTokenTransfer(
        address from,
        address to,
        uint256, /*first*/
        uint96 size
    ) internal virtual {
        if (from != address(0)) {
            _balances[from] -= size;
        }
        if (to != address(0)) {
            _balances[to] += size;
        }
    }

    function _afterConsecutiveTokenTransfer(
        address, /*from*/
        address, /*to*/
        uint256, /*first*/
        uint96 /*size*/
    ) internal virtual {}

    ///////////////////////////////
    ////   Private Functions   ////
    ///////////////////////////////

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}


contract SegMint_ERC721_Factory {
    ////////////////////
    ////   Fields   ////
    ////////////////////

    // SegMint Factory Owner Address
    address private _owner;

    // status check if an address is SegMint ERC721 or not.
    mapping(address => bool) private _isSegMintERC721;

    // Mapping to store the addresses of deployed SegMint ERC721 contracts
    mapping(address => address[]) private _deployedSegMintERC721ByDeployer;

    // list of All deployed SegMint ERC721
    address[] private _deployedSegMintERC721List;

    // list of all restricted SegMint ERC721 addresses
    address[] private _restrictedDeployedSegMintERC721List;

    /////////////////////////
    ////   Constructor   ////
    /////////////////////////

    // constructor
    constructor(){
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

    // Event to log the deployment of a SegMint ERC721 contract
    event SegMintERC721Deployed(
        address indexed deployer, 
        address indexed deployed,
        uint256 indexed timestamp
    );

    // restrict SegMint ERC721 Address
    event restrictSegMintERC721AddressEvent(
        address indexed ownerAddress,
        address indexed SegMintERC721Address,
        uint256 indexed timestamp
    );

    event AddSegMintERC721AddressEvent(
        address indexed ownerAddress,
        address indexed SegMintERC721Address,
        uint256 indexed timestamp
    );

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
     * Function to deploy a SegMint ERC721 contract
     *
     * @param name_ the name of the token
     * @param symbol_ the symbol of the token
     * @param tokenNumber_ the number of tokens
     * @param tokenUrl_ the URL of the token
     */
    
    function deploySegMintERC721(
        string memory name_,
        string memory symbol_,
        uint256 tokenNumber_,
        string memory tokenUrl_) external {

        // Deploy the SegMint ERC721 contract and store its address
        address deployedAddress = address(new ERC721(name_, symbol_, tokenNumber_, tokenUrl_));
        
        // add deployed contract to list of SegMintERC721 deployed by an Deployer
        _deployedSegMintERC721ByDeployer[msg.sender] .push(deployedAddress);

        // udpate is SegMint ERC721
        _isSegMintERC721[deployedAddress] = true;

        // add deployed contract to all deployed SegMint ERC721 list
        _deployedSegMintERC721List.push(deployedAddress);

        // Log the deployment of the SegMint ERC721 contract
        emit SegMintERC721Deployed(
            msg.sender, 
            deployedAddress,
            block.timestamp
        );
    }

    /*
     * Function to restrict a SegMint ERC721 Contract Address
     * @params SegMintERC721Address the address of contract to be restricted
     */
    
    function restrictSegMintERC721Address(address SegMintERC721Address_) public onlyOwner {
        
        // require address be a SegMint ERC721
        require(
            isSegmintERC721(SegMintERC721Address_),
            "SegMint ERC721 Factory: Address is not a SegMint ERC721 Contract!"
        );

        // update is SegMint ERC721
        _isSegMintERC721[SegMintERC721Address_] = false;

        // remove from SegMint ERC721 list
        _removeAddressFromSegMintERC721(SegMintERC721Address_);

        // add to restricted SegMint ERC721
        _restrictedDeployedSegMintERC721List.push(SegMintERC721Address_);

        // emit event
        emit restrictSegMintERC721AddressEvent(
            msg.sender,
            SegMintERC721Address_,
            block.timestamp
        );

    }

    /*
     * Function to manually add or unrestrict an address to SegMint ERC721 List
     * @params SegMintERC721Address the address of contract to be added
     */
    function AddOrUnrestrictSegMintERC721Address(address SegMintERC721Address_) public onlyOwner {

        // require address not be in the SegMint ERC721 list
        require(
            ! isSegmintERC721(SegMintERC721Address_),
            "SegMint ERC721 Factory: Address is already in SegMint"
        );

        // udpate is SegMint ERC721
        _isSegMintERC721[SegMintERC721Address_] = true;

        // add contract address to all deployed SegMint ERC721 list
        _deployedSegMintERC721List.push(SegMintERC721Address_);

        // emit event
        emit AddSegMintERC721AddressEvent(
            msg.sender,
            SegMintERC721Address_,
            block.timestamp
        );
    }

    /**
     * Function to get the address of a deployed SegMint ERC721 contract
     *
     * @param deployer - the address of the deployer
     * @return the addresses of the deployed SegMint ERC721 contract
     */
    
    function getSegMintERC721DeployedAddressByDeployer(address deployer) public view returns (address[] memory) {
        return _deployedSegMintERC721ByDeployer[deployer];
    }

    /**
     * Function to check if an addresss is SegMint ERC721 contract
     *
     * @dev Returns a boolean indicating whether the specified contract address is registered as a Segmint NFT ERC721 contract.
     * @param contractAddress The address of the contract to check.
     * @return A boolean value indicating whether the specified contract address is registered as a Segmint NFT ERC721 contract.
    */

    function isSegmintERC721(address contractAddress) public view returns(bool) {
        return _isSegMintERC721[contractAddress];
    }

    ////////////////////////////////
    ////   Internal Functions   ////
    ////////////////////////////////

    /*
     * Internal Function to remove Address from SegMint ERC721 List
     * @params SegMintERC721Address_ the contract address to be removed
     */

    function _removeAddressFromSegMintERC721(address SegMintERC721Address_) internal {
        if (_isSegMintERC721[SegMintERC721Address_]) {
            for (uint256 i = 0; i < _deployedSegMintERC721List.length; i++) {
                if (_deployedSegMintERC721List[i] == SegMintERC721Address_) {
                    _deployedSegMintERC721List[i] = _deployedSegMintERC721List[
                        _deployedSegMintERC721List.length - 1
                    ];
                    _deployedSegMintERC721List.pop();
                    // update status
                    _isSegMintERC721[SegMintERC721Address_] = false;
                    break;
                }
            }
        }
    }
}