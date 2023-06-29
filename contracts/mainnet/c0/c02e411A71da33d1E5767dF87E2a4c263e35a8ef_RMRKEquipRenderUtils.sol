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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Context.sol";
import "../library/RMRKErrors.sol";

/**
 * @title Ownable
 * @author RMRK team
 * @notice A minimal ownable smart contractf or owner and contributors.
 * @dev This smart contract is based on "openzeppelin's access/Ownable.sol".
 */
contract Ownable is Context {
    address private _owner;
    mapping(address => uint256) private _contributors;

    /**
     * @notice Used to anounce the transfer of ownership.
     * @param previousOwner Address of the account that transferred their ownership role
     * @param newOwner Address of the account receiving the ownership role
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice Event that signifies that an address was granted contributor role or that the permission has been
     *  revoked.
     * @dev This can only be triggered by a current owner, so there is no need to include that information in the event.
     * @param contributor Address of the account that had contributor role status updated
     * @param isContributor A boolean value signifying whether the role has been granted (`true`) or revoked (`false`)
     */
    event ContributorUpdate(address indexed contributor, bool isContributor);

    /**
     * @dev Reverts if called by any account other than the owner or an approved contributor.
     */
    modifier onlyOwnerOrContributor() {
        _onlyOwnerOrContributor();
        _;
    }

    /**
     * @dev Reverts if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @dev Initializes the contract by setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @notice Returns the address of the current owner.
     * @return Address of the current owner
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Leaves the contract without owner. Functions using the `onlyOwner` modifier will be disabled.
     * @dev Can only be called by the current owner.
     * @dev Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is
     *  only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice Transfers ownership of the contract to a new owner.
     * @dev Can only be called by the current owner.
     * @param newOwner Address of the new owner's account
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert RMRKNewOwnerIsZeroAddress();
        _transferOwnership(newOwner);
    }

    /**
     * @notice Transfers ownership of the contract to a new owner.
     * @dev Internal function without access restriction.
     * @dev Emits ***OwnershipTransferred*** event.
     * @param newOwner Address of the new owner's account
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @notice Adds or removes a contributor to the smart contract.
     * @dev Can only be called by the owner.
     * @dev Emits ***ContributorUpdate*** event.
     * @param contributor Address of the contributor's account
     * @param grantRole A boolean value signifying whether the contributor role is being granted (`true`) or revoked
     *  (`false`)
     */
    function manageContributor(
        address contributor,
        bool grantRole
    ) external onlyOwner {
        if (contributor == address(0)) revert RMRKNewContributorIsZeroAddress();
        grantRole
            ? _contributors[contributor] = 1
            : _contributors[contributor] = 0;
        emit ContributorUpdate(contributor, grantRole);
    }

    /**
     * @notice Used to check if the address is one of the contributors.
     * @param contributor Address of the contributor whose status we are checking
     * @return Boolean value indicating whether the address is a contributor or not
     */
    function isContributor(address contributor) public view returns (bool) {
        return _contributors[contributor] == 1;
    }

    /**
     * @notice Used to verify that the caller is either the owner or a contributor.
     * @dev If the caller is not the owner or a contributor, the execution will be reverted.
     */
    function _onlyOwnerOrContributor() private view {
        if (owner() != _msgSender() && !isContributor(_msgSender()))
            revert RMRKNotOwnerOrContributor();
    }

    /**
     * @notice Used to verify that the caller is the owner.
     * @dev If the caller is not the owner, the execution will be reverted.
     */
    function _onlyOwner() private view {
        if (owner() != _msgSender()) revert RMRKNotOwner();
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "./Ownable.sol";
import "../library/RMRKErrors.sol";

/**
 * @title OwnableLock
 * @author RMRK team
 * @notice A minimal ownable lock smart contract.
 */
contract OwnableLock is Ownable {
    uint256 private _lock;

    /**
     * @notice Emitted when the smart contract is locked.
     */
    event LockSet();

    /**
     * @notice Reverts if the lock flag is set to true.
     */
    modifier notLocked() {
        _onlyNotLocked();
        _;
    }

    /**
     * @notice Locks the operation.
     * @dev Once locked, functions using `notLocked` modifier cannot be executed.
     * @dev Emits ***LockSet*** event.
     */
    function setLock() public virtual onlyOwner {
        _lock = 1;
        emit LockSet();
    }

    /**
     * @notice Used to retrieve the status of a lockable smart contract.
     * @return A boolean value signifying whether the smart contract has been locked
     */
    function getLock() public view returns (bool) {
        return _lock == 1;
    }

    /**
     * @notice Used to verify that the operation of the smart contract is not locked.
     * @dev If the operation of the smart contract is locked, the execution will be reverted.
     */
    function _onlyNotLocked() private view {
        if (_lock == 1) revert RMRKLocked();
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IRMRKCatalog
 * @author RMRK team
 * @notice An interface Catalog for RMRK equippable module.
 */
interface IRMRKCatalog is IERC165 {
    /**
     * @notice Event to announce addition of a new part.
     * @dev It is emitted when a new part is added.
     * @param partId ID of the part that was added
     * @param itemType Enum value specifying whether the part is `None`, `Slot` and `Fixed`
     * @param zIndex An uint specifying the z value of the part. It is used to specify the depth which the part should
     *  be rendered at
     * @param equippableAddresses An array of addresses that can equip this part
     * @param metadataURI The metadata URI of the part
     */
    event AddedPart(
        uint64 indexed partId,
        ItemType indexed itemType,
        uint8 zIndex,
        address[] equippableAddresses,
        string metadataURI
    );

    /**
     * @notice Event to announce new equippables to the part.
     * @dev It is emitted when new addresses are marked as equippable for `partId`.
     * @param partId ID of the part that had new equippable addresses added
     * @param equippableAddresses An array of the new addresses that can equip this part
     */
    event AddedEquippables(
        uint64 indexed partId,
        address[] equippableAddresses
    );

    /**
     * @notice Event to announce the overriding of equippable addresses of the part.
     * @dev It is emitted when the existing list of addresses marked as equippable for `partId` is overwritten by a new one.
     * @param partId ID of the part whose list of equippable addresses was overwritten
     * @param equippableAddresses The new, full, list of addresses that can equip this part
     */
    event SetEquippables(uint64 indexed partId, address[] equippableAddresses);

    /**
     * @notice Event to announce that a given part can be equipped by any address.
     * @dev It is emitted when a given part is marked as equippable by any.
     * @param partId ID of the part marked as equippable by any address
     */
    event SetEquippableToAll(uint64 indexed partId);

    /**
     * @notice Used to define a type of the item. Possible values are `None`, `Slot` or `Fixed`.
     * @dev Used for fixed and slot parts.
     */
    enum ItemType {
        None,
        Slot,
        Fixed
    }

    /**
     * @notice The integral structure of a standard RMRK catalog item defining it.
     * @dev Requires a minimum of 3 storage slots per catalog item, equivalent to roughly 60,000 gas as of Berlin hard
     *  fork (April 14, 2021), though 5-7 storage slots is more realistic, given the standard length of an IPFS URI.
     *  This will result in between 25,000,000 and 35,000,000 gas per 250 assets--the maximum block size of Ethereum
     *  mainnet is 30M at peak usage.
     * @return itemType The item type of the part
     * @return z The z value of the part defining how it should be rendered when presenting the full NFT
     * @return equippable The array of addresses allowed to be equipped in this part
     * @return metadataURI The metadata URI of the part
     */
    struct Part {
        ItemType itemType; //1 byte
        uint8 z; //1 byte
        address[] equippable; //n Collections that can be equipped into this slot
        string metadataURI; //n bytes 32+
    }

    /**
     * @notice The structure used to add a new `Part`.
     * @dev The part is added with specified ID, so you have to make sure that you are using an unused `partId`,
     *  otherwise the addition of the part vill be reverted.
     * @dev The full `IntakeStruct` looks like this:
     *  [
     *          partID,
     *      [
     *          itemType,
     *          z,
     *          [
     *               permittedCollectionAddress0,
     *               permittedCollectionAddress1,
     *               permittedCollectionAddress2
     *           ],
     *           metadataURI
     *       ]
     *   ]
     * @return partId ID to be assigned to the `Part`
     * @return part A `Part` to be added
     */
    struct IntakeStruct {
        uint64 partId;
        Part part;
    }

    /**
     * @notice Used to return the metadata URI of the associated Catalog.
     * @return Catalog metadata URI
     */
    function getMetadataURI() external view returns (string memory);

    /**
     * @notice Used to return the `itemType` of the associated Catalog
     * @return `itemType` of the associated Catalog
     */
    function getType() external view returns (string memory);

    /**
     * @notice Used to check whether the given address is allowed to equip the desired `Part`.
     * @dev Returns true if a collection may equip asset with `partId`.
     * @param partId The ID of the part that we are checking
     * @param targetAddress The address that we are checking for whether the part can be equipped into it or not
     * @return The status indicating whether the `targetAddress` can be equipped into `Part` with `partId` or not
     */
    function checkIsEquippable(
        uint64 partId,
        address targetAddress
    ) external view returns (bool);

    /**
     * @notice Used to check if the part is equippable by all addresses.
     * @dev Returns true if part is equippable to all.
     * @param partId ID of the part that we are checking
     * @return The status indicating whether the part with `partId` can be equipped by any address or not
     */
    function checkIsEquippableToAll(uint64 partId) external view returns (bool);

    /**
     * @notice Used to retrieve a `Part` with id `partId`
     * @param partId ID of the part that we are retrieving
     * @return The `Part` struct associated with given `partId`
     */
    function getPart(uint64 partId) external view returns (Part memory);

    /**
     * @notice Used to retrieve multiple parts at the same time.
     * @param partIds An array of part IDs that we want to retrieve
     * @return An array of `Part` structs associated with given `partIds`
     */
    function getParts(
        uint64[] memory partIds
    ) external view returns (Part[] memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

/**
 * @title IRMRKCore
 * @author RMRK team
 * @notice Interface smart contract for RMRK core module.
 */
interface IRMRKCore {
    /**
     * @notice Used to retrieve the collection name.
     * @return Name of the collection
     */
    function name() external view returns (string memory);

    /**
     * @notice Used to retrieve the collection symbol.
     * @return Symbol of the collection
     */
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "./IRMRKCore.sol";

/**
 * @title RMRKCore
 * @author RMRK team
 * @notice Smart contract of the RMRK core module.
 * @dev This is currently just a passthrough contract which allows for granular editing of base-level ERC721 functions.
 */
contract RMRKCore is IRMRKCore {
    /**
     * @notice Version of the @rmrk-team/evm-contracts package
     * @return Version identifier of the smart contract
     */
    string public constant VERSION = "1.2.1";
    bytes4 public constant RMRK_INTERFACE = 0x524D524B; // "RMRK" in ASCII hex

    /**
     * @notice Used to initialize the smart contract.
     * @param name_ Name of the token collection
     * @param symbol_ Symbol of the token collection
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /// Token name
    string private _name;

    /// Token symbol
    string private _symbol;

    /**
     * @notice Used to retrieve the collection name.
     * @return Name of the collection
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @notice Used to retrieve the collection symbol.
     * @return Symbol of the collection
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Hook that is called before any token transfer. This includes minting and burning.
     * @dev Calling conditions:
     *
     *  - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be transferred to `to`.
     *  - When `from` is zero, `tokenId` will be minted to `to`.
     *  - When `to` is zero, ``from``'s `tokenId` will be burned.
     *  - `from` and `to` are never zero at the same time.
     *
     *  To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token is being transferred
     * @param to Address to which the token is being transferred
     * @param tokenId ID of the token being transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @notice Hook that is called after any transfer of tokens. This includes minting and burning.
     * @dev Calling conditions:
     *
     *  - When `from` and `to` are both non-zero.
     *  - `from` and `to` are never zero at the same time.
     *
     *  To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token has been transferred
     * @param to Address to which the token has been transferred
     * @param tokenId ID of the token that has been transferred
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "../multiasset/IERC5773.sol";

/**
 * @title IERC6220
 * @author RMRK team
 * @notice Interface smart contract of the RMRK equippable module.
 */
interface IERC6220 is IERC5773 {
    /**
     * @notice Used to store the core structure of the `Equippable` RMRK lego.
     * @return assetId The ID of the asset equipping a child
     * @return childAssetId The ID of the asset used as equipment
     * @return childId The ID of token that is equipped
     * @return childEquippableAddress Address of the collection to which the child asset belongs to
     */
    struct Equipment {
        uint64 assetId;
        uint64 childAssetId;
        uint256 childId;
        address childEquippableAddress;
    }

    /**
     * @notice Used to provide a struct for inputing equip data.
     * @dev Only used for input and not storage of data.
     * @return tokenId ID of the token we are managing
     * @return childIndex Index of a child in the list of token's active children
     * @return assetId ID of the asset that we are equipping into
     * @return slotPartId ID of the slot part that we are using to equip
     * @return childAssetId ID of the asset that we are equipping
     */
    struct IntakeEquip {
        uint256 tokenId;
        uint256 childIndex;
        uint64 assetId;
        uint64 slotPartId;
        uint64 childAssetId;
    }

    /**
     * @notice Used to notify listeners that a child's asset has been equipped into one of its parent assets.
     * @param tokenId ID of the token that had an asset equipped
     * @param assetId ID of the asset associated with the token we are equipping into
     * @param slotPartId ID of the slot we are using to equip
     * @param childId ID of the child token we are equipping into the slot
     * @param childAddress Address of the child token's collection
     * @param childAssetId ID of the asset associated with the token we are equipping
     */
    event ChildAssetEquipped(
        uint256 indexed tokenId,
        uint64 indexed assetId,
        uint64 indexed slotPartId,
        uint256 childId,
        address childAddress,
        uint64 childAssetId
    );

    /**
     * @notice Used to notify listeners that a child's asset has been unequipped from one of its parent assets.
     * @param tokenId ID of the token that had an asset unequipped
     * @param assetId ID of the asset associated with the token we are unequipping out of
     * @param slotPartId ID of the slot we are unequipping from
     * @param childId ID of the token being unequipped
     * @param childAddress Address of the collection that a token that is being unequipped belongs to
     * @param childAssetId ID of the asset associated with the token we are unequipping
     */
    event ChildAssetUnequipped(
        uint256 indexed tokenId,
        uint64 indexed assetId,
        uint64 indexed slotPartId,
        uint256 childId,
        address childAddress,
        uint64 childAssetId
    );

    /**
     * @notice Used to notify listeners that the assets belonging to a `equippableGroupId` have been marked as
     *  equippable into a given slot and parent
     * @param equippableGroupId ID of the equippable group being marked as equippable into the slot associated with
     *  `slotPartId` of the `parentAddress` collection
     * @param slotPartId ID of the slot part of the catalog into which the parts belonging to the equippable group
     *  associated with `equippableGroupId` can be equipped
     * @param parentAddress Address of the collection into which the parts belonging to `equippableGroupId` can be
     *  equipped
     */
    event ValidParentEquippableGroupIdSet(
        uint64 indexed equippableGroupId,
        uint64 indexed slotPartId,
        address parentAddress
    );

    /**
     * @notice Used to equip a child into a token.
     * @dev The `IntakeEquip` stuct contains the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param data An `IntakeEquip` struct specifying the equip data
     */
    function equip(IntakeEquip memory data) external;

    /**
     * @notice Used to unequip child from parent token.
     * @dev This can only be called by the owner of the token or by an account that has been granted permission to
     *  manage the given token by the current owner.
     * @param tokenId ID of the parent from which the child is being unequipped
     * @param assetId ID of the parent's asset that contains the `Slot` into which the child is equipped
     * @param slotPartId ID of the `Slot` from which to unequip the child
     */
    function unequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) external;

    /**
     * @notice Used to check whether the token has a given child equipped.
     * @dev This is used to prevent from transferring a child that is equipped.
     * @param tokenId ID of the parent token for which we are querying for
     * @param childAddress Address of the child token's smart contract
     * @param childId ID of the child token
     * @return A boolean value indicating whether the child token is equipped into the given token or not
     */
    function isChildEquipped(
        uint256 tokenId,
        address childAddress,
        uint256 childId
    ) external view returns (bool);

    /**
     * @notice Used to verify whether a token can be equipped into a given parent's slot.
     * @param parent Address of the parent token's smart contract
     * @param tokenId ID of the token we want to equip
     * @param assetId ID of the asset associated with the token we want to equip
     * @param slotId ID of the slot that we want to equip the token into
     * @return A boolean indicating whether the token with the given asset can be equipped into the desired slot
     */
    function canTokenBeEquippedWithAssetIntoSlot(
        address parent,
        uint256 tokenId,
        uint64 assetId,
        uint64 slotId
    ) external view returns (bool);

    /**
     * @notice Used to get the Equipment object equipped into the specified slot of the desired token.
     * @dev The `Equipment` struct consists of the following data:
     *  [
     *      assetId,
     *      childAssetId,
     *      childId,
     *      childEquippableAddress
     *  ]
     * @param tokenId ID of the token for which we are retrieving the equipped object
     * @param targetCatalogAddress Address of the `Catalog` associated with the `Slot` part of the token
     * @param slotPartId ID of the `Slot` part that we are checking for equipped objects
     * @return The `Equipment` struct containing data about the equipped object
     */
    function getEquipment(
        uint256 tokenId,
        address targetCatalogAddress,
        uint64 slotPartId
    ) external view returns (Equipment memory);

    /**
     * @notice Used to get the asset and equippable data associated with given `assetId`.
     * @param tokenId ID of the token for which to retrieve the asset
     * @param assetId ID of the asset of which we are retrieving
     * @return metadataURI The metadata URI of the asset
     * @return equippableGroupId ID of the equippable group this asset belongs to
     * @return catalogAddress The address of the catalog the part belongs to
     * @return partIds An array of IDs of parts included in the asset
     */
    function getAssetAndEquippableData(
        uint256 tokenId,
        uint64 assetId
    )
        external
        view
        returns (
            string memory metadataURI,
            uint64 equippableGroupId,
            address catalogAddress,
            uint64[] memory partIds
        );
}

// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.18;

import "../catalog/IRMRKCatalog.sol";
import "../library/RMRKLib.sol";
import "../multiasset/AbstractMultiAsset.sol";
import "../nestable/RMRKNestable.sol";
import "../security/ReentrancyGuard.sol";
import "./IERC6220.sol";

/**
 * @title RMRKEquippable
 * @author RMRK team
 * @notice Smart contract of the RMRK Equippable module.
 */
contract RMRKEquippable is
    ReentrancyGuard,
    RMRKNestable,
    AbstractMultiAsset,
    IERC6220
{
    using RMRKLib for uint64[];

    // ------------------- ASSETS --------------

    // ------------------- ASSET APPROVALS --------------

    /**
     * @notice Mapping from token ID to approver address to approved address for assets.
     * @dev The approver is necessary so approvals are invalidated for nested children on transfer.
     * @dev WARNING: If a child NFT returns the original root owner, old permissions would be active again.
     */
    mapping(uint256 => mapping(address => address))
        private _tokenApprovalsForAssets;

    // ------------------- EQUIPPABLE --------------
    /// Mapping of uint64 asset ID to corresponding catalog address.
    mapping(uint64 => address) private _catalogAddresses;
    /// Mapping of uint64 ID to asset object.
    mapping(uint64 => uint64) private _equippableGroupIds;
    /// Mapping of assetId to catalog parts applicable to this asset, both fixed and slot
    mapping(uint64 => uint64[]) private _partIds;

    /// Mapping of token ID to catalog address to slot part ID to equipment information. Used to compose an NFT.
    mapping(uint256 => mapping(address => mapping(uint64 => Equipment)))
        private _equipments;

    /// Mapping of token ID to child (nestable) address to child ID to count of equipped items. Used to check if equipped.
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        private _equipCountPerChild;

    /// Mapping of `equippableGroupId` to parent contract address and valid `slotId`.
    mapping(uint64 => mapping(address => uint64)) private _validParentSlots;

    /**
     * @notice Used to verify that the caller is either the owner of the given token or approved to manage the token's assets
     *  of the owner.
     * @param tokenId ID of the token that we are checking
     */
    function _onlyApprovedForAssetsOrOwner(uint256 tokenId) private view {
        if (!_isApprovedForAssetsOrOwner(_msgSender(), tokenId))
            revert RMRKNotApprovedForAssetsOrOwner();
    }

    /**
     * @notice Used to ensure that the caller is either the owner of the given token or approved to manage the token's assets
     *  of the owner.
     * @dev If that is not the case, the execution of the function will be reverted.
     * @param tokenId ID of the token that we are checking
     */
    modifier onlyApprovedForAssetsOrOwner(uint256 tokenId) {
        _onlyApprovedForAssetsOrOwner(tokenId);
        _;
    }

    // ----------------------------- CONSTRUCTOR ------------------------------

    /**
     * @notice Initializes the contract by setting a `name` and a `symbol` of the token collection.
     * @param name_ Name of the token collection
     * @param symbol_ Symbol of the token collection
     */
    constructor(
        string memory name_,
        string memory symbol_
    ) RMRKNestable(name_, symbol_) {}

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC165, RMRKNestable) returns (bool) {
        return
            RMRKNestable.supportsInterface(interfaceId) ||
            interfaceId == type(IERC5773).interfaceId ||
            interfaceId == type(IERC6220).interfaceId;
    }

    // ------------------------------- ASSETS ------------------------------

    // --------------------------- ASSET HANDLERS -------------------------

    /**
     * @notice Accepts a asset at from the pending array of given token.
     * @dev Migrates the asset from the token's pending asset array to the token's active asset array.
     * @dev Active assets cannot be removed by anyone, but can be replaced by a new asset.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - `index` must be in range of the length of the pending asset array.
     * @dev Emits an {AssetAccepted} event.
     * @param tokenId ID of the token for which to accept the pending asset
     * @param index Index of the asset in the pending array to accept
     * @param assetId ID of the asset that is being accepted
     */
    function acceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _acceptAsset(tokenId, index, assetId);
    }

    /**
     * @notice Rejects a asset from the pending array of given token.
     * @dev Removes the asset from the token's pending asset array.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - `index` must be in range of the length of the pending asset array.
     * @dev Emits a {AssetRejected} event.
     * @param tokenId ID of the token that the asset is being rejected from
     * @param index Index of the asset in the pending array to be rejected
     * @param assetId ID of the asset that is being rejected
     */
    function rejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _rejectAsset(tokenId, index, assetId);
    }

    /**
     * @notice Rejects all assets from the pending array of a given token.
     * @dev Effecitvely deletes the pending array.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     * @dev Emits a {AssetRejected} event with assetId = 0.
     * @param tokenId ID of the token of which to clear the pending array.
     * @param maxRejections Maximum number of expected assets to reject, used to prevent from rejecting assets which
     *  arrive just before this operation.
     */
    function rejectAllAssets(
        uint256 tokenId,
        uint256 maxRejections
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _rejectAllAssets(tokenId, maxRejections);
    }

    /**
     * @notice Sets a new priority array for a given token.
     * @dev The priority array is a non-sequential list of `uint64`s, where the lowest value is considered highest
     *  priority.
     * @dev Value `0` of a priority is a special case equivalent to unitialized.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - The length of `priorities` must be equal the length of the active assets array.
     * @dev Emits a {AssetPrioritySet} event.
     * @param tokenId ID of the token to set the priorities for
     * @param priorities An array of priority values
     */
    function setPriority(
        uint256 tokenId,
        uint64[] calldata priorities
    ) public virtual onlyApprovedForAssetsOrOwner(tokenId) {
        _setPriority(tokenId, priorities);
    }

    // --------------------------- ASSET INTERNALS -------------------------

    /**
     * @notice Used to add a asset entry.
     * @dev This internal function warrants custom access control to be implemented when used.
     * @param id ID of the asset being added
     * @param equippableGroupId ID of the equippable group being marked as equippable into the slot associated with
     *  `Parts` of the `Slot` type
     * @param catalogAddress Address of the `Catalog` associated with the asset
     * @param metadataURI The metadata URI of the asset
     * @param partIds An array of IDs of fixed and slot parts to be included in the asset
     */
    function _addAssetEntry(
        uint64 id,
        uint64 equippableGroupId,
        address catalogAddress,
        string memory metadataURI,
        uint64[] memory partIds
    ) internal virtual {
        _addAssetEntry(id, metadataURI);

        if (catalogAddress == address(0) && partIds.length != 0)
            revert RMRKCatalogRequiredForParts();

        _catalogAddresses[id] = catalogAddress;
        _equippableGroupIds[id] = equippableGroupId;
        _partIds[id] = partIds;
    }

    // ----------------------- ASSET APPROVALS ------------------------

    /**
     * @notice Used to grant approvals for specific tokens to a specified address.
     * @dev This can only be called by the owner of the token or by an account that has been granted permission to
     *  manage all of the owner's assets.
     * @param to Address of the account to receive the approval to the specified token
     * @param tokenId ID of the token for which we are granting the permission
     */
    function approveForAssets(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) revert RMRKApprovalForAssetsToCurrentOwner();

        if (
            _msgSender() != owner &&
            !isApprovedForAllForAssets(owner, _msgSender())
        ) revert RMRKApproveForAssetsCallerIsNotOwnerNorApprovedForAll();
        _approveForAssets(to, tokenId);
    }

    /**
     * @notice Used to get the address of the user that is approved to manage the specified token from the current
     *  owner.
     * @param tokenId ID of the token we are checking
     * @return Address of the account that is approved to manage the token
     */
    function getApprovedForAssets(
        uint256 tokenId
    ) public view virtual returns (address) {
        _requireMinted(tokenId);
        return _tokenApprovalsForAssets[tokenId][ownerOf(tokenId)];
    }

    /**
     * @notice Internal function to check whether the queried user is either:
     *   1. The root owner of the token associated with `tokenId`.
     *   2. Is approved for all assets of the current owner via the `setApprovalForAllForAssets` function.
     *   3. Is granted approval for the specific tokenId for asset management via the `approveForAssets` function.
     * @param user Address of the user we are checking for permission
     * @param tokenId ID of the token to query for permission for a given `user`
     * @return A boolean value indicating whether the user is approved to manage the token or not
     */
    function _isApprovedForAssetsOrOwner(
        address user,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (user == owner ||
            isApprovedForAllForAssets(owner, user) ||
            getApprovedForAssets(tokenId) == user);
    }

    /**
     * @notice Internal function for granting approvals for a specific token.
     * @param to Address of the account we are granting an approval to
     * @param tokenId ID of the token we are granting the approval for
     */
    function _approveForAssets(address to, uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _tokenApprovalsForAssets[tokenId][owner] = to;
        emit ApprovalForAssets(owner, to, tokenId);
    }

    /**
     * @notice Used to clear the approvals on a given token.
     * @param tokenId ID of the token we are clearing the approvals of
     */
    function _cleanApprovals(uint256 tokenId) internal virtual override {
        _approveForAssets(address(0), tokenId);
    }

    // ------------------------------- EQUIPPING ------------------------------

    /**
     * @inheritdoc RMRKNestable
     */
    function _transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) internal virtual override {
        if (!isPending) {
            if (isChildEquipped(tokenId, childAddress, childId))
                revert RMRKMustUnequipFirst();
        }
        super._transferChild(
            tokenId,
            to,
            destinationId,
            childIndex,
            childAddress,
            childId,
            isPending,
            data
        );
    }

    /**
     * @inheritdoc IERC6220
     */
    function equip(
        IntakeEquip memory data
    ) public virtual onlyApprovedOrOwner(data.tokenId) nonReentrant {
        _equip(data);
    }

    /**
     * @notice Private function used to equip a child into a token.
     * @dev If the `Slot` already has an item equipped, the execution will be reverted.
     * @dev If the child can't be used in the given `Slot`, the execution will be reverted.
     * @dev If the catalog doesn't allow this equip to happen, the execution will be reverted.
     * @dev The `IntakeEquip` stuct contains the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @dev Emits ***ChildAssetEquipped*** event.
     * @param data An `IntakeEquip` struct specifying the equip data
     */
    function _equip(IntakeEquip memory data) internal virtual {
        address catalogAddress = _catalogAddresses[data.assetId];
        uint64 slotPartId = data.slotPartId;
        if (
            _equipments[data.tokenId][catalogAddress][slotPartId]
                .childEquippableAddress != address(0)
        ) revert RMRKSlotAlreadyUsed();

        // Check from parent's asset perspective:
        _checkAssetAcceptsSlot(data.assetId, slotPartId);

        IERC6059.Child memory child = childOf(data.tokenId, data.childIndex);

        // Check from child perspective intention to be used in part
        // We add reentrancy guard because of this call, it happens before updating state
        if (
            !IERC6220(child.contractAddress)
                .canTokenBeEquippedWithAssetIntoSlot(
                    address(this),
                    child.tokenId,
                    data.childAssetId,
                    slotPartId
                )
        ) revert RMRKTokenCannotBeEquippedWithAssetIntoSlot();

        // Check from catalog perspective
        if (
            !IRMRKCatalog(catalogAddress).checkIsEquippable(
                slotPartId,
                child.contractAddress
            )
        ) revert RMRKEquippableEquipNotAllowedByCatalog();

        _beforeEquip(data);
        Equipment memory newEquip = Equipment({
            assetId: data.assetId,
            childAssetId: data.childAssetId,
            childId: child.tokenId,
            childEquippableAddress: child.contractAddress
        });

        _equipments[data.tokenId][catalogAddress][slotPartId] = newEquip;
        _equipCountPerChild[data.tokenId][child.contractAddress][
            child.tokenId
        ] += 1;

        emit ChildAssetEquipped(
            data.tokenId,
            data.assetId,
            slotPartId,
            child.tokenId,
            child.contractAddress,
            data.childAssetId
        );
        _afterEquip(data);
    }

    /**
     * @notice Private function to check if a given asset accepts a given slot or not.
     * @dev Execution will be reverted if the `Slot` does not apply for the asset.
     * @param assetId ID of the asset
     * @param slotPartId ID of the `Slot`
     */
    function _checkAssetAcceptsSlot(
        uint64 assetId,
        uint64 slotPartId
    ) private view {
        (, bool found) = _partIds[assetId].indexOf(slotPartId);
        if (!found) revert RMRKTargetAssetCannotReceiveSlot();
    }

    /**
     * @inheritdoc IERC6220
     */
    function unequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _unequip(tokenId, assetId, slotPartId);
    }

    /**
     * @notice Private function used to unequip child from parent token.
     * @dev Emits ***ChildAssetUnequipped*** event.
     * @param tokenId ID of the parent from which the child is being unequipped
     * @param assetId ID of the parent's asset that contains the `Slot` into which the child is equipped
     * @param slotPartId ID of the `Slot` from which to unequip the child
     */
    function _unequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) internal virtual {
        address targetCatalogAddress = _catalogAddresses[assetId];
        Equipment memory equipment = _equipments[tokenId][targetCatalogAddress][
            slotPartId
        ];
        if (equipment.childEquippableAddress == address(0))
            revert RMRKNotEquipped();
        _beforeUnequip(tokenId, assetId, slotPartId);

        delete _equipments[tokenId][targetCatalogAddress][slotPartId];
        _equipCountPerChild[tokenId][equipment.childEquippableAddress][
            equipment.childId
        ] -= 1;

        emit ChildAssetUnequipped(
            tokenId,
            assetId,
            slotPartId,
            equipment.childId,
            equipment.childEquippableAddress,
            equipment.childAssetId
        );
        _afterUnequip(tokenId, assetId, slotPartId);
    }

    /**
     * @inheritdoc IERC6220
     */
    function isChildEquipped(
        uint256 tokenId,
        address childAddress,
        uint256 childId
    ) public view virtual returns (bool) {
        return _equipCountPerChild[tokenId][childAddress][childId] != 0;
    }

    // --------------------- ADMIN VALIDATION ---------------------

    /**
     * @notice Internal function used to declare that the assets belonging to a given `equippableGroupId` are
     *  equippable into the `Slot` associated with the `partId` of the collection at the specified `parentAddress`.
     * @dev Emits ***ValidParentEquippableGroupIdSet*** event.
     * @param equippableGroupId ID of the equippable group
     * @param parentAddress Address of the parent into which the equippable group can be equipped into
     * @param slotPartId ID of the `Slot` that the items belonging to the equippable group can be equipped into
     */
    function _setValidParentForEquippableGroup(
        uint64 equippableGroupId,
        address parentAddress,
        uint64 slotPartId
    ) internal virtual {
        if (equippableGroupId == uint64(0) || slotPartId == uint64(0))
            revert RMRKIdZeroForbidden();
        _validParentSlots[equippableGroupId][parentAddress] = slotPartId;
        emit ValidParentEquippableGroupIdSet(
            equippableGroupId,
            slotPartId,
            parentAddress
        );
    }

    /**
     * @inheritdoc IERC6220
     */
    function canTokenBeEquippedWithAssetIntoSlot(
        address parent,
        uint256 tokenId,
        uint64 assetId,
        uint64 slotId
    ) public view virtual returns (bool) {
        uint64 equippableGroupId = _equippableGroupIds[assetId];
        uint64 equippableSlot = _validParentSlots[equippableGroupId][parent];
        if (equippableSlot == slotId) {
            (, bool found) = getActiveAssets(tokenId).indexOf(assetId);
            return found;
        }
        return false;
    }

    // --------------------- Getting Extended Assets ---------------------

    /**
     * @inheritdoc IERC6220
     */
    function getAssetAndEquippableData(
        uint256 tokenId,
        uint64 assetId
    )
        public
        view
        virtual
        returns (string memory, uint64, address, uint64[] memory)
    {
        return (
            getAssetMetadata(tokenId, assetId),
            _equippableGroupIds[assetId],
            _catalogAddresses[assetId],
            _partIds[assetId]
        );
    }

    ////////////////////////////////////////
    //              UTILS
    ////////////////////////////////////////

    /**
     * @inheritdoc IERC6220
     */
    function getEquipment(
        uint256 tokenId,
        address targetCatalogAddress,
        uint64 slotPartId
    ) public view virtual returns (Equipment memory) {
        return _equipments[tokenId][targetCatalogAddress][slotPartId];
    }

    // HOOKS

    /**
     * @notice A hook to be called before a equipping a asset to the token.
     * @dev The `IntakeEquip` struct consist of the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param data The `IntakeEquip` struct containing data of the asset that is being equipped
     */
    function _beforeEquip(IntakeEquip memory data) internal virtual {}

    /**
     * @notice A hook to be called after equipping a asset to the token.
     * @dev The `IntakeEquip` struct consist of the following data:
     *  [
     *      tokenId,
     *      childIndex,
     *      assetId,
     *      slotPartId,
     *      childAssetId
     *  ]
     * @param data The `IntakeEquip` struct containing data of the asset that was equipped
     */
    function _afterEquip(IntakeEquip memory data) internal virtual {}

    /**
     * @notice A hook to be called before unequipping a asset from the token.
     * @param tokenId ID of the token from which the asset is being unequipped
     * @param assetId ID of the asset being unequipped
     * @param slotPartId ID of the slot from which the asset is being unequipped
     */
    function _beforeUnequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) internal virtual {}

    /**
     * @notice A hook to be called after unequipping a asset from the token.
     * @param tokenId ID of the token from which the asset was unequipped
     * @param assetId ID of the asset that was unequipped
     * @param slotPartId ID of the slot from which the asset was unequipped
     */
    function _afterUnequip(
        uint256 tokenId,
        uint64 assetId,
        uint64 slotPartId
    ) internal virtual {}
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IERC6454
 * @author RMRK team
 * @notice A minimal extension to identify the transferability of Non-Fungible Tokens.
 */
interface IERC6454 is IERC165 {
    /**
     * @notice Used to check whether the given token is transferable or not.
     * @dev If this function returns `false`, the transfer of the token MUST revert execution.
     * @dev If the tokenId does not exist, this method MUST revert execution, unless the token is being checked for
     *  minting.
     * @param tokenId ID of the token being checked
     * @param from Address from which the token is being transferred
     * @param to Address to which the token is being transferred
     * @return Boolean value indicating whether the given token is transferable
     */
    function isTransferable(
        uint256 tokenId,
        address from,
        address to
    ) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "../../core/RMRKCore.sol";
import "./IERC6454.sol";
import "../../library/RMRKErrors.sol";

/**
 * @title RMRKSoulbound
 * @author RMRK team
 * @notice Smart contract of the RMRK Soulbound module.
 */
abstract contract RMRKSoulbound is IERC6454, RMRKCore {
    /**
     * @notice Hook that is called before any token transfer. This includes minting and burning.
     * @dev This is a hook ensuring that all transfers of tokens are reverted if the token is soulbound.
     * @dev The only exception of transfers being allowed is when the tokens are minted or when they are being burned.
     * @param from Address from which the token is originating (current owner of the token)
     * @param to Address to which the token would be sent
     * @param tokenId ID of the token that would be transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (!isTransferable(tokenId, from, to))
            revert RMRKCannotTransferSoulbound();

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function isTransferable(
        uint256,
        address from,
        address to
    ) public view virtual returns (bool) {
        return ((from == address(0) || // Exclude minting
            to == address(0)) && from != to); // Exclude Burning // Besides the obvious transfer to self, if both are address 0 (general transferability check), it returns false
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return interfaceId == type(IERC6454).interfaceId;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

/// @title RMRKErrors
/// @author RMRK team
/// @notice A collection of errors used in the RMRK suite
/// @dev Errors are kept in a centralised file in order to provide a central point of reference and to avoid error
///  naming collisions due to inheritance

/// Attempting to grant the token to 0x0 address
error ERC721AddressZeroIsNotaValidOwner();
/// Attempting to grant approval to the current owner of the token
error ERC721ApprovalToCurrentOwner();
/// Attempting to grant approval when not being owner or approved for all should not be permitted
error ERC721ApproveCallerIsNotOwnerNorApprovedForAll();
/// Attempting to get approvals for a token owned by 0x0 (considered non-existent)
error ERC721ApprovedQueryForNonexistentToken();
/// Attempting to grant approval to self
error ERC721ApproveToCaller();
/// Attempting to use an invalid token ID
error ERC721InvalidTokenId();
/// Attempting to mint to 0x0 address
error ERC721MintToTheZeroAddress();
/// Attempting to manage a token without being its owner or approved by the owner
error ERC721NotApprovedOrOwner();
/// Attempting to mint an already minted token
error ERC721TokenAlreadyMinted();
/// Attempting to transfer the token from an address that is not the owner
error ERC721TransferFromIncorrectOwner();
/// Attempting to safe transfer to an address that is unable to receive the token
error ERC721TransferToNonReceiverImplementer();
/// Attempting to transfer the token to a 0x0 address
error ERC721TransferToTheZeroAddress();
/// Attempting to grant approval of assets to their current owner
error RMRKApprovalForAssetsToCurrentOwner();
/// Attempting to grant approval of assets without being the caller or approved for all
error RMRKApproveForAssetsCallerIsNotOwnerNorApprovedForAll();
/// Attempting to incorrectly configue a Catalog item
error RMRKBadConfig();
/// Attempting to set the priorities with an array of length that doesn't match the length of active assets array
error RMRKBadPriorityListLength();
/// Attempting to add an asset entry with `Part`s, without setting the `Catalog` address
error RMRKCatalogRequiredForParts();
/// Attempting to transfer a soulbound (non-transferrable) token
error RMRKCannotTransferSoulbound();
/// Attempting to accept a child that has already been accepted
error RMRKChildAlreadyExists();
/// Attempting to interact with a child, using index that is higher than the number of children
error RMRKChildIndexOutOfRange();
/// Attempting to find the index of a child token on a parent which does not own it.
error RMRKChildNotFoundInParent();
/// Attempting to pass collaborator address array and collaborator permission array of different lengths
error RMRKCollaboratorArraysNotEqualLength();
/// Attempting to register a collection that is already registered
error RMRKCollectionAlreadyRegistered();
/// Attempting to manage or interact with colleciton that is not registered
error RMRKCollectionNotRegistered();
/// Attempting to equip a `Part` with a child not approved by the Catalog
error RMRKEquippableEquipNotAllowedByCatalog();
/// Attempting to use ID 0, which is not supported
/// @dev The ID 0 in RMRK suite is reserved for empty values. Guarding against its use ensures the expected operation
error RMRKIdZeroForbidden();
/// Attempting to interact with an asset, using index greater than number of assets
error RMRKIndexOutOfRange();
/// Attempting to reclaim a child that can't be reclaimed
error RMRKInvalidChildReclaim();
/// Attempting to interact with an end-user account when the contract account is expected
error RMRKIsNotContract();
/// Attempting to interact with a contract that had its operation locked
error RMRKLocked();
/// Attempting to add a pending child after the number of pending children has reached the limit (default limit is 128)
error RMRKMaxPendingChildrenReached();
/// Attempting to add a pending asset after the number of pending assets has reached the limit (default limit is
///  128)
error RMRKMaxPendingAssetsReached();
/// Attempting to burn a total number of recursive children higher than maximum set
/// @param childContract Address of the collection smart contract in which the maximum number of recursive burns was reached
/// @param childId ID of the child token at which the maximum number of recursive burns was reached
error RMRKMaxRecursiveBurnsReached(address childContract, uint256 childId);
/// Attempting to mint a number of tokens that would cause the total supply to be greater than maximum supply
error RMRKMintOverMax();
/// Attempting to mint a nested token to a smart contract that doesn't support nesting
error RMRKMintToNonRMRKNestableImplementer();
/// Attempting to pass complementary arrays of different lengths
error RMRKMismachedArrayLength();
/// Attempting to transfer a child before it is unequipped
error RMRKMustUnequipFirst();
/// Attempting to nest a child over the nestable limit (current limit is 100 levels of nesting)
error RMRKNestableTooDeep();
/// Attempting to nest the token to own descendant, which would create a loop and leave the looped tokens in limbo
error RMRKNestableTransferToDescendant();
/// Attempting to nest the token to a smart contract that doesn't support nesting
error RMRKNestableTransferToNonRMRKNestableImplementer();
/// Attempting to nest the token into itself
error RMRKNestableTransferToSelf();
/// Attempting to interact with an asset that can not be found
error RMRKNoAssetMatchingId();
/// Attempting to manage an asset without owning it or having been granted permission by the owner to do so
error RMRKNotApprovedForAssetsOrOwner();
/// Attempting to interact with a token without being its owner or having been granted permission by the
///  owner to do so
/// @dev When a token is nested, only the direct owner (NFT parent) can mange it. In that case, approved addresses are
///  not allowed to manage it, in order to ensure the expected behaviour
error RMRKNotApprovedOrDirectOwner();
/// Attempting to manage a collection without being the collection's collaborator
error RMRKNotCollectionCollaborator();
/// Attemting to manage a collection without being the collection's issuer
error RMRKNotCollectionIssuer();
/// Attempting to manage a collection without being the collection's issuer or collaborator
error RMRKNotCollectionIssuerOrCollaborator();
/// Attempting to compose an asset wihtout having an associated Catalog
error RMRKNotComposableAsset();
/// Attempting to unequip an item that isn't equipped
error RMRKNotEquipped();
/// Attempting to interact with a management function without being the smart contract's owner
error RMRKNotOwner();
/// Attempting to interact with a function without being the owner or contributor of the collection
error RMRKNotOwnerOrContributor();
/// Attempting to manage a collection without being the specific address
error RMRKNotSpecificAddress();
/// Attempting to manage a token without being its owner
error RMRKNotTokenOwner();
/// Attempting to transfer the ownership to the 0x0 address
error RMRKNewOwnerIsZeroAddress();
/// Attempting to assign a 0x0 address as a contributor
error RMRKNewContributorIsZeroAddress();
/// Attemtping to use `Ownable` interface without implementing it
error RMRKOwnableNotImplemented();
/// Attempting an operation requiring the token being nested, while it is not
error RMRKParentIsNotNFT();
/// Attempting to add a `Part` with an ID that is already used
error RMRKPartAlreadyExists();
/// Attempting to use a `Part` that doesn't exist
error RMRKPartDoesNotExist();
/// Attempting to use a `Part` that is `Fixed` when `Slot` kind of `Part` should be used
error RMRKPartIsNotSlot();
/// Attempting to interact with a pending child using an index greater than the size of pending array
error RMRKPendingChildIndexOutOfRange();
/// Attempting to add an asset using an ID that has already been used
error RMRKAssetAlreadyExists();
/// Attempting to equip an item into a slot that already has an item equipped
error RMRKSlotAlreadyUsed();
/// Attempting to equip an item into a `Slot` that the target asset does not implement
error RMRKTargetAssetCannotReceiveSlot();
/// Attempting to equip a child into a `Slot` and parent that the child's collection doesn't support
error RMRKTokenCannotBeEquippedWithAssetIntoSlot();
/// Attempting to compose a NFT of a token without active assets
error RMRKTokenDoesNotHaveAsset();
/// Attempting to determine the asset with the top priority on a token without assets
error RMRKTokenHasNoAssets();
/// Attempting to accept or transfer a child which does not match the one at the specified index
error RMRKUnexpectedChildId();
/// Attempting to reject all pending assets but more assets than expected are pending
error RMRKUnexpectedNumberOfAssets();
/// Attempting to reject all pending children but children assets than expected are pending
error RMRKUnexpectedNumberOfChildren();
/// Attempting to accept or reject an asset which does not match the one at the specified index
error RMRKUnexpectedAssetId();
/// Attempting an operation expecting a parent to the token which is not the actual one
error RMRKUnexpectedParent();
/// Attempting not to pass an empty array of equippable addresses when adding or setting the equippable addresses
error RMRKZeroLengthIdsPassed();
/// Attempting to set the royalties to a value higher than 100% (10000 in base points)
error RMRKRoyaltiesTooHigh();
/// Attempting to do a bulk operation on a token that is not owned by the caller
error RMRKCanOnlyDoBulkOperationsOnOwnedTokens();
/// Attempting to do a bulk operation with multiple tokens at a time
error RMRKCanOnlyDoBulkOperationsWithOneTokenAtATime();

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

/**
 * @title RMRKLib
 * @author RMRK team
 * @notice RMRK library smart contract.
 */
library RMRKLib {
    /**
     * @notice Used to remove an item from the array using the specified index.
     * @dev The item is removed by replacing it with the last item and removing the last element.
     * @param array An array of items containing the item to be removed
     * @param index Index of the item to remove
     */
    function removeItemByIndex(uint64[] storage array, uint256 index) internal {
        //Check to see if this is already gated by require in all calls
        require(index < array.length);
        array[index] = array[array.length - 1];
        array.pop();
    }

    /**
     * @notice Used to determine the index of the item in the array by spedifying its value.
     * @dev This was adapted from Cryptofin-Solidity `arrayUtils`.
     * @dev If the item is not found the index returned will equal `0`.
     * @param A The array containing the item to be found
     * @param a The value of the item to find the index of
     * @return The index of the item in the array
     * @return A boolean value specifying whether the item was found
     */
    function indexOf(
        uint64[] memory A,
        uint64 a
    ) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i; i < length; ) {
            if (A[i] == a) {
                return (i, true);
            }
            unchecked {
                ++i;
            }
        }
        return (0, false);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "./IERC5773.sol";
import "../library/RMRKLib.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "../library/RMRKErrors.sol";

/**
 * @title AbstractMultiAsset
 * @author RMRK team
 * @notice Abstract Smart contract implementing most of the common logic for contracts implementing IERC5773
 */
abstract contract AbstractMultiAsset is Context, IERC5773 {
    using RMRKLib for uint64[];

    /// Mapping of uint64 Ids to asset metadata
    mapping(uint64 => string) private _assets;

    /// Mapping of tokenId to new asset, to asset to be replaced
    mapping(uint256 => mapping(uint64 => uint64)) private _assetReplacements;

    /// Mapping of tokenId to an array of active assets
    /// @dev Active recurses is unbounded, getting all would reach gas limit at around 30k items
    /// so we leave this as internal in case a custom implementation needs to implement pagination
    mapping(uint256 => uint64[]) internal _activeAssets;

    /// Mapping of tokenId to an array of pending assets
    mapping(uint256 => uint64[]) internal _pendingAssets;

    /// Mapping of tokenId to an array of priorities for active assets
    mapping(uint256 => uint64[]) internal _activeAssetPriorities;

    /// Mapping of tokenId to assetId to whether the token has this asset assigned
    mapping(uint256 => mapping(uint64 => bool)) private _tokenAssets;

    /// Mapping from owner to operator approvals for assets
    mapping(address => mapping(address => bool))
        private _operatorApprovalsForAssets;

    /**
     * @inheritdoc IERC5773
     */
    function getAssetMetadata(
        uint256 tokenId,
        uint64 assetId
    ) public view virtual returns (string memory) {
        if (!_tokenAssets[tokenId][assetId]) revert RMRKTokenDoesNotHaveAsset();
        return _assets[assetId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function getActiveAssets(
        uint256 tokenId
    ) public view virtual returns (uint64[] memory) {
        return _activeAssets[tokenId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function getPendingAssets(
        uint256 tokenId
    ) public view virtual returns (uint64[] memory) {
        return _pendingAssets[tokenId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function getActiveAssetPriorities(
        uint256 tokenId
    ) public view virtual returns (uint64[] memory) {
        return _activeAssetPriorities[tokenId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function getAssetReplacements(
        uint256 tokenId,
        uint64 newAssetId
    ) public view virtual returns (uint64) {
        return _assetReplacements[tokenId][newAssetId];
    }

    /**
     * @inheritdoc IERC5773
     */
    function isApprovedForAllForAssets(
        address owner,
        address operator
    ) public view virtual returns (bool) {
        return _operatorApprovalsForAssets[owner][operator];
    }

    /**
     * @inheritdoc IERC5773
     */
    function setApprovalForAllForAssets(
        address operator,
        bool approved
    ) public virtual {
        if (_msgSender() == operator)
            revert RMRKApprovalForAssetsToCurrentOwner();

        _operatorApprovalsForAssets[_msgSender()][operator] = approved;
        emit ApprovalForAllForAssets(_msgSender(), operator, approved);
    }

    /**
     * @notice Used to accept a pending asset.
     * @dev The call is reverted if there is no pending asset at a given index.
     * @dev Emits ***AssetAccepted*** event.
     * @param tokenId ID of the token for which to accept the pending asset
     * @param index Index of the asset in the pending array to accept
     * @param assetId ID of the asset to accept in token's pending array
     */
    function _acceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) internal virtual {
        _validatePendingAssetAtIndex(tokenId, index, assetId);
        _beforeAcceptAsset(tokenId, index, assetId);

        uint64 replacesId = _assetReplacements[tokenId][assetId];
        uint256 replaceIndex;
        bool replacefound;
        if (replacesId != uint64(0))
            (replaceIndex, replacefound) = _activeAssets[tokenId].indexOf(
                replacesId
            );

        if (replacefound) {
            // We don't want to remove and then push a new asset.
            // This way we also keep the priority of the original asset
            _activeAssets[tokenId][replaceIndex] = assetId;
            delete _tokenAssets[tokenId][replacesId];
        } else {
            // We use the current size as next priority, by default priorities would be [0,1,2...]
            _activeAssetPriorities[tokenId].push(
                uint64(_activeAssets[tokenId].length)
            );
            _activeAssets[tokenId].push(assetId);
            replacesId = uint64(0);
        }
        _removePendingAsset(tokenId, index, assetId);

        emit AssetAccepted(tokenId, assetId, replacesId);
        _afterAcceptAsset(tokenId, index, assetId);
    }

    /**
     * @notice Used to reject the specified asset from the pending array.
     * @dev The call is reverted if there is no pending asset at a given index.
     * @dev Emits ***AssetRejected*** event.
     * @param tokenId ID of the token that the asset is being rejected from
     * @param index Index of the asset in the pending array to be rejected
     * @param assetId ID of the asset expected to be in the index
     */
    function _rejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) internal virtual {
        _validatePendingAssetAtIndex(tokenId, index, assetId);
        _beforeRejectAsset(tokenId, index, assetId);

        _removePendingAsset(tokenId, index, assetId);
        delete _tokenAssets[tokenId][assetId];

        emit AssetRejected(tokenId, assetId);
        _afterRejectAsset(tokenId, index, assetId);
    }

    /**
     * @notice Used to validate the index on the pending assets array
     * @dev The call is reverted if the index is out of range or the asset Id is not present at the index.
     * @param tokenId ID of the token that the asset is validated from
     * @param index Index of the asset in the pending array
     * @param assetId Id of the asset expected to be in the index
     */
    function _validatePendingAssetAtIndex(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) private view {
        if (index >= _pendingAssets[tokenId].length)
            revert RMRKIndexOutOfRange();
        if (assetId != _pendingAssets[tokenId][index])
            revert RMRKUnexpectedAssetId();
    }

    /**
     * @notice Used to remove the asset at the index on the pending assets array
     * @param tokenId ID of the token that the asset is being removed from
     * @param index Index of the asset in the pending array
     * @param assetId Id of the asset expected to be in the index
     */
    function _removePendingAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) private {
        _pendingAssets[tokenId].removeItemByIndex(index);
        delete _assetReplacements[tokenId][assetId];
    }

    /**
     * @notice Used to reject all of the pending assets for the given token.
     * @dev When rejecting all assets, the pending array is indiscriminately cleared.
     * @dev If the number of pending assets is greater than the value of `maxRejections`, the exectuion will be
     *  reverted.
     * @dev Emits ***AssetRejected*** event.
     * @param tokenId ID of the token to reject all of the pending assets.
     * @param maxRejections Maximum number of expected assets to reject, used to prevent from
     *  rejecting assets which arrive just before this operation.
     */
    function _rejectAllAssets(
        uint256 tokenId,
        uint256 maxRejections
    ) internal virtual {
        uint256 len = _pendingAssets[tokenId].length;
        if (len > maxRejections) revert RMRKUnexpectedNumberOfAssets();

        _beforeRejectAllAssets(tokenId);

        for (uint256 i; i < len; ) {
            uint64 assetId = _pendingAssets[tokenId][i];
            delete _assetReplacements[tokenId][assetId];
            unchecked {
                ++i;
            }
        }
        delete (_pendingAssets[tokenId]);

        emit AssetRejected(tokenId, uint64(0));
        _afterRejectAllAssets(tokenId);
    }

    /**
     * @notice Used to specify the priorities for a given token's active assets.
     * @dev If the length of the priorities array doesn't match the length of the active assets array, the execution
     *  will be reverted.
     * @dev The position of the priority value in the array corresponds the position of the asset in the active
     *  assets array it will be applied to.
     * @dev Emits ***AssetPrioritySet*** event.
     * @param tokenId ID of the token for which the priorities are being set
     * @param priorities Array of priorities for the assets
     */
    function _setPriority(
        uint256 tokenId,
        uint64[] calldata priorities
    ) internal virtual {
        uint256 length = priorities.length;
        if (length != _activeAssets[tokenId].length)
            revert RMRKBadPriorityListLength();

        _beforeSetPriority(tokenId, priorities);
        _activeAssetPriorities[tokenId] = priorities;

        emit AssetPrioritySet(tokenId);
        _afterSetPriority(tokenId, priorities);
    }

    /**
     * @notice Used to add an asset entry.
     * @dev If the specified ID is already used by another asset, the execution will be reverted.
     * @dev This internal function warrants custom access control to be implemented when used.
     * @dev Emits ***AssetSet*** event.
     * @param id ID of the asset to assign to the new asset
     * @param metadataURI Metadata URI of the asset
     */
    function _addAssetEntry(
        uint64 id,
        string memory metadataURI
    ) internal virtual {
        if (id == uint64(0)) revert RMRKIdZeroForbidden();
        if (bytes(_assets[id]).length > 0) revert RMRKAssetAlreadyExists();

        _beforeAddAsset(id, metadataURI);
        _assets[id] = metadataURI;

        emit AssetSet(id);
        _afterAddAsset(id, metadataURI);
    }

    /**
     * @notice Used to add an asset to a token.
     * @dev If the given asset is already added to the token, the execution will be reverted.
     * @dev If the asset ID is invalid, the execution will be reverted.
     * @dev If the token already has the maximum amount of pending assets (128), the execution will be
     *  reverted.
     * @dev Emits ***AssetAddedToTokens*** event.
     * @param tokenId ID of the token to add the asset to
     * @param assetId ID of the asset to add to the token
     * @param replacesAssetWithId ID of the asset to replace from the token's list of active assets
     */
    function _addAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) internal virtual {
        if (_tokenAssets[tokenId][assetId]) revert RMRKAssetAlreadyExists();

        if (bytes(_assets[assetId]).length == uint256(0))
            revert RMRKNoAssetMatchingId();

        if (_pendingAssets[tokenId].length >= 128)
            revert RMRKMaxPendingAssetsReached();

        _beforeAddAssetToToken(tokenId, assetId, replacesAssetWithId);
        _tokenAssets[tokenId][assetId] = true;
        _pendingAssets[tokenId].push(assetId);

        if (replacesAssetWithId != uint64(0)) {
            _assetReplacements[tokenId][assetId] = replacesAssetWithId;
        }

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        emit AssetAddedToTokens(tokenIds, assetId, replacesAssetWithId);
        _afterAddAssetToToken(tokenId, assetId, replacesAssetWithId);
    }

    /**
     * @notice Hook that is called before an asset is added.
     * @param id ID of the asset
     * @param metadataURI Metadata URI of the asset
     */
    function _beforeAddAsset(
        uint64 id,
        string memory metadataURI
    ) internal virtual {}

    /**
     * @notice Hook that is called after an asset is added.
     * @param id ID of the asset
     * @param metadataURI Metadata URI of the asset
     */
    function _afterAddAsset(
        uint64 id,
        string memory metadataURI
    ) internal virtual {}

    /**
     * @notice Hook that is called before adding an asset to a token's pending assets array.
     * @dev If the asset doesn't intend to replace another asset, the `replacesAssetWithId` value should be `0`.
     * @param tokenId ID of the token to which the asset is being added
     * @param assetId ID of the asset that is being added
     * @param replacesAssetWithId ID of the asset that this asset is attempting to replace
     */
    function _beforeAddAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) internal virtual {}

    /**
     * @notice Hook that is called after an asset has been added to a token's pending assets array.
     * @dev If the asset doesn't intend to replace another asset, the `replacesAssetWithId` value should be `0`.
     * @param tokenId ID of the token to which the asset is has been added
     * @param assetId ID of the asset that is has been added
     * @param replacesAssetWithId ID of the asset that this asset is attempting to replace
     */
    function _afterAddAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) internal virtual {}

    /**
     * @notice Hook that is called before an asset is accepted to a token's active assets array.
     * @param tokenId ID of the token for which the asset is being accepted
     * @param index Index of the asset in the token's pending assets array
     * @param assetId ID of the asset expected to be located at the specified `index`
     */
    function _beforeAcceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) internal virtual {}

    /**
     * @notice Hook that is called after an asset is accepted to a token's active assets array.
     * @param tokenId ID of the token for which the asset has been accepted
     * @param index Index of the asset in the token's pending assets array
     * @param assetId ID of the asset expected to have been located at the specified `index`
     */
    function _afterAcceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) internal virtual {}

    /**
     * @notice Hook that is called before rejecting an asset.
     * @param tokenId ID of the token from which the asset is being rejected
     * @param index Index of the asset in the token's pending assets array
     * @param assetId ID of the asset expected to be located at the specified `index`
     */
    function _beforeRejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) internal virtual {}

    /**
     * @notice Hook that is called after rejecting an asset.
     * @param tokenId ID of the token from which the asset has been rejected
     * @param index Index of the asset in the token's pending assets array
     * @param assetId ID of the asset expected to have been located at the specified `index`
     */
    function _afterRejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) internal virtual {}

    /**
     * @notice Hook that is called before rejecting all assets of a token.
     * @param tokenId ID of the token from which all of the assets are being rejected
     */
    function _beforeRejectAllAssets(uint256 tokenId) internal virtual {}

    /**
     * @notice Hook that is called after rejecting all assets of a token.
     * @param tokenId ID of the token from which all of the assets have been rejected
     */
    function _afterRejectAllAssets(uint256 tokenId) internal virtual {}

    /**
     * @notice Hook that is called before the priorities for token's assets is set.
     * @param tokenId ID of the token for which the asset priorities are being set
     * @param priorities[] An array of priorities for token's active resources
     */
    function _beforeSetPriority(
        uint256 tokenId,
        uint64[] calldata priorities
    ) internal virtual {}

    /**
     * @notice Hook that is called after the priorities for token's assets is set.
     * @param tokenId ID of the token for which the asset priorities have been set
     * @param priorities[] An array of priorities for token's active resources
     */
    function _afterSetPriority(
        uint256 tokenId,
        uint64[] calldata priorities
    ) internal virtual {}
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IERC5773
 * @author RMRK team
 * @notice Interface smart contract of the RMRK multi asset module.
 */
interface IERC5773 is IERC165 {
    /**
     * @notice Used to notify listeners that an asset object is initialized at `assetId`.
     * @param assetId ID of the asset that was initialized
     */
    event AssetSet(uint64 indexed assetId);

    /**
     * @notice Used to notify listeners that an asset object at `assetId` is added to token's pending asset
     *  array.
     * @param tokenIds An array of token IDs that received a new pending asset
     * @param assetId ID of the asset that has been added to the token's pending assets array
     * @param replacesId ID of the asset that would be replaced
     */
    event AssetAddedToTokens(
        uint256[] tokenIds,
        uint64 indexed assetId,
        uint64 indexed replacesId
    );

    /**
     * @notice Used to notify listeners that an asset object at `assetId` is accepted by the token and migrated
     *  from token's pending assets array to active assets array of the token.
     * @param tokenId ID of the token that had a new asset accepted
     * @param assetId ID of the asset that was accepted
     * @param replacesId ID of the asset that was replaced
     */
    event AssetAccepted(
        uint256 indexed tokenId,
        uint64 indexed assetId,
        uint64 indexed replacesId
    );

    /**
     * @notice Used to notify listeners that an asset object at `assetId` is rejected from token and is dropped
     *  from the pending assets array of the token.
     * @param tokenId ID of the token that had an asset rejected
     * @param assetId ID of the asset that was rejected
     */
    event AssetRejected(uint256 indexed tokenId, uint64 indexed assetId);

    /**
     * @notice Used to notify listeners that token's prioritiy array is reordered.
     * @param tokenId ID of the token that had the asset priority array updated
     */
    event AssetPrioritySet(uint256 indexed tokenId);

    /**
     * @notice Used to notify listeners that owner has granted an approval to the user to manage the assets of a
     *  given token.
     * @dev Approvals must be cleared on transfer
     * @param owner Address of the account that has granted the approval for all token's assets
     * @param approved Address of the account that has been granted approval to manage the token's assets
     * @param tokenId ID of the token on which the approval was granted
     */
    event ApprovalForAssets(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @notice Used to notify listeners that owner has granted approval to the user to manage assets of all of their
     *  tokens.
     * @param owner Address of the account that has granted the approval for all assets on all of their tokens
     * @param operator Address of the account that has been granted the approval to manage the token's assets on all of
     *  the tokens
     * @param approved Boolean value signifying whether the permission has been granted (`true`) or revoked (`false`)
     */
    event ApprovalForAllForAssets(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @notice Accepts an asset at from the pending array of given token.
     * @dev Migrates the asset from the token's pending asset array to the token's active asset array.
     * @dev Active assets cannot be removed by anyone, but can be replaced by a new asset.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - `index` must be in range of the length of the pending asset array.
     * @dev Emits an {AssetAccepted} event.
     * @param tokenId ID of the token for which to accept the pending asset
     * @param index Index of the asset in the pending array to accept
     * @param assetId ID of the asset expected to be in the index
     */
    function acceptAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) external;

    /**
     * @notice Rejects an asset from the pending array of given token.
     * @dev Removes the asset from the token's pending asset array.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - `index` must be in range of the length of the pending asset array.
     * @dev Emits a {AssetRejected} event.
     * @param tokenId ID of the token that the asset is being rejected from
     * @param index Index of the asset in the pending array to be rejected
     * @param assetId ID of the asset expected to be in the index
     */
    function rejectAsset(
        uint256 tokenId,
        uint256 index,
        uint64 assetId
    ) external;

    /**
     * @notice Rejects all assets from the pending array of a given token.
     * @dev Effecitvely deletes the pending array.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     * @dev Emits a {AssetRejected} event with assetId = 0.
     * @param tokenId ID of the token of which to clear the pending array.
     * @param maxRejections Maximum number of expected assets to reject, used to prevent from rejecting assets which
     *  arrive just before this operation.
     */
    function rejectAllAssets(uint256 tokenId, uint256 maxRejections) external;

    /**
     * @notice Sets a new priority array for a given token.
     * @dev The priority array is a non-sequential list of `uint64`s, where the lowest value is considered highest
     *  priority.
     * @dev Value `0` of a priority is a special case equivalent to unitialized.
     * @dev Requirements:
     *
     *  - The caller must own the token or be approved to manage the token's assets
     *  - `tokenId` must exist.
     *  - The length of `priorities` must be equal the length of the active assets array.
     * @dev Emits a {AssetPrioritySet} event.
     * @param tokenId ID of the token to set the priorities for
     * @param priorities An array of priorities of active assets. The succesion of items in the priorities array
     *  matches that of the succesion of items in the active array
     */
    function setPriority(
        uint256 tokenId,
        uint64[] calldata priorities
    ) external;

    /**
     * @notice Used to retrieve IDs of the active assets of given token.
     * @dev Asset data is stored by reference, in order to access the data corresponding to the ID, call
     *  `getAssetMetadata(tokenId, assetId)`.
     * @dev You can safely get 10k
     * @param tokenId ID of the token to retrieve the IDs of the active assets
     * @return An array of active asset IDs of the given token
     */
    function getActiveAssets(
        uint256 tokenId
    ) external view returns (uint64[] memory);

    /**
     * @notice Used to retrieve IDs of the pending assets of given token.
     * @dev Asset data is stored by reference, in order to access the data corresponding to the ID, call
     *  `getAssetMetadata(tokenId, assetId)`.
     * @param tokenId ID of the token to retrieve the IDs of the pending assets
     * @return An array of pending asset IDs of the given token
     */
    function getPendingAssets(
        uint256 tokenId
    ) external view returns (uint64[] memory);

    /**
     * @notice Used to retrieve the priorities of the active resoources of a given token.
     * @dev Asset priorities are a non-sequential array of uint64 values with an array size equal to active asset
     *  priorites.
     * @param tokenId ID of the token for which to retrieve the priorities of the active assets
     * @return An array of priorities of the active assets of the given token
     */
    function getActiveAssetPriorities(
        uint256 tokenId
    ) external view returns (uint64[] memory);

    /**
     * @notice Used to retrieve the asset that will be replaced if a given asset from the token's pending array
     *  is accepted.
     * @dev Asset data is stored by reference, in order to access the data corresponding to the ID, call
     *  `getAssetMetadata(tokenId, assetId)`.
     * @param tokenId ID of the token to check
     * @param newAssetId ID of the pending asset which will be accepted
     * @return ID of the asset which will be replaced
     */
    function getAssetReplacements(
        uint256 tokenId,
        uint64 newAssetId
    ) external view returns (uint64);

    /**
     * @notice Used to fetch the asset metadata of the specified token's active asset with the given index.
     * @dev Assets are stored by reference mapping `_assets[assetId]`.
     * @dev Can be overriden to implement enumerate, fallback or other custom logic.
     * @param tokenId ID of the token from which to retrieve the asset metadata
     * @param assetId Asset Id, must be in the active assets array
     * @return The metadata of the asset belonging to the specified index in the token's active assets
     *  array
     */
    function getAssetMetadata(
        uint256 tokenId,
        uint64 assetId
    ) external view returns (string memory);

    // Approvals

    /**
     * @notice Used to grant permission to the user to manage token's assets.
     * @dev This differs from transfer approvals, as approvals are not cleared when the approved party accepts or
     *  rejects an asset, or sets asset priorities. This approval is cleared on token transfer.
     * @dev Only a single account can be approved at a time, so approving the `0x0` address clears previous approvals.
     * @dev Requirements:
     *
     *  - The caller must own the token or be an approved operator.
     *  - `tokenId` must exist.
     * @dev Emits an {ApprovalForAssets} event.
     * @param to Address of the account to grant the approval to
     * @param tokenId ID of the token for which the approval to manage the assets is granted
     */
    function approveForAssets(address to, uint256 tokenId) external;

    /**
     * @notice Used to retrieve the address of the account approved to manage assets of a given token.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @param tokenId ID of the token for which to retrieve the approved address
     * @return Address of the account that is approved to manage the specified token's assets
     */
    function getApprovedForAssets(
        uint256 tokenId
    ) external view returns (address);

    /**
     * @notice Used to add or remove an operator of assets for the caller.
     * @dev Operators can call {acceptAsset}, {rejectAsset}, {rejectAllAssets} or {setPriority} for any token
     *  owned by the caller.
     * @dev Requirements:
     *
     *  - The `operator` cannot be the caller.
     * @dev Emits an {ApprovalForAllForAssets} event.
     * @param operator Address of the account to which the operator role is granted or revoked from
     * @param approved The boolean value indicating whether the operator role is being granted (`true`) or revoked
     *  (`false`)
     */
    function setApprovalForAllForAssets(
        address operator,
        bool approved
    ) external;

    /**
     * @notice Used to check whether the address has been granted the operator role by a given address or not.
     * @dev See {setApprovalForAllForAssets}.
     * @param owner Address of the account that we are checking for whether it has granted the operator role
     * @param operator Address of the account that we are checking whether it has the operator role or not
     * @return A boolean value indicating wehter the account we are checking has been granted the operator role
     */
    function isApprovedForAllForAssets(
        address owner,
        address operator
    ) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IERC6059
 * @author RMRK team
 * @notice Interface smart contract of the RMRK nestable module.
 */
interface IERC6059 is IERC165 {
    /**
     * @notice The core struct of RMRK ownership.
     * @dev The `DirectOwner` struct is used to store information of the next immediate owner, be it the parent token or
     *  the externally owned account.
     * @dev If the token is owned by the externally owned account, the `tokenId` should equal `0`.
     * @param tokenId ID of the parent token
     * @param ownerAddress Address of the owner of the token. If the owner is another token, then the address should be
     *  the one of the parent token's collection smart contract. If the owner is externally owned account, the address
     *  should be the address of this account
     * @param isNft A boolean value signifying whether the token is owned by another token (`true`) or by an externally
     *  owned account (`false`)
     */
    struct DirectOwner {
        uint256 tokenId;
        address ownerAddress;
    }

    /**
     * @notice Used to notify listeners that the token is being transferred.
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     * @param from Address of the previous immediate owner, which is a smart contract if the token was nested.
     * @param to Address of the new immediate owner, which is a smart contract if the token is being nested.
     * @param fromTokenId ID of the previous parent token. If the token was not nested before, the value should be `0`
     * @param toTokenId ID of the new parent token. If the token is not being nested, the value should be `0`
     * @param tokenId ID of the token being transferred
     */
    event NestTransfer(
        address indexed from,
        address indexed to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 indexed tokenId
    );

    /**
     * @notice Used to notify listeners that a new token has been added to a given token's pending children array.
     * @dev Emitted when a child NFT is added to a token's pending array.
     * @param tokenId ID of the token that received a new pending child token
     * @param childIndex Index of the proposed child token in the parent token's pending children array
     * @param childAddress Address of the proposed child token's collection smart contract
     * @param childId ID of the child token in the child token's collection smart contract
     */
    event ChildProposed(
        uint256 indexed tokenId,
        uint256 childIndex,
        address indexed childAddress,
        uint256 indexed childId
    );

    /**
     * @notice Used to notify listeners that a new child token was accepted by the parent token.
     * @dev Emitted when a parent token accepts a token from its pending array, migrating it to the active array.
     * @param tokenId ID of the token that accepted a new child token
     * @param childIndex Index of the newly accepted child token in the parent token's active children array
     * @param childAddress Address of the child token's collection smart contract
     * @param childId ID of the child token in the child token's collection smart contract
     */
    event ChildAccepted(
        uint256 indexed tokenId,
        uint256 childIndex,
        address indexed childAddress,
        uint256 indexed childId
    );

    /**
     * @notice Used to notify listeners that all pending child tokens of a given token have been rejected.
     * @dev Emitted when a token removes all a child tokens from its pending array.
     * @param tokenId ID of the token that rejected all of the pending children
     */
    event AllChildrenRejected(uint256 indexed tokenId);

    /**
     * @notice Used to notify listeners a child token has been transferred from parent token.
     * @dev Emitted when a token transfers a child from itself, transferring ownership to the root owner.
     * @param tokenId ID of the token that transferred a child token
     * @param childIndex Index of a child in the array from which it is being transferred
     * @param childAddress Address of the child token's collection smart contract
     * @param childId ID of the child token in the child token's collection smart contract
     * @param fromPending A boolean value signifying whether the token was in the pending child tokens array (`true`) or
     *  in the active child tokens array (`false`)
     * @param toZero A boolean value signifying whether the token is being transferred to the `0x0` address (`true`) or
     *  not (`false`)
     */
    event ChildTransferred(
        uint256 indexed tokenId,
        uint256 childIndex,
        address indexed childAddress,
        uint256 indexed childId,
        bool fromPending,
        bool toZero
    );

    /**
     * @notice The core child token struct, holding the information about the child tokens.
     * @return tokenId ID of the child token in the child token's collection smart contract
     * @return contractAddress Address of the child token's smart contract
     */
    struct Child {
        uint256 tokenId;
        address contractAddress;
    }

    /**
     * @notice Used to retrieve the *root* owner of a given token.
     * @dev The *root* owner of the token is an externally owned account (EOA). If the given token is child of another
     *  NFT, this will return an EOA address. Otherwise, if the token is owned by an EOA, this EOA wil be returned.
     * @param tokenId ID of the token for which the *root* owner has been retrieved
     * @return owner The *root* owner of the token
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice Used to retrieve the immediate owner of the given token.
     * @dev If the immediate owner is another token, the address returned, should be the one of the parent token's
     *  collection smart contract.
     * @param tokenId ID of the token for which the RMRK owner is being retrieved
     * @return Address of the given token's owner
     * @return The ID of the parent token. Should be `0` if the owner is an externally owned account
     * @return The boolean value signifying whether the owner is an NFT or not
     */
    function directOwnerOf(
        uint256 tokenId
    ) external view returns (address, uint256, bool);

    /**
     * @notice Used to burn a given token.
     * @dev When a token is burned, all of its child tokens are recursively burned as well.
     * @dev When specifying the maximum recursive burns, the execution will be reverted if there are more children to be
     *  burned.
     * @dev Setting the `maxRecursiveBurn` value to 0 will only attempt to burn the specified token and revert if there
     *  are any child tokens present.
     * @dev The approvals are cleared when the token is burned.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @dev Emits a {Transfer} event.
     * @param tokenId ID of the token to burn
     * @param maxRecursiveBurns Maximum number of tokens to recursively burn
     * @return Number of recursively burned children
     */
    function burn(
        uint256 tokenId,
        uint256 maxRecursiveBurns
    ) external returns (uint256);

    /**
     * @notice Used to add a child token to a given parent token.
     * @dev This adds the child token into the given parent token's pending child tokens array.
     * @dev Requirements:
     *
     *  - `directOwnerOf` on the child contract must resolve to the called contract.
     *  - the pending array of the parent contract must not be full.
     * @param parentId ID of the parent token to receive the new child token
     * @param childId ID of the new proposed child token
     * @param data Additional data with no specified format
     */
    function addChild(
        uint256 parentId,
        uint256 childId,
        bytes memory data
    ) external;

    /**
     * @notice Used to accept a pending child token for a given parent token.
     * @dev This moves the child token from parent token's pending child tokens array into the active child tokens
     *  array.
     * @param parentId ID of the parent token for which the child token is being accepted
     * @param childIndex Index of a child tokem in the given parent's pending children array
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function acceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) external;

    /**
     * @notice Used to reject all pending children of a given parent token.
     * @dev Removes the children from the pending array mapping.
     * @dev This does not update the ownership storage data on children. If necessary, ownership can be reclaimed by the
     *  rootOwner of the previous parent.
     * @dev Requirements:
     *
     * Requirements:
     *
     * - `parentId` must exist
     * @param parentId ID of the parent token for which to reject all of the pending tokens.
     * @param maxRejections Maximum number of expected children to reject, used to prevent from rejecting children which
     *  arrive just before this operation.
     */
    function rejectAllChildren(
        uint256 parentId,
        uint256 maxRejections
    ) external;

    /**
     * @notice Used to transfer a child token from a given parent token.
     * @dev When transferring a child token, the owner of the token is set to `to`, or is not updated in the event of
     *  `to` being the `0x0` address.
     * @param tokenId ID of the parent token from which the child token is being transferred
     * @param to Address to which to transfer the token to
     * @param destinationId ID of the token to receive this child token (MUST be 0 if the destination is not a token)
     * @param childIndex Index of a token we are transferring, in the array it belongs to (can be either active array or
     *  pending array)
     * @param childAddress Address of the child token's collection smart contract.
     * @param childId ID of the child token in its own collection smart contract.
     * @param isPending A boolean value indicating whether the child token being transferred is in the pending array of
     *  the parent token (`true`) or in the active array (`false`)
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) external;

    /**
     * @notice Used to retrieve the active child tokens of a given parent token.
     * @dev Returns array of Child structs existing for parent token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which to retrieve the active child tokens
     * @return An array of Child structs containing the parent token's active child tokens
     */
    function childrenOf(
        uint256 parentId
    ) external view returns (Child[] memory);

    /**
     * @notice Used to retrieve the pending child tokens of a given parent token.
     * @dev Returns array of pending Child structs existing for given parent.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which to retrieve the pending child tokens
     * @return An array of Child structs containing the parent token's pending child tokens
     */
    function pendingChildrenOf(
        uint256 parentId
    ) external view returns (Child[] memory);

    /**
     * @notice Used to retrieve a specific active child token for a given parent token.
     * @dev Returns a single Child struct locating at `index` of parent token's active child tokens array.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which the child is being retrieved
     * @param index Index of the child token in the parent token's active child tokens array
     * @return A Child struct containing data about the specified child
     */
    function childOf(
        uint256 parentId,
        uint256 index
    ) external view returns (Child memory);

    /**
     * @notice Used to retrieve a specific pending child token from a given parent token.
     * @dev Returns a single Child struct locating at `index` of parent token's active child tokens array.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param parentId ID of the parent token for which the pending child token is being retrieved
     * @param index Index of the child token in the parent token's pending child tokens array
     * @return A Child struct containting data about the specified child
     */
    function pendingChildOf(
        uint256 parentId,
        uint256 index
    ) external view returns (Child memory);

    /**
     * @notice Used to transfer the token into another token.
     * @param from Address of the direct owner of the token to be transferred
     * @param to Address of the receiving token's collection smart contract
     * @param tokenId ID of the token being transferred
     * @param destinationId ID of the token to receive the token being transferred
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function nestTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: Apache-2.0

//Generally all interactions should propagate downstream

pragma solidity ^0.8.18;

import "./IERC6059.sol";
import "../core/RMRKCore.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "../library/RMRKErrors.sol";

/**
 * @title RMRKNestable
 * @author RMRK team
 * @notice Smart contract of the RMRK Nestable module.
 * @dev This contract is hierarchy agnostic and can support an arbitrary number of nested levels up and down, as long as
 *  gas limits allow it.
 */
contract RMRKNestable is Context, IERC165, IERC721, IERC6059, RMRKCore {
    using Address for address;

    uint256 private constant _MAX_LEVELS_TO_CHECK_FOR_INHERITANCE_LOOP = 100;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approver address to approved address
    // The approver is necessary so approvals are invalidated for nested children on transfer
    // WARNING: If a child NFT returns to a previous root owner, old permissions would be active again
    mapping(uint256 => mapping(address => address)) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // ------------------- NESTABLE --------------

    // Mapping from token ID to DirectOwner struct
    mapping(uint256 => DirectOwner) private _RMRKOwners;

    // Mapping of tokenId to array of active children structs
    mapping(uint256 => Child[]) internal _activeChildren;

    // Mapping of tokenId to array of pending children structs
    mapping(uint256 => Child[]) internal _pendingChildren;

    // Mapping of child token address to child token ID to whether they are pending or active on any token
    // We might have a first extra mapping from token ID, but since the same child cannot be nested into multiple tokens
    //  we can strip it for size/gas savings.
    mapping(address => mapping(uint256 => uint256)) internal _childIsInActive;

    // -------------------------- MODIFIERS ----------------------------

    /**
     * @notice Used to verify that the caller is either the owner of the token or approved to manage it by its owner.
     * @dev If the caller is not the owner of the token or approved to manage it by its owner, the execution will be
     *  reverted.
     * @param tokenId ID of the token to check
     */
    function _onlyApprovedOrOwner(uint256 tokenId) private view {
        if (!_isApprovedOrOwner(_msgSender(), tokenId))
            revert ERC721NotApprovedOrOwner();
    }

    /**
     * @notice Used to verify that the caller is either the owner of the token or approved to manage it by its owner.
     * @param tokenId ID of the token to check
     */
    modifier onlyApprovedOrOwner(uint256 tokenId) {
        _onlyApprovedOrOwner(tokenId);
        _;
    }

    /**
     * @notice Used to verify that the caller is approved to manage the given token or it its direct owner.
     * @dev This does not delegate to ownerOf, which returns the root owner, but rater uses an owner from DirectOwner
     *  struct.
     * @dev The execution is reverted if the caller is not immediate owner or approved to manage the given token.
     * @dev Used for parent-scoped transfers.
     * @param tokenId ID of the token to check.
     */
    function _onlyApprovedOrDirectOwner(uint256 tokenId) private view {
        if (!_isApprovedOrDirectOwner(_msgSender(), tokenId))
            revert RMRKNotApprovedOrDirectOwner();
    }

    /**
     * @notice Used to verify that the caller is approved to manage the given token or is its direct owner.
     * @param tokenId ID of the token to check
     */
    modifier onlyApprovedOrDirectOwner(uint256 tokenId) {
        _onlyApprovedOrDirectOwner(tokenId);
        _;
    }

    // ----------------------------- CONSTRUCTOR ------------------------------

    /**
     * @notice Initializes the contract by setting a `name` and a `symbol` to the token collection.
     * @param name_ Name of the token collection
     * @param symbol_ Symbol of the token collection
     */
    constructor(
        string memory name_,
        string memory symbol_
    ) RMRKCore(name_, symbol_) {}

    // ------------------------------- ERC721 ---------------------------------
    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC6059).interfaceId;
    }

    /**
     * @notice Used to retrieve the number of tokens in `owner`'s account.
     * @param owner Address of the account being checked
     * @return The balance of the given account
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert ERC721AddressZeroIsNotaValidOwner();
        return _balances[owner];
    }

    ////////////////////////////////////////
    //              TRANSFERS
    ////////////////////////////////////////

    /**
     * @notice Transfers a given token from `from` to `to`.
     * @dev Requirements:
     *
     *  - `from` cannot be the zero address.
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must be owned by `from`.
     *  - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * @dev Emits a {Transfer} event.
     * @param from Address from which to transfer the token from
     * @param to Address to which to transfer the token to
     * @param tokenId ID of the token to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _transfer(from, to, tokenId, "");
    }

    /**
     * @notice Used to safely transfer a given token token from `from` to `to`.
     * @dev Requirements:
     *
     *  - `from` cannot be the zero address.
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must exist and be owned by `from`.
     *  - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *  - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * @dev Emits a {Transfer} event.
     * @param from Address to transfer the tokens from
     * @param to Address to transfer the tokens to
     * @param tokenId ID of the token to transfer
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @notice Used to safely transfer a given token token from `from` to `to`.
     * @dev Requirements:
     *
     *  - `from` cannot be the zero address.
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must exist and be owned by `from`.
     *  - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *  - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * @dev Emits a {Transfer} event.
     * @param from Address to transfer the tokens from
     * @param to Address to transfer the tokens to
     * @param tokenId ID of the token to transfer
     * @param data Additional data without a specified format to be sent along with the token transaction
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @inheritdoc IERC6059
     */
    function nestTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) public virtual onlyApprovedOrDirectOwner(tokenId) {
        _nestTransfer(from, to, tokenId, destinationId, data);
    }

    /**
     * @notice Used to safely transfer the token form `from` to `to`.
     * @dev The function checks that contract recipients are aware of the ERC721 protocol to prevent tokens from being
     *  forever locked.
     * @dev This internal function is equivalent to {safeTransferFrom}, and can be used to e.g. implement alternative
     *  mechanisms to perform token transfer, such as signature-based.
     * @dev Requirements:
     *
     *  - `from` cannot be the zero address.
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must exist and be owned by `from`.
     *  - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     * @dev Emits a {Transfer} event.
     * @param from Address of the account currently owning the given token
     * @param to Address to transfer the token to
     * @param tokenId ID of the token to transfer
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId, data);
        if (!_checkOnERC721Received(from, to, tokenId, data))
            revert ERC721TransferToNonReceiverImplementer();
    }

    /**
     * @notice Used to transfer the token from `from` to `to`.
     * @dev As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     * @dev Requirements:
     *
     *  - `to` cannot be the zero address.
     *  - `tokenId` token must be owned by `from`.
     * @dev Emits a {Transfer} event.
     * @param from Address of the account currently owning the given token
     * @param to Address to transfer the token to
     * @param tokenId ID of the token to transfer
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        (address immediateOwner, uint256 parentId, ) = directOwnerOf(tokenId);
        if (immediateOwner != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();

        _beforeTokenTransfer(from, to, tokenId);
        _beforeNestedTokenTransfer(
            immediateOwner,
            to,
            parentId,
            0,
            tokenId,
            data
        );

        _balances[from] -= 1;
        _updateOwnerAndClearApprovals(tokenId, 0, to);
        _balances[to] += 1;

        emit Transfer(from, to, tokenId);
        emit NestTransfer(immediateOwner, to, parentId, 0, tokenId);

        _afterTokenTransfer(from, to, tokenId);
        _afterNestedTokenTransfer(
            immediateOwner,
            to,
            parentId,
            0,
            tokenId,
            data
        );
    }

    /**
     * @notice Used to transfer a token into another token.
     * @dev Attempting to nest a token into `0x0` address will result in reverted transaction.
     * @dev Attempting to nest a token into itself will result in reverted transaction.
     * @param from Address of the account currently owning the given token
     * @param to Address of the receiving token's collection smart contract
     * @param tokenId ID of the token to transfer
     * @param destinationId ID of the token receiving the given token
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _nestTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) internal virtual {
        (address immediateOwner, uint256 parentId, ) = directOwnerOf(tokenId);
        if (immediateOwner != from) revert ERC721TransferFromIncorrectOwner();
        if (to == address(0)) revert ERC721TransferToTheZeroAddress();
        if (to == address(this) && tokenId == destinationId)
            revert RMRKNestableTransferToSelf();

        // Destination contract checks:
        // It seems redundant, but otherwise it would revert with no error
        if (!to.isContract()) revert RMRKIsNotContract();
        if (!IERC165(to).supportsInterface(type(IERC6059).interfaceId))
            revert RMRKNestableTransferToNonRMRKNestableImplementer();
        _checkForInheritanceLoop(tokenId, to, destinationId);

        _beforeTokenTransfer(from, to, tokenId);
        _beforeNestedTokenTransfer(
            immediateOwner,
            to,
            parentId,
            destinationId,
            tokenId,
            data
        );
        _balances[from] -= 1;
        _updateOwnerAndClearApprovals(tokenId, destinationId, to);
        _balances[to] += 1;

        // Sending to NFT:
        _sendToNFT(immediateOwner, to, parentId, destinationId, tokenId, data);
    }

    /**
     * @notice Used to send a token to another token.
     * @dev If the token being sent is currently owned by an externally owned account, the `parentId` should equal `0`.
     * @dev Emits {Transfer} event.
     * @dev Emits {NestTransfer} event.
     * @param from Address from which the token is being sent
     * @param to Address of the collection smart contract of the token to receive the given token
     * @param parentId ID of the current parent token of the token being sent
     * @param destinationId ID of the tokento receive the token being sent
     * @param tokenId ID of the token being sent
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _sendToNFT(
        address from,
        address to,
        uint256 parentId,
        uint256 destinationId,
        uint256 tokenId,
        bytes memory data
    ) private {
        IERC6059 destContract = IERC6059(to);
        destContract.addChild(destinationId, tokenId, data);

        emit Transfer(from, to, tokenId);
        emit NestTransfer(from, to, parentId, destinationId, tokenId);

        _afterTokenTransfer(from, to, tokenId);
        _afterNestedTokenTransfer(
            from,
            to,
            parentId,
            destinationId,
            tokenId,
            data
        );
    }

    /**
     * @notice Used to check if nesting a given token into a specified token would create an inheritance loop.
     * @dev If a loop would occur, the tokens would be unmanageable, so the execution is reverted if one is detected.
     * @dev The check for inheritance loop is bounded to guard against too much gas being consumed.
     * @param currentId ID of the token that would be nested
     * @param targetContract Address of the collection smart contract of the token into which the given token would be
     *  nested
     * @param targetId ID of the token into which the given token would be nested
     */
    function _checkForInheritanceLoop(
        uint256 currentId,
        address targetContract,
        uint256 targetId
    ) private view {
        for (uint256 i; i < _MAX_LEVELS_TO_CHECK_FOR_INHERITANCE_LOOP; ) {
            (
                address nextOwner,
                uint256 nextOwnerTokenId,
                bool isNft
            ) = IERC6059(targetContract).directOwnerOf(targetId);
            // If there's a final address, we're good. There's no loop.
            if (!isNft) {
                return;
            }
            // Ff the current nft is an ancestor at some point, there is an inheritance loop
            if (nextOwner == address(this) && nextOwnerTokenId == currentId) {
                revert RMRKNestableTransferToDescendant();
            }
            // We reuse the parameters to save some contract size
            targetContract = nextOwner;
            targetId = nextOwnerTokenId;
            unchecked {
                ++i;
            }
        }
        revert RMRKNestableTooDeep();
    }

    ////////////////////////////////////////
    //              MINTING
    ////////////////////////////////////////

    /**
     * @notice Used to safely mint the token to the specified address while passing the additional data to contract
     *  recipients.
     * @param to Address to which to mint the token
     * @param tokenId ID of the token to mint
     * @param data Additional data to send with the tokens
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId, data);
        if (!_checkOnERC721Received(address(0), to, tokenId, data))
            revert ERC721TransferToNonReceiverImplementer();
    }

    /**
     * @notice Used to mint a specified token to a given address.
     * @dev WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible.
     * @dev Requirements:
     *
     *  - `tokenId` must not exist.
     *  - `to` cannot be the zero address.
     * @dev Emits a {Transfer} event.
     * @dev Emits a {NestTransfer} event.
     * @param to Address to mint the token to
     * @param tokenId ID of the token to mint
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _mint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _innerMint(to, tokenId, 0, data);

        emit Transfer(address(0), to, tokenId);
        emit NestTransfer(address(0), to, 0, 0, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
        _afterNestedTokenTransfer(address(0), to, 0, 0, tokenId, data);
    }

    /**
     * @notice Used to mint a child token to a given parent token.
     * @param to Address of the collection smart contract of the token into which to mint the child token
     * @param tokenId ID of the token to mint
     * @param destinationId ID of the token into which to mint the new child token
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _nestMint(
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) internal virtual {
        // It seems redundant, but otherwise it would revert with no error
        if (!to.isContract()) revert RMRKIsNotContract();
        if (!IERC165(to).supportsInterface(type(IERC6059).interfaceId))
            revert RMRKMintToNonRMRKNestableImplementer();

        _innerMint(to, tokenId, destinationId, data);
        _sendToNFT(address(0), to, 0, destinationId, tokenId, data);
    }

    /**
     * @notice Used to mint a child token into a given parent token.
     * @dev Requirements:
     *
     *  - `to` cannot be the zero address.
     *  - `tokenId` must not exist.
     *  - `tokenId` must not be `0`.
     * @param to Address of the collection smart contract of the token into which to mint the child token
     * @param tokenId ID of the token to mint
     * @param destinationId ID of the token into which to mint the new token
     * @param data Additional data with no specified format, sent in call to `to`
     */
    function _innerMint(
        address to,
        uint256 tokenId,
        uint256 destinationId,
        bytes memory data
    ) private {
        if (to == address(0)) revert ERC721MintToTheZeroAddress();
        if (_exists(tokenId)) revert ERC721TokenAlreadyMinted();
        if (tokenId == uint256(0)) revert RMRKIdZeroForbidden();

        _beforeTokenTransfer(address(0), to, tokenId);
        _beforeNestedTokenTransfer(
            address(0),
            to,
            0,
            destinationId,
            tokenId,
            data
        );

        _balances[to] += 1;
        _RMRKOwners[tokenId] = DirectOwner({
            ownerAddress: to,
            tokenId: destinationId
        });
    }

    ////////////////////////////////////////
    //              Ownership
    ////////////////////////////////////////

    /**
     * @inheritdoc IERC6059
     */
    function ownerOf(
        uint256 tokenId
    ) public view virtual override(IERC6059, IERC721) returns (address) {
        (address owner, uint256 ownerTokenId, bool isNft) = directOwnerOf(
            tokenId
        );
        if (isNft) {
            owner = IERC6059(owner).ownerOf(ownerTokenId);
        }
        return owner;
    }

    /**
     * @inheritdoc IERC6059
     */
    function directOwnerOf(
        uint256 tokenId
    ) public view virtual returns (address, uint256, bool) {
        DirectOwner memory owner = _RMRKOwners[tokenId];
        if (owner.ownerAddress == address(0)) revert ERC721InvalidTokenId();

        return (owner.ownerAddress, owner.tokenId, owner.tokenId != 0);
    }

    ////////////////////////////////////////
    //              BURNING
    ////////////////////////////////////////

    /**
     * @notice Used to burn a given token.
     * @dev In case the token has any child tokens, the execution will be reverted.
     * @param tokenId ID of the token to burn
     */
    function burn(uint256 tokenId) public virtual {
        burn(tokenId, 0);
    }

    /**
     * @inheritdoc IERC6059
     */
    function burn(
        uint256 tokenId,
        uint256 maxChildrenBurns
    ) public virtual onlyApprovedOrDirectOwner(tokenId) returns (uint256) {
        return _burn(tokenId, maxChildrenBurns);
    }

    /**
     * @notice Used to burn a token.
     * @dev When a token is burned, its children are recursively burned as well.
     * @dev The approvals are cleared when the token is burned.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @dev Emits a {Transfer} event.
     * @dev Emits a {NestTransfer} event.
     * @param tokenId ID of the token to burn
     * @param maxChildrenBurns Maximum children to recursively burn
     * @return The number of recursive burns it took to burn all of the children
     */
    function _burn(
        uint256 tokenId,
        uint256 maxChildrenBurns
    ) internal virtual returns (uint256) {
        (address immediateOwner, uint256 parentId, ) = directOwnerOf(tokenId);
        address owner = ownerOf(tokenId);
        _balances[immediateOwner] -= 1;

        _beforeTokenTransfer(owner, address(0), tokenId);
        _beforeNestedTokenTransfer(
            immediateOwner,
            address(0),
            parentId,
            0,
            tokenId,
            ""
        );

        _approve(address(0), tokenId);
        _cleanApprovals(tokenId);

        Child[] memory children = childrenOf(tokenId);

        delete _activeChildren[tokenId];
        delete _pendingChildren[tokenId];
        delete _tokenApprovals[tokenId][owner];

        uint256 pendingRecursiveBurns;
        uint256 totalChildBurns;

        uint256 length = children.length; //gas savings
        for (uint256 i; i < length; ) {
            if (totalChildBurns >= maxChildrenBurns)
                revert RMRKMaxRecursiveBurnsReached(
                    children[i].contractAddress,
                    children[i].tokenId
                );
            delete _childIsInActive[children[i].contractAddress][
                children[i].tokenId
            ];
            unchecked {
                // At this point we know pendingRecursiveBurns must be at least 1
                pendingRecursiveBurns = maxChildrenBurns - totalChildBurns;
            }
            // We substract one to the next level to count for the token being burned, then add it again on returns
            // This is to allow the behavior of 0 recursive burns meaning only the current token is deleted.
            totalChildBurns +=
                IERC6059(children[i].contractAddress).burn(
                    children[i].tokenId,
                    pendingRecursiveBurns - 1
                ) +
                1;
            unchecked {
                ++i;
            }
        }
        // Can't remove before burning child since child will call back to get root owner
        delete _RMRKOwners[tokenId];

        emit Transfer(owner, address(0), tokenId);
        emit NestTransfer(immediateOwner, address(0), parentId, 0, tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
        _afterNestedTokenTransfer(
            immediateOwner,
            address(0),
            parentId,
            0,
            tokenId,
            ""
        );

        return totalChildBurns;
    }

    ////////////////////////////////////////
    //              APPROVALS
    ////////////////////////////////////////

    /**
     * @notice Used to grant a one-time approval to manage one's token.
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * @dev The approval is cleared when the token is transferred.
     * @dev Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     * @dev Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     * @dev Emits an {Approval} event.
     * @param to Address receiving the approval
     * @param tokenId ID of the token for which the approval is being granted
     */
    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) revert ERC721ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert ERC721ApproveCallerIsNotOwnerNorApprovedForAll();

        _approve(to, tokenId);
    }

    /**
     * @notice Used to retrieve the account approved to manage given token.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @param tokenId ID of the token to check for approval
     * @return Address of the account approved to manage the token
     */
    function getApproved(
        uint256 tokenId
    ) public view virtual returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId][ownerOf(tokenId)];
    }

    /**
     * @notice Used to approve or remove `operator` as an operator for the caller.
     * @dev Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     * @dev Requirements:
     *
     * - The `operator` cannot be the caller.
     * @dev Emits an {ApprovalForAll} event.
     * @param operator Address of the operator being managed
     * @param approved A boolean value signifying whether the approval is being granted (`true`) or (`revoked`)
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        if (_msgSender() == operator) revert ERC721ApproveToCaller();
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @notice Used to check if the given address is allowed to manage the tokens of the specified address.
     * @param owner Address of the owner of the tokens
     * @param operator Address being checked for approval
     * @return A boolean value signifying whether the *operator* is allowed to manage the tokens of the *owner* (`true`)
     *  or not (`false`)
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @notice Used to grant an approval to manage a given token.
     * @dev Emits an {Approval} event.
     * @param to Address to which the approval is being granted
     * @param tokenId ID of the token for which the approval is being granted
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _tokenApprovals[tokenId][owner] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @notice Used to update the owner of the token and clear the approvals associated with the previous owner.
     * @dev The `destinationId` should equal `0` if the new owner is an externally owned account.
     * @param tokenId ID of the token being updated
     * @param destinationId ID of the token to receive the given token
     * @param to Address of account to receive the token
     */
    function _updateOwnerAndClearApprovals(
        uint256 tokenId,
        uint256 destinationId,
        address to
    ) internal {
        _RMRKOwners[tokenId] = DirectOwner({
            ownerAddress: to,
            tokenId: destinationId
        });

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _cleanApprovals(tokenId);
    }

    /**
     * @notice Used to remove approvals for the current owner of the given token.
     * @param tokenId ID of the token to clear the approvals for
     */
    function _cleanApprovals(uint256 tokenId) internal virtual {}

    ////////////////////////////////////////
    //              UTILS
    ////////////////////////////////////////

    /**
     * @notice Used to check whether the given account is allowed to manage the given token.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @param spender Address that is being checked for approval
     * @param tokenId ID of the token being checked
     * @return A boolean value indicating whether the `spender` is approved to manage the given token
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @notice Used to check whether the account is approved to manage the token or its direct owner.
     * @param spender Address that is being checked for approval or direct ownership
     * @param tokenId ID of the token being checked
     * @return A boolean value indicating whether the `spender` is approved to manage the given token or its
     *  direct owner
     */
    function _isApprovedOrDirectOwner(
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        (address owner, uint256 parentId, ) = directOwnerOf(tokenId);
        // When the parent is an NFT, only it can do operations
        if (parentId != 0) {
            return (spender == owner);
        }
        // Otherwise, the owner or approved address can
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @notice Used to enforce that the given token has been minted.
     * @dev Reverts if the `tokenId` has not been minted yet.
     * @dev The validation checks whether the owner of a given token is a `0x0` address and considers it not minted if
     *  it is. This means that both tokens that haven't been minted yet as well as the ones that have already been
     *  burned will cause the transaction to be reverted.
     * @param tokenId ID of the token to check
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        if (!_exists(tokenId)) revert ERC721InvalidTokenId();
    }

    /**
     * @notice Used to check whether the given token exists.
     * @dev Tokens start existing when they are minted (`_mint`) and stop existing when they are burned (`_burn`).
     * @param tokenId ID of the token being checked
     * @return A boolean value signifying whether the token exists
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _RMRKOwners[tokenId].ownerAddress != address(0);
    }

    /**
     * @notice Used to invoke {IERC721Receiver-onERC721Received} on a target address.
     * @dev The call is not executed if the target address is not a contract.
     * @param from Address representing the previous owner of the given token
     * @param to Yarget address that will receive the tokens
     * @param tokenId ID of the token to be transferred
     * @param data Optional data to send along with the call
     * @return Boolean value signifying whether the call correctly returned the expected magic value
     */
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
                if (reason.length == uint256(0)) {
                    revert ERC721TransferToNonReceiverImplementer();
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

    ////////////////////////////////////////
    //      CHILD MANAGEMENT PUBLIC
    ////////////////////////////////////////

    /**
     * @inheritdoc IERC6059
     */
    function addChild(
        uint256 parentId,
        uint256 childId,
        bytes memory data
    ) public virtual {
        _requireMinted(parentId);

        address childAddress = _msgSender();
        if (!childAddress.isContract()) revert RMRKIsNotContract();

        Child memory child = Child({
            contractAddress: childAddress,
            tokenId: childId
        });

        _beforeAddChild(parentId, childAddress, childId, data);

        uint256 length = pendingChildrenOf(parentId).length;

        if (length < 128) {
            _pendingChildren[parentId].push(child);
        } else {
            revert RMRKMaxPendingChildrenReached();
        }

        // Previous length matches the index for the new child
        emit ChildProposed(parentId, length, childAddress, childId);

        _afterAddChild(parentId, childAddress, childId, data);
    }

    /**
     * @inheritdoc IERC6059
     */
    function acceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) public virtual onlyApprovedOrOwner(parentId) {
        _acceptChild(parentId, childIndex, childAddress, childId);
    }

    /**
     * @notice Used to accept a pending child token for a given parent token.
     * @dev This moves the child token from parent token's pending child tokens array into the active child tokens
     *  array.
     * @dev Requirements:
     *
     *  - `tokenId` must exist
     *  - `index` must be in range of the pending children array
     * @dev Emits ***ChildAccepted*** event.
     * @param parentId ID of the parent token for which the child token is being accepted
     * @param childIndex Index of a child tokem in the given parent's pending children array
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function _acceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) internal virtual {
        Child memory child = pendingChildOf(parentId, childIndex);
        _checkExpectedChild(child, childAddress, childId);
        if (_childIsInActive[childAddress][childId] != 0)
            revert RMRKChildAlreadyExists();

        _beforeAcceptChild(parentId, childIndex, childAddress, childId);

        // Remove from pending:
        _removeChildByIndex(_pendingChildren[parentId], childIndex);

        // Add to active:
        _activeChildren[parentId].push(child);
        _childIsInActive[childAddress][childId] = 1; // We use 1 as true

        emit ChildAccepted(parentId, childIndex, childAddress, childId);

        _afterAcceptChild(parentId, childIndex, childAddress, childId);
    }

    /**
     * @inheritdoc IERC6059
     */
    function rejectAllChildren(
        uint256 tokenId,
        uint256 maxRejections
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _rejectAllChildren(tokenId, maxRejections);
    }

    /**
     * @notice Used to reject all pending children of a given parent token.
     * @dev Removes the children from the pending array mapping.
     * @dev This does not update the ownership storage data on children. If necessary, ownership can be reclaimed by the
     *  rootOwner of the previous parent.
     * @dev Requirements:
     *
     *  - `tokenId` must exist
     * @dev Emits ***AllChildrenRejected*** event.
     * @param tokenId ID of the parent token for which to reject all of the pending tokens.
     * @param maxRejections Maximum number of expected children to reject, used to prevent from rejecting children which
     *  arrive just before this operation.
     */
    function _rejectAllChildren(
        uint256 tokenId,
        uint256 maxRejections
    ) internal virtual {
        if (_pendingChildren[tokenId].length > maxRejections)
            revert RMRKUnexpectedNumberOfChildren();

        _beforeRejectAllChildren(tokenId);
        delete _pendingChildren[tokenId];
        emit AllChildrenRejected(tokenId);
        _afterRejectAllChildren(tokenId);
    }

    /**
     * @inheritdoc IERC6059
     */
    function transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) public virtual onlyApprovedOrOwner(tokenId) {
        _transferChild(
            tokenId,
            to,
            destinationId,
            childIndex,
            childAddress,
            childId,
            isPending,
            data
        );
    }

    /**
     * @notice Used to transfer a child token from a given parent token.
     * @dev When transferring a child token, the owner of the token is set to `to`, or is not updated in the event of
     *  `to` being the `0x0` address.
     * @dev Requirements:
     *
     *  - `tokenId` must exist.
     * @dev Emits {ChildTransferred} event.
     * @param tokenId ID of the parent token from which the child token is being transferred
     * @param to Address to which to transfer the token to
     * @param destinationId ID of the token to receive this child token (MUST be 0 if the destination is not a token)
     * @param childIndex Index of a token we are transferring, in the array it belongs to (can be either active array or
     *  pending array)
     * @param childAddress Address of the child token's collection smart contract.
     * @param childId ID of the child token in its own collection smart contract.
     * @param isPending A boolean value indicating whether the child token being transferred is in the pending array of
     *  the parent token (`true`) or in the active array (`false`)
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function _transferChild(
        uint256 tokenId,
        address to,
        uint256 destinationId, // newParentId
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) internal virtual {
        Child memory child;
        if (isPending) {
            child = pendingChildOf(tokenId, childIndex);
        } else {
            child = childOf(tokenId, childIndex);
        }
        _checkExpectedChild(child, childAddress, childId);

        _beforeTransferChild(
            tokenId,
            childIndex,
            childAddress,
            childId,
            isPending,
            data
        );

        if (isPending) {
            _removeChildByIndex(_pendingChildren[tokenId], childIndex);
        } else {
            delete _childIsInActive[childAddress][childId];
            _removeChildByIndex(_activeChildren[tokenId], childIndex);
        }

        if (to != address(0)) {
            if (destinationId == uint256(0)) {
                IERC721(childAddress).safeTransferFrom(
                    address(this),
                    to,
                    childId,
                    data
                );
            } else {
                // Destination is an NFT
                IERC6059(child.contractAddress).nestTransferFrom(
                    address(this),
                    to,
                    child.tokenId,
                    destinationId,
                    data
                );
            }
        }

        emit ChildTransferred(
            tokenId,
            childIndex,
            childAddress,
            childId,
            isPending,
            to == address(0)
        );
        _afterTransferChild(
            tokenId,
            childIndex,
            childAddress,
            childId,
            isPending,
            data
        );
    }

    /**
     * @notice Used to verify that the child being accessed is the intended child.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param child A Child struct of a child being accessed
     * @param expectedAddress The address expected to be the one of the child
     * @param expectedId The token ID expected to be the one of the child
     */
    function _checkExpectedChild(
        Child memory child,
        address expectedAddress,
        uint256 expectedId
    ) private pure {
        if (
            expectedAddress != child.contractAddress ||
            expectedId != child.tokenId
        ) revert RMRKUnexpectedChildId();
    }

    ////////////////////////////////////////
    //      CHILD MANAGEMENT GETTERS
    ////////////////////////////////////////

    /**
     * @inheritdoc IERC6059
     */

    function childrenOf(
        uint256 parentId
    ) public view virtual returns (Child[] memory) {
        Child[] memory children = _activeChildren[parentId];
        return children;
    }

    /**
     * @inheritdoc IERC6059
     */

    function pendingChildrenOf(
        uint256 parentId
    ) public view virtual returns (Child[] memory) {
        Child[] memory pendingChildren = _pendingChildren[parentId];
        return pendingChildren;
    }

    /**
     * @inheritdoc IERC6059
     */
    function childOf(
        uint256 parentId,
        uint256 index
    ) public view virtual returns (Child memory) {
        if (childrenOf(parentId).length <= index)
            revert RMRKChildIndexOutOfRange();
        Child memory child = _activeChildren[parentId][index];
        return child;
    }

    /**
     * @inheritdoc IERC6059
     */
    function pendingChildOf(
        uint256 parentId,
        uint256 index
    ) public view virtual returns (Child memory) {
        if (pendingChildrenOf(parentId).length <= index)
            revert RMRKPendingChildIndexOutOfRange();
        Child memory child = _pendingChildren[parentId][index];
        return child;
    }

    // HOOKS

    /**
     * @notice Hook that is called before nested token transfer.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token is being transferred
     * @param to Address to which the token is being transferred
     * @param fromTokenId ID of the token from which the given token is being transferred
     * @param toTokenId ID of the token to which the given token is being transferred
     * @param tokenId ID of the token being transferred
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _beforeNestedTokenTransfer(
        address from,
        address to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called after nested token transfer.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param from Address from which the token was transferred
     * @param to Address to which the token was transferred
     * @param fromTokenId ID of the token from which the given token was transferred
     * @param toTokenId ID of the token to which the given token was transferred
     * @param tokenId ID of the token that was transferred
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _afterNestedTokenTransfer(
        address from,
        address to,
        uint256 fromTokenId,
        uint256 toTokenId,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is added to the pending tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will receive a new pending child token
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     * @param data Additional data with no specified format
     */
    function _beforeAddChild(
        uint256 tokenId,
        address childAddress,
        uint256 childId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is added to the pending tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has received a new pending child token
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     * @param data Additional data with no specified format
     */
    function _afterAddChild(
        uint256 tokenId,
        address childAddress,
        uint256 childId,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is accepted to the active tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param parentId ID of the token that will accept a pending child token
     * @param childIndex Index of the child token to accept in the given parent token's pending children array
     * @param childAddress Address of the collection smart contract of the child token expected to be located at the
     *  specified index of the given parent token's pending children array
     * @param childId ID of the child token expected to be located at the specified index of the given parent token's
     *  pending children array
     */
    function _beforeAcceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is accepted to the active tokens array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param parentId ID of the token that has accepted a pending child token
     * @param childIndex Index of the child token that was accpeted in the given parent token's pending children array
     * @param childAddress Address of the collection smart contract of the child token that was expected to be located
     *  at the specified index of the given parent token's pending children array
     * @param childId ID of the child token that was expected to be located at the specified index of the given parent
     *  token's pending children array
     */
    function _afterAcceptChild(
        uint256 parentId,
        uint256 childIndex,
        address childAddress,
        uint256 childId
    ) internal virtual {}

    /**
     * @notice Hook that is called before a child is transferred from a given child token array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will transfer a child token
     * @param childIndex Index of the child token that will be transferred from the given parent token's children array
     * @param childAddress Address of the collection smart contract of the child token that is expected to be located
     *  at the specified index of the given parent token's children array
     * @param childId ID of the child token that is expected to be located at the specified index of the given parent
     *  token's children array
     * @param isPending A boolean value signifying whether the child token is being transferred from the pending child
     *  tokens array (`true`) or from the active child tokens array (`false`)
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _beforeTransferChild(
        uint256 tokenId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called after a child is transferred from a given child token array of a given token.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has transferred a child token
     * @param childIndex Index of the child token that was transferred from the given parent token's children array
     * @param childAddress Address of the collection smart contract of the child token that was expected to be located
     *  at the specified index of the given parent token's children array
     * @param childId ID of the child token that was expected to be located at the specified index of the given parent
     *  token's children array
     * @param isPending A boolean value signifying whether the child token was transferred from the pending child tokens
     *  array (`true`) or from the active child tokens array (`false`)
     * @param data Additional data with no specified format, sent in the addChild call
     */
    function _afterTransferChild(
        uint256 tokenId,
        uint256 childIndex,
        address childAddress,
        uint256 childId,
        bool isPending,
        bytes memory data
    ) internal virtual {}

    /**
     * @notice Hook that is called before a pending child tokens array of a given token is cleared.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that will reject all of the pending child tokens
     */
    function _beforeRejectAllChildren(uint256 tokenId) internal virtual {}

    /**
     * @notice Hook that is called after a pending child tokens array of a given token is cleared.
     * @dev To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @param tokenId ID of the token that has rejected all of the pending child tokens
     */
    function _afterRejectAllChildren(uint256 tokenId) internal virtual {}

    // HELPERS

    /**
     * @notice Used to remove a specified child token form an array using its index within said array.
     * @dev The caller must ensure that the length of the array is valid compared to the index passed.
     * @dev The Child struct consists of the following values:
     *  [
     *      tokenId,
     *      contractAddress
     *  ]
     * @param array An array od Child struct containing info about the child tokens in a given child tokens array
     * @param index An index of the child token to remove in the accompanying array
     */
    function _removeChildByIndex(Child[] storage array, uint256 index) private {
        array[index] = array[array.length - 1];
        array.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.18;

error RentrantCall();

/**
 * @title ReentrancyGuard
 * @notice Smart contract used to guard against potential reentrancy exploits.
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

    /**
     * @notice Initializes the ReentrancyGuard with the `_status` of `_NOT_ENTERED`.
     */
    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @notice Used to ensure that the function it is applied to cannot be reentered.
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantIn();
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @notice Used to ensure that the current call is not a reentrant call.
     * @dev If reentrant call is detected, the execution will be reverted.
     */
    function _nonReentrantIn() private {
        // On the first call to nonReentrant, _notEntered will be true
        if (_status == _ENTERED) revert RentrantCall();

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "./RMRKRenderUtils.sol";
import "./RMRKMultiAssetRenderUtils.sol";
import "./RMRKNestableRenderUtils.sol";
import "../catalog/IRMRKCatalog.sol";
import "../equippable/IERC6220.sol";
import "../nestable/IERC6059.sol";
import "../library/RMRKLib.sol";
import "../library/RMRKErrors.sol";

/**
 * @title RMRKEquipRenderUtils
 * @author RMRK team
 * @notice Smart contract of the RMRK Equip render utils module.
 * @dev Extra utility functions for composing RMRK extended assets.
 */
contract RMRKEquipRenderUtils is
    RMRKRenderUtils,
    RMRKMultiAssetRenderUtils,
    RMRKNestableRenderUtils
{
    using RMRKLib for uint64[];

    /**
     * @notice The structure used to display a full information of an active asset.
     * @return id ID of the asset
     * @return equppableGroupId ID of the equippable group this asset belongs to
     * @return priority Priority of the asset in the active assets array it belongs to
     * @return catalogAddress Address of the `Catalog` smart contract this asset belongs to
     * @return metadata Metadata URI of the asset
     * @return partIds[] An array of IDs of fixed and slot parts present in the asset
     */
    struct ExtendedEquippableActiveAsset {
        uint64 id;
        uint64 equippableGroupId;
        uint64 priority;
        address catalogAddress;
        string metadata;
        uint64[] partIds;
    }

    /**
     * @notice The structure used to display a full information of a pending asset.
     * @return id ID of the asset
     * @return equppableGroupId ID of the equippable group this asset belongs to
     * @return acceptRejectIndex The index of the given asset in the pending assets array it belongs to
     * @return replacesAssetWithId ID of the asset the given asset will replace if accepted
     * @return catalogAddress Address of the `Catalog` smart contract this asset belongs to
     * @return metadata Metadata URI of the asset
     * @return partIds[] An array of IDs of fixed and slot parts present in the asset
     */
    struct ExtendedPendingAsset {
        uint64 id;
        uint64 equippableGroupId;
        uint128 acceptRejectIndex;
        uint64 replacesAssetWithId;
        address catalogAddress;
        string metadata;
        uint64[] partIds;
    }

    /**
     * @notice The structure used to display a full information of an equippend slot part.
     * @return partId ID of the slot part
     * @return childAssetId ID of the child asset equipped into the slot part
     * @return z The z value of the part defining how it should be rendered when presenting the full NFT
     * @return childAddress Address of the collection smart contract of the child token equipped into the slot
     * @return childId ID of the child token equipped into the slot
     * @return childAssetMetadata Metadata URI of the child token equipped into the slot
     * @return partMetadata Metadata URI of the given slot part
     */
    struct EquippedSlotPart {
        uint64 partId;
        uint64 childAssetId;
        uint8 z; //1 byte
        address childAddress;
        uint256 childId;
        string childAssetMetadata; //n bytes 32+
        string partMetadata; //n bytes 32+
    }

    /**
     * @notice Used to provide data about fixed parts.
     * @return partId ID of the part
     * @return z The z value of the asset, specifying how the part should be rendered in a composed NFT
     * @return matadataURI The metadata URI of the fixed part
     */
    struct FixedPart {
        uint64 partId;
        uint8 z; //1 byte
        string metadataURI; //n bytes 32+
    }

    /**
     * @notice The structure used to represent an asset with a Slot.
     * @return slotPartId ID of the Slot part
     * @return childAssetId ID of the child asset which is equippable into the slot part
     * @return parentAssetId ID of the parent asset which can receive the slot part
     * @return priority Priority of the asset on the active assets list
     * @return parentCatalogAddress Catalog address of the parent asset
     * @return isEquipped Whether the asset is currently equipped into the slot part or not
     * @return partMetadata Metadata URI of the given slot part
     * @return childAssetMetadata Metadata URI of the child asset
     * @return parentAssetMetadata Metadata URI of the parent asset
     */
    struct EquippableData {
        uint64 slotPartId;
        uint64 childAssetId;
        uint64 parentAssetId;
        uint64 priority;
        address parentCatalogAddress;
        bool isEquipped;
        string partMetadata;
        string childAssetMetadata;
        string parentAssetMetadata;
    }

    struct ChildWithTopAssetMetadata {
        address contractAddress;
        uint256 tokenId;
        string metadata;
    }

    /**
     * @notice Used to get extended active assets of the given token.
     * @dev The full `ExtendedEquippableActiveAsset` looks like this:
     *  [
     *      ID,
     *      equippableGroupId,
     *      priority,
     *      catalogAddress,
     *      metadata,
     *      [
     *          fixedPartId0,
     *          fixedPartId1,
     *          fixedPartId2,
     *          slotPartId0,
     *          slotPartId1,
     *          slotPartId2
     *      ]
     *  ]
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token to retrieve the extended active assets for
     * @return An array of ExtendedEquippableActiveAssets present on the given token
     */
    function getExtendedEquippableActiveAssets(
        address target,
        uint256 tokenId
    ) public view virtual returns (ExtendedEquippableActiveAsset[] memory) {
        IERC6220 target_ = IERC6220(target);

        uint64[] memory assets = target_.getActiveAssets(tokenId);
        uint64[] memory priorities = target_.getActiveAssetPriorities(tokenId);
        uint256 len = assets.length;
        if (len == uint256(0)) {
            revert RMRKTokenHasNoAssets();
        }

        ExtendedEquippableActiveAsset[]
            memory activeAssets = new ExtendedEquippableActiveAsset[](len);

        for (uint256 i; i < len; ) {
            (
                string memory metadataURI,
                uint64 equippableGroupId,
                address catalogAddress,
                uint64[] memory partIds
            ) = target_.getAssetAndEquippableData(tokenId, assets[i]);
            activeAssets[i] = ExtendedEquippableActiveAsset({
                id: assets[i],
                equippableGroupId: equippableGroupId,
                priority: priorities[i],
                catalogAddress: catalogAddress,
                metadata: metadataURI,
                partIds: partIds
            });
            unchecked {
                ++i;
            }
        }
        return activeAssets;
    }

    /**
     * @notice Used to get the extended pending assets of the given token.
     * @dev The full `ExtendedPendingAsset` looks like this:
     *  [
     *      ID,
     *      equippableGroupId,
     *      acceptRejectIndex,
     *      replacesAssetWithId,
     *      catalogAddress,
     *      metadata,
     *      [
     *          fixedPartId0,
     *          fixedPartId1,
     *          fixedPartId2,
     *          slotPartId0,
     *          slotPartId1,
     *          slotPartId2
     *      ]
     *  ]
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token to retrieve the extended pending assets for
     * @return An array of ExtendedPendingAssets present on the given token
     */
    function getExtendedPendingAssets(
        address target,
        uint256 tokenId
    ) public view virtual returns (ExtendedPendingAsset[] memory) {
        IERC6220 target_ = IERC6220(target);

        uint64[] memory assets = target_.getPendingAssets(tokenId);
        uint256 len = assets.length;
        if (len == uint256(0)) {
            revert RMRKTokenHasNoAssets();
        }

        ExtendedPendingAsset[]
            memory pendingAssets = new ExtendedPendingAsset[](len);
        uint64 replacesAssetWithId;
        for (uint256 i; i < len; ) {
            (
                string memory metadataURI,
                uint64 equippableGroupId,
                address catalogAddress,
                uint64[] memory partIds
            ) = target_.getAssetAndEquippableData(tokenId, assets[i]);
            replacesAssetWithId = target_.getAssetReplacements(
                tokenId,
                assets[i]
            );
            pendingAssets[i] = ExtendedPendingAsset({
                id: assets[i],
                equippableGroupId: equippableGroupId,
                acceptRejectIndex: uint128(i),
                replacesAssetWithId: replacesAssetWithId,
                catalogAddress: catalogAddress,
                metadata: metadataURI,
                partIds: partIds
            });
            unchecked {
                ++i;
            }
        }
        return pendingAssets;
    }

    /**
     * @notice Used to retrieve the equipped parts of the given token.
     * @dev NOTE: Some of the equipped children might be empty.
     * @dev The full `Equipment` struct looks like this:
     *  [
     *      assetId,
     *      childAssetId,
     *      childId,
     *      childEquippableAddress
     *  ]
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token to retrieve the equipped items in the asset for
     * @param assetId ID of the asset being queried for equipped parts
     * @return slotPartIds An array of the IDs of the slot parts present in the given asset
     * @return childrenEquipped An array of `Equipment` structs containing info about the equipped children
     * @return childrenAssetMetadata An array of strings corresponding to asset metadata of the equipped children
     */
    function getEquipped(
        address target,
        uint64 tokenId,
        uint64 assetId
    )
        public
        view
        returns (
            uint64[] memory slotPartIds,
            IERC6220.Equipment[] memory childrenEquipped,
            string[] memory childrenAssetMetadata
        )
    {
        IERC6220 target_ = IERC6220(target);

        (, , address catalogAddress, uint64[] memory partIds) = target_
            .getAssetAndEquippableData(tokenId, assetId);

        (slotPartIds, ) = splitSlotAndFixedParts(partIds, catalogAddress);
        uint256 len = slotPartIds.length;

        childrenEquipped = new IERC6220.Equipment[](len);
        childrenAssetMetadata = new string[](len);

        for (uint256 i; i < len; ) {
            IERC6220.Equipment memory equipment = target_.getEquipment(
                tokenId,
                catalogAddress,
                slotPartIds[i]
            );
            if (equipment.assetId == assetId) {
                childrenEquipped[i] = equipment;
                childrenAssetMetadata[i] = IERC6220(
                    equipment.childEquippableAddress
                ).getAssetMetadata(equipment.childId, equipment.childAssetId);
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to compose the given equippables.
     * @dev The full `FixedPart` struct looks like this:
     *  [
     *      partId,
     *      z,
     *      metadataURI
     *  ]
     * @dev The full `EquippedSlotPart` struct looks like this:
     *  [
     *      partId,
     *      childAssetId,
     *      z,
     *      childAddress,
     *      childId,
     *      childAssetMetadata,
     *      partMetadata
     *  ]
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token to compose the equipped items in the asset for
     * @param assetId ID of the asset being queried for equipped parts
     * @return metadataURI Metadata URI of the asset
     * @return equippableGroupId Equippable group ID of the asset
     * @return catalogAddress Address of the catalog to which the asset belongs to
     * @return fixedParts An array of fixed parts respresented by the `FixedPart` structs present on the asset
     * @return slotParts An array of slot parts represented by the `EquippedSlotPart` structs present on the asset
     */
    function composeEquippables(
        address target,
        uint256 tokenId,
        uint64 assetId
    )
        public
        view
        returns (
            string memory metadataURI,
            uint64 equippableGroupId,
            address catalogAddress,
            FixedPart[] memory fixedParts,
            EquippedSlotPart[] memory slotParts
        )
    {
        IERC6220 target_ = IERC6220(target);
        uint64[] memory partIds;

        // If token does not have uint64[] memory slotPartId to save the asset, it would fail here.
        (metadataURI, equippableGroupId, catalogAddress, partIds) = target_
            .getAssetAndEquippableData(tokenId, assetId);
        if (catalogAddress == address(0)) revert RMRKNotComposableAsset();

        (
            uint64[] memory slotPartIds,
            uint64[] memory fixedPartIds
        ) = splitSlotAndFixedParts(partIds, catalogAddress);

        // Fixed parts:
        fixedParts = new FixedPart[](fixedPartIds.length);

        uint256 len = fixedPartIds.length;
        if (len != 0) {
            IRMRKCatalog.Part[] memory catalogFixedParts = IRMRKCatalog(
                catalogAddress
            ).getParts(fixedPartIds);
            for (uint256 i; i < len; ) {
                fixedParts[i] = FixedPart({
                    partId: fixedPartIds[i],
                    z: catalogFixedParts[i].z,
                    metadataURI: catalogFixedParts[i].metadataURI
                });
                unchecked {
                    ++i;
                }
            }
        }

        (slotParts, ) = _getEquippedSlotParts(
            target_,
            tokenId,
            assetId,
            catalogAddress,
            slotPartIds
        );
    }

    /** @notice Used to get the child's assets and slot parts pairs, identifying parts the said assets can be equipped
     *  into, for all of parent's assets.
     * @dev Reverts if child token is not owned by an NFT.
     * @dev The full `EquippableData` struct looks like this:
     *  [
     *      slotPartId,
     *      childAssetId,
     *      parentAssetId,
     *      priority,
     *      parentCatalogAddress,
     *      isEquipped,
     *      partMetadata
     *  ]
     * @param targetChild Address of the smart contract of the given token
     * @param childId ID of the child token whose assets will be matched against parent's slot parts
     * @param onlyEquipped Boolean value signifying whether to only return the assets that are currently equipped (`true`) or to include the non-equipped ones as well (`false`)
     * @return childIndex Index of the child in the parent's list of active children
     * @return equippableData An array of `EquippableData` structs containing info about the equippable child assets and their corresponding slot parts
     */
    function getAllEquippableSlotsFromParent(
        address targetChild,
        uint256 childId,
        bool onlyEquipped
    )
        public
        view
        returns (uint256 childIndex, EquippableData[] memory equippableData)
    {
        (address parentAddress, uint256 parentId) = getParent(
            targetChild,
            childId
        );
        uint64[] memory parentAssets = IERC5773(parentAddress).getActiveAssets(
            parentId
        );
        uint256 totalParentAssets = parentAssets.length;

        uint256 totalChildAssets = IERC5773(targetChild)
            .getActiveAssets(childId)
            .length;
        uint256 totalMatchesForAll = 0;

        // This is the most valid asset combinations that can be made. When we know the real total we'll recreate it
        EquippableData[] memory allTempAssetsWithSlots = new EquippableData[](
            totalParentAssets * totalChildAssets
        );

        // Here we store temporarly the matches for each parent asset.
        EquippableData[] memory assetsWithSlotsForParentAsset;

        for (uint256 i; i < totalParentAssets; ) {
            assetsWithSlotsForParentAsset = _getEquippableSlotsFromParent(
                targetChild,
                childId,
                parentAddress,
                parentId,
                parentAssets[0]
            );
            uint totalMatchesForParentAsset = assetsWithSlotsForParentAsset
                .length;

            // We move them to the temporary array of all matches. Optionally filtering for onlyEquipped
            for (uint256 j; j < totalMatchesForParentAsset; ) {
                if (
                    !onlyEquipped || assetsWithSlotsForParentAsset[j].isEquipped
                ) {
                    allTempAssetsWithSlots[
                        totalMatchesForAll
                    ] = assetsWithSlotsForParentAsset[j];
                    unchecked {
                        ++totalMatchesForAll;
                    }
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        equippableData = new EquippableData[](totalMatchesForAll);
        for (uint256 i; i < totalMatchesForAll; ) {
            equippableData[i] = allTempAssetsWithSlots[i];
            unchecked {
                ++i;
            }
        }

        childIndex = getChildIndex(
            parentAddress,
            parentId,
            targetChild,
            childId
        );
    }

    /**
     * @notice Used to get the child's assets and slot parts pairs, identifying parts the said assets can be equipped
     *  into, for a specific parent asset.
     * @dev Reverts if child token is not owned by an NFT.
     * @dev The full `EquippableData` struct looks like this:
     *  [
     *      slotPartId,
     *      childAssetId,
     *      parentAssetId,
     *      priority,
     *      parentCatalogAddress,
     *      isEquipped,
     *      partMetadata,
     *      childAssetMetadata,
     *      parentAssetMetadata
     *  ]
     * @param targetChild Address of the smart contract of the given token
     * @param childId ID of the child token whose assets will be matched against parent's slot parts
     * @param parentAssetId ID of the target parent asset to use to equip the child
     * @return childIndex Index of the child in the parent's list of active children
     * @return equippableData An array of `EquippableData` structs containing info about the equippable child assets and
     *  their corresponding slot parts
     */
    function getEquippableSlotsFromParent(
        address targetChild,
        uint256 childId,
        uint64 parentAssetId
    )
        public
        view
        returns (uint256 childIndex, EquippableData[] memory equippableData)
    {
        (address parentAddress, uint256 parentId) = getParent(
            targetChild,
            childId
        );
        childIndex = getChildIndex(
            parentAddress,
            parentId,
            targetChild,
            childId
        );

        equippableData = _getEquippableSlotsFromParent(
            targetChild,
            childId,
            parentAddress,
            parentId,
            parentAssetId
        );
    }

    /**
     * @notice Used to get the child's assets and slot parts pairs, identifying parts the said assets can be equipped
     *  into, for a specific parent asset while the child is in pending array.
     * @dev Reverts if child token is not owned by an NFT.
     * @dev The full `EquippableData` struct looks like this:
     *  [
     *      slotPartId,
     *      childAssetId,
     *      parentAssetId,
     *      priority,
     *      parentCatalogAddress,
     *      isEquipped,
     *      partMetadata,
     *      childAssetMetadata,
     *      parentAssetMetadata
     *  ]
     * @param targetChild Address of the smart contract of the given token
     * @param childId ID of the child token whose assets will be matched against parent's slot parts
     * @param parentAssetId ID of the target parent asset to use to equip the child
     * @return childIndex Index of the child in the parent's list of pending children
     * @return equippableData An array of `EquippableData` structs containing info about the equippable child assets and
     *  their corresponding slot parts
     */
    function getEquippableSlotsFromParentForPendingChild(
        address targetChild,
        uint256 childId,
        uint64 parentAssetId
    )
        public
        view
        returns (uint256 childIndex, EquippableData[] memory equippableData)
    {
        (address parentAddress, uint256 parentId) = getParent(
            targetChild,
            childId
        );
        childIndex = getPendingChildIndex(
            parentAddress,
            parentId,
            targetChild,
            childId
        );

        equippableData = _getEquippableSlotsFromParent(
            targetChild,
            childId,
            parentAddress,
            parentId,
            parentAssetId
        );
    }

    /**
     * @notice Used to get information about the current children equipped into a specific parent and asset.
     * @dev The full `IERC6220.Equipment` struct looks like this:
     *  [
     *       assetId
     *       childAssetId
     *       childId
     *       childEquippableAddress
     *  ]
     * @param parentAddress Address of the parent token's smart contract
     * @param parentId ID of the parent token
     * @param parentAssetId ID of the target parent asset to use to equip the child
     * @return equippedChildren An array of `IERC6220.Equipment` structs containing the info
     *  about the equipped children
     */
    function equippedChildrenOf(
        address parentAddress,
        uint256 parentId,
        uint64 parentAssetId
    ) public view returns (IERC6220.Equipment[] memory equippedChildren) {
        (
            uint64[] memory slotPartIds,
            address parentAssetCatalog
        ) = getSlotPartsAndCatalog(parentAddress, parentId, parentAssetId);
        IERC6220 target_ = IERC6220(parentAddress);
        (
            EquippedSlotPart[] memory tmpSlotParts,
            uint256 totalEquipped
        ) = _getEquippedSlotParts(
                target_,
                parentId,
                parentAssetId,
                parentAssetCatalog,
                slotPartIds
            );

        uint256 totalSlots = slotPartIds.length;
        uint256 finalIndex;
        equippedChildren = new IERC6220.Equipment[](totalEquipped);
        for (uint256 i; i < totalSlots; ) {
            if (tmpSlotParts[i].childId != 0) {
                equippedChildren[finalIndex] = IERC6220.Equipment({
                    assetId: parentAssetId,
                    childAssetId: tmpSlotParts[i].childAssetId,
                    childId: tmpSlotParts[i].childId,
                    childEquippableAddress: tmpSlotParts[i].childAddress
                });
                unchecked {
                    ++finalIndex;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to get the child's assets and slot parts pairs, identifying parts the said assets can be equipped into.
     * @dev Reverts if child token is not owned by an NFT.
     * @dev The full `EquippableData` struct looks like this:
     *  [
     *       slotPartId
     *       childAssetId
     *       parentAssetId
     *       priority
     *       parentCatalogAddress
     *       isEquipped
     *       partMetadata,
     *       childAssetMetadata,
     *       parentAssetMetadata
     *  ]
     * @param childAddress Address of the smart contract of the given token
     * @param childId ID of the child token whose assets will be matched against parent's slot parts
     * @param parentAddress Address of the parent token's smart contract
     * @param parentId ID of the parent token
     * @param parentAssetId ID of the target parent asset to use to equip the child
     * @return equippableData An array of `EquippableData` structs containing info about the equippable child assets and
     *  their corresponding slot parts
     */
    function _getEquippableSlotsFromParent(
        address childAddress,
        uint256 childId,
        address parentAddress,
        uint256 parentId,
        uint64 parentAssetId
    ) private view returns (EquippableData[] memory equippableData) {
        (
            uint64[] memory parentSlotPartIds,
            address parentAssetCatalog
        ) = getSlotPartsAndCatalog(parentAddress, parentId, parentAssetId);

        (
            EquippableData[] memory tempAssetsWithSlots,
            uint256 totalMatches
        ) = _matchAllAssetsWithSlots(
                IERC6220(childAddress),
                childId,
                parentSlotPartIds,
                parentAddress,
                parentAssetCatalog
            );
        // Finally, we copy the matches into the final array which has the right lenght according to results
        equippableData = new EquippableData[](totalMatches);
        for (uint256 i; i < totalMatches; ) {
            equippableData[i] = tempAssetsWithSlots[i];
            // Ideally we would check this directly in the _matchAllAssetsWithSlots function, but we'd get stack too deep error
            // Since that function uses the limit of variables already
            equippableData[i].isEquipped = isAssetEquipped(
                parentAddress,
                parentId,
                parentAssetCatalog,
                childAddress,
                childId,
                tempAssetsWithSlots[i].childAssetId,
                tempAssetsWithSlots[i].slotPartId
            );
            equippableData[i].partMetadata = IRMRKCatalog(parentAssetCatalog)
                .getPart(tempAssetsWithSlots[i].slotPartId)
                .metadataURI;
            equippableData[i].parentAssetId = parentAssetId;
            equippableData[i].parentCatalogAddress = parentAssetCatalog;
            equippableData[i].childAssetMetadata = IERC5773(childAddress)
                .getAssetMetadata(childId, tempAssetsWithSlots[i].childAssetId);
            equippableData[i].parentAssetMetadata = IERC5773(parentAddress)
                .getAssetMetadata(parentId, parentAssetId);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to retrieve the equippable data of the specified token's asset with the highest priority.
     * @param target Address of the collection smart contract of the specified token
     * @param tokenId ID of the token for which to retrieve the equippable data of the asset with the highest priority
     * @return topAsset `ExtendedEquippableActiveAsset` struct with the equippable data containing the asset with the
     *  highest priority
     */
    function getTopAssetAndEquippableDataForToken(
        address target,
        uint256 tokenId
    ) public view returns (ExtendedEquippableActiveAsset memory topAsset) {
        (uint64 topAssetId, uint64 topPriority) = getAssetIdWithTopPriority(
            target,
            tokenId
        );
        (
            string memory metadataURI,
            uint64 equippableGroupId,
            address catalogAddress,
            uint64[] memory partIds
        ) = IERC6220(target).getAssetAndEquippableData(tokenId, topAssetId);
        topAsset = ExtendedEquippableActiveAsset({
            id: topAssetId,
            equippableGroupId: equippableGroupId,
            priority: topPriority,
            catalogAddress: catalogAddress,
            metadata: metadataURI,
            partIds: partIds
        });
    }

    /**
     * @notice Matches all child's assets with the corresponding slot parts of the parent, if they apply.
     * @dev The full `EquippableData` struct looks like this:
     *  [
     *       slotPartId
     *       childAssetId
     *       parentAssetId
     *       priority
     *       parentCatalogAddress
     *       isEquipped
     *       partMetadata
     *  ]
     * @dev The size of the returning array is equal to the total of available parent slots, even if there's not a match
     *  for each one.
     * @dev The valid matches are located at the beginning of the array, and the rest of the slots are filled with empty
     *  structs. Use totalMatches to know how many valid matches there are.
     * @dev Some data from the returned structs is not filled due to stack to deep limitation: parentAssetId,
     *  parentCatalogAddress, isEquipped and partMetadata.
     * @param childContract IERC6220 instance of the child smart contract
     * @param childId ID of the child token whose assets will be matched against parent's slot parts
     * @param parentSlotPartIds Array of slot part IDs of the parent token's asset
     * @param parentAddress Address of the parent smart contract
     * @param parentAssetCatalog Address of the parent asset's catalog
     * @return allAssetsWithSlots An array of `EquippableData` structs containing info about the equippable child assets
     *  and their corresponding slot parts
     * @return totalMatches Total of valid matches found
     */
    function _matchAllAssetsWithSlots(
        IERC6220 childContract,
        uint256 childId,
        uint64[] memory parentSlotPartIds,
        address parentAddress,
        address parentAssetCatalog
    )
        private
        view
        returns (
            EquippableData[] memory allAssetsWithSlots,
            uint256 totalMatches
        )
    {
        uint64[] memory childAssets = childContract.getActiveAssets(childId);
        uint64[] memory priorities = childContract.getActiveAssetPriorities(
            childId
        );

        uint256 totalChildAssets = childAssets.length;

        // There can be at most min(totalChildAssets, totalParentSlots) resulting matches, we just pick one of them.
        allAssetsWithSlots = new EquippableData[](totalChildAssets);

        for (uint256 i; i < totalChildAssets; ) {
            (, , address catalogAddress, ) = childContract
                .getAssetAndEquippableData(childId, childAssets[i]);
            for (uint256 j; j < parentSlotPartIds.length; ) {
                if (
                    catalogAddress == parentAssetCatalog &&
                    childContract.canTokenBeEquippedWithAssetIntoSlot(
                        parentAddress,
                        childId,
                        childAssets[i],
                        parentSlotPartIds[j]
                    )
                ) {
                    allAssetsWithSlots[totalMatches].childAssetId = childAssets[
                        i
                    ];
                    allAssetsWithSlots[totalMatches]
                        .slotPartId = parentSlotPartIds[j];
                    allAssetsWithSlots[totalMatches].priority = priorities[i];

                    // These will be calculated later, due to too many variables in the stack at this point:
                    // - parentAssetId
                    // - parentCatalogAddress
                    // - isEquipped
                    // - partMetadata
                    unchecked {
                        ++totalMatches;
                    }
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to verify whether a given child asset is equipped into a given parent slot.
     * @param parentAddress Address of the collection smart contract of the parent token
     * @param parentId ID of the parent token
     * @param parentAssetCatalog Address of the catalog the parent asset belongs to
     * @param childAddress Address of the collection smart contract of the child token
     * @param childId ID of the child token
     * @param childAssetId ID of the child asset
     * @param slotPartId ID of the slot part
     * @return isEquipped Boolean value signifying whether the child asset is equipped into the parent slot or not
     */
    function isAssetEquipped(
        address parentAddress,
        uint256 parentId,
        address parentAssetCatalog,
        address childAddress,
        uint256 childId,
        uint64 childAssetId,
        uint64 slotPartId
    ) public view returns (bool isEquipped) {
        IERC6220.Equipment memory equipment = IERC6220(parentAddress)
            .getEquipment(parentId, parentAssetCatalog, slotPartId);
        isEquipped =
            equipment.childEquippableAddress == childAddress &&
            equipment.childId == childId &&
            equipment.childAssetId == childAssetId;
    }

    /**
     * @notice Used to retrieve the parent address and its slot part IDs for a given target child, and the catalog of the parent asset.
     * @param tokenAddress Address of the collection smart contract of parent token
     * @param tokenId ID of the parent token
     * @param assetId ID of the parent asset from which to get the slot parts
     * @return parentSlotPartIds Array of slot part IDs of the parent token's asset
     * @return catalogAddress Address of the catalog the parent asset belongs to
     */
    function getSlotPartsAndCatalog(
        address tokenAddress,
        uint256 tokenId,
        uint64 assetId
    )
        public
        view
        returns (uint64[] memory parentSlotPartIds, address catalogAddress)
    {
        uint64[] memory parentPartIds;
        (, , catalogAddress, parentPartIds) = IERC6220(tokenAddress)
            .getAssetAndEquippableData(tokenId, assetId);
        if (catalogAddress == address(0)) revert RMRKNotComposableAsset();

        (parentSlotPartIds, ) = splitSlotAndFixedParts(
            parentPartIds,
            catalogAddress
        );
    }

    /**
     * @notice Used to retrieve the equipped slot parts.
     * @dev The full `EquippedSlotPart` struct looks like this:
     *  [
     *      partId,
     *      childAssetId,
     *      z,
     *      childAddress,
     *      childId,
     *      childAssetMetadata,
     *      partMetadata
     *  ]
     * @param target_ An address of the `IERC6220` smart contract to retrieve the equipped slot parts from.
     * @param tokenId ID of the token for which to retrieve the equipped slot parts
     * @param assetId ID of the asset on the token to retrieve the equipped slot parts
     * @param catalogAddress The address of the catalog to which the given asset belongs to
     * @param slotPartIds An array of slot part IDs in the asset for which to retrieve the equipped slot parts
     * @return slotParts An array of `EquippedSlotPart` structs representing the equipped slot parts
     * @return totalEquipped Total of slot parts with some asset equipped.
     */
    function _getEquippedSlotParts(
        IERC6220 target_,
        uint256 tokenId,
        uint64 assetId,
        address catalogAddress,
        uint64[] memory slotPartIds
    )
        private
        view
        returns (EquippedSlotPart[] memory slotParts, uint256 totalEquipped)
    {
        slotParts = new EquippedSlotPart[](slotPartIds.length);
        uint256 len = slotPartIds.length;

        if (len != 0) {
            string memory metadata;
            IRMRKCatalog.Part[] memory catalogSlotParts = IRMRKCatalog(
                catalogAddress
            ).getParts(slotPartIds);
            for (uint256 i; i < len; ) {
                IERC6220.Equipment memory equipment = target_.getEquipment(
                    tokenId,
                    catalogAddress,
                    slotPartIds[i]
                );
                if (equipment.assetId == assetId) {
                    metadata = IERC6220(equipment.childEquippableAddress)
                        .getAssetMetadata(
                            equipment.childId,
                            equipment.childAssetId
                        );
                    slotParts[i] = EquippedSlotPart({
                        partId: slotPartIds[i],
                        childAssetId: equipment.childAssetId,
                        z: catalogSlotParts[i].z,
                        childId: equipment.childId,
                        childAddress: equipment.childEquippableAddress,
                        childAssetMetadata: metadata,
                        partMetadata: catalogSlotParts[i].metadataURI
                    });
                    unchecked {
                        ++totalEquipped;
                    }
                } else {
                    slotParts[i].partId = slotPartIds[i];
                    slotParts[i].z = catalogSlotParts[i].z;
                    slotParts[i].partMetadata = catalogSlotParts[i].metadataURI;
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Used to split slot and fixed parts.
     * @param allPartIds[] An array of `Part` IDs containing both, `Slot` and `Fixed` parts
     * @param catalogAddress An address of the catalog to which the given `Part`s belong to
     * @return slotPartIds An array of IDs of the `Slot` parts included in the `allPartIds`
     * @return fixedPartIds An array of IDs of the `Fixed` parts included in the `allPartIds`
     */
    function splitSlotAndFixedParts(
        uint64[] memory allPartIds,
        address catalogAddress
    )
        public
        view
        returns (uint64[] memory slotPartIds, uint64[] memory fixedPartIds)
    {
        IRMRKCatalog.Part[] memory allParts = IRMRKCatalog(catalogAddress)
            .getParts(allPartIds);
        uint256 numFixedParts;
        uint256 numSlotParts;

        uint256 numParts = allPartIds.length;
        // This for loop is just to discover the right size of the split arrays, since we can't create them dynamically
        for (uint256 i; i < numParts; ) {
            if (allParts[i].itemType == IRMRKCatalog.ItemType.Fixed)
                numFixedParts += 1;
                // We could just take the numParts - numFixedParts, but it doesn't hurt to double check it's not an uninitialized part:
            else if (allParts[i].itemType == IRMRKCatalog.ItemType.Slot)
                numSlotParts += 1;
            unchecked {
                ++i;
            }
        }

        slotPartIds = new uint64[](numSlotParts);
        fixedPartIds = new uint64[](numFixedParts);
        uint256 slotPartsIndex;
        uint256 fixedPartsIndex;

        // This for loop is to actually fill the split arrays
        for (uint256 i; i < numParts; ) {
            if (allParts[i].itemType == IRMRKCatalog.ItemType.Fixed) {
                fixedPartIds[fixedPartsIndex] = allPartIds[i];
                fixedPartsIndex += 1;
            } else if (allParts[i].itemType == IRMRKCatalog.ItemType.Slot) {
                slotPartIds[slotPartsIndex] = allPartIds[i];
                slotPartsIndex += 1;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev The full `ChildWithTopAssetMetadata` struct looks like this:
     *  [
     *      contractAddress,
     *      tokenId,
     *      metadata
     *  ]
     * @param parentAddress Address of the collection smart contract of the parent token
     * @param parentId ID of the parent token
     * @return An array of `ChildWithTopAssetMetadata` structs representing the children with their top asset metadata
     */
    function getChildrenWithTopMetadata(
        address parentAddress,
        uint256 parentId
    ) public view returns (ChildWithTopAssetMetadata[] memory) {
        IERC6059.Child[] memory children = IERC6059(parentAddress).childrenOf(
            parentId
        );
        (parentId);
        uint256 len = children.length;
        ChildWithTopAssetMetadata[]
            memory childrenWithMetadata = new ChildWithTopAssetMetadata[](len);

        for (uint256 i; i < len; ) {
            string memory meta = getTopAssetMetaForToken(
                children[i].contractAddress,
                children[i].tokenId
            );
            childrenWithMetadata[i] = ChildWithTopAssetMetadata(
                children[i].contractAddress,
                children[i].tokenId,
                meta
            );
            unchecked {
                ++i;
            }
        }
        return childrenWithMetadata;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "../access/OwnableLock.sol";
import "../library/RMRKErrors.sol";

/**
 * @title RMRKMintingUtils
 * @author RMRK team
 * @notice Smart contract of the RMRK minting utils module.
 * @dev This smart contract includes the top-level utilities for managing minting and implements OwnableLock by default.
 * @dev Max supply-related and pricing variables are immutable after deployment.
 */
contract RMRKMintingUtils is OwnableLock {
    uint256 internal _nextId;
    uint256 internal _totalSupply;
    uint256 internal _maxSupply;
    uint256 internal immutable _pricePerMint;

    /**
     * @notice Initializes the smart contract with a given maximum supply and minting price.
     * @param maxSupply_ The maximum supply of tokens to initialize the smart contract with
     * @param pricePerMint_ The minting price to initialize the smart contract with, expressed in the smallest
     *  denomination of the native currency of the chain to which the smart contract is deployed to
     */
    constructor(uint256 maxSupply_, uint256 pricePerMint_) {
        _maxSupply = maxSupply_;
        _pricePerMint = pricePerMint_;
    }

    /**
     * @notice Used to verify that the sale of the given token is still available.
     * @dev If the maximum supply is reached, the execution will be reverted.
     */
    modifier saleIsOpen() {
        _checkSaleIsOpen();
        _;
    }

    /**
     * @inheritdoc OwnableLock
     */
    function setLock() public virtual override onlyOwner {
        super.setLock();
        _maxSupply = _totalSupply;
    }

    /**
     * @notice Used to retrieve the total supply of the tokens in a collection.
     * @return The number of tokens in a collection
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Used to retrieve the maximum supply of the collection.
     * @return The maximum supply of tokens in the collection
     */
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @notice Used to retrieve the price per mint.
     * @return The price per mint of a single token expressed in the lowest denomination of a native currency
     */
    function pricePerMint() public view returns (uint256) {
        return _pricePerMint;
    }

    /**
     * @notice Used to withdraw the minting proceedings to a specified address.
     * @dev This function can only be called by the owner.
     * @param to Address to receive the given amount of minting proceedings
     * @param amount The amount to withdraw
     */
    function withdrawRaised(address to, uint256 amount) external onlyOwner {
        _withdraw(to, amount);
    }

    /**
     * @notice Used to withdraw the minting proceedings to a specified address.
     * @param _address Address to receive the given amount of minting proceedings
     * @param _amount The amount to withdraw
     */
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    /**
     * @notice Used to verify that the sale is still open.
     * @dev In case the maximum supply of the collection is reached, the execution is reverted.
     */
    function _checkSaleIsOpen() private view {
        if (_nextId >= _maxSupply) revert RMRKMintOverMax();
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "../multiasset/IERC5773.sol";
import "../library/RMRKErrors.sol";

/**
 * @title RMRKMultiAssetRenderUtils
 * @author RMRK team
 */
contract RMRKMultiAssetRenderUtils {
    uint64 private constant _LOWEST_POSSIBLE_PRIORITY = 2 ** 64 - 1;

    /**
     * @notice The structure used to display information about an active asset.
     * @return id ID of the asset
     * @return priority The priority assigned to the asset
     * @return metadata The metadata URI of the asset
     */
    struct ExtendedActiveAsset {
        uint64 id;
        uint64 priority;
        string metadata;
    }

    /**
     * @notice The structure used to display information about a pending asset.
     * @return id ID of the asset
     * @return acceptRejectIndex An index to use in order to accept or reject the given asset
     * @return replacesAssetWithId ID of the asset that would be replaced if this asset gets accepted
     * @return metadata The metadata URI of the asset
     */
    struct PendingAsset {
        uint64 id;
        uint128 acceptRejectIndex;
        uint64 replacesAssetWithId;
        string metadata;
    }

    /**
     * @notice Used to get the active assets of the given token.
     * @dev The full `ExtendedActiveAsset` looks like this:
     *  [
     *      id,
     *      priority,
     *      metadata
     *  ]
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token to retrieve the active assets for
     * @return An array of ActiveAssets present on the given token
     */
    function getExtendedActiveAssets(
        address target,
        uint256 tokenId
    ) public view virtual returns (ExtendedActiveAsset[] memory) {
        IERC5773 target_ = IERC5773(target);

        uint64[] memory assets = target_.getActiveAssets(tokenId);
        uint64[] memory priorities = target_.getActiveAssetPriorities(tokenId);
        uint256 len = assets.length;
        if (len == uint256(0)) {
            revert RMRKTokenHasNoAssets();
        }

        ExtendedActiveAsset[] memory activeAssets = new ExtendedActiveAsset[](
            len
        );
        string memory metadata;
        for (uint256 i; i < len; ) {
            metadata = target_.getAssetMetadata(tokenId, assets[i]);
            activeAssets[i] = ExtendedActiveAsset({
                id: assets[i],
                priority: priorities[i],
                metadata: metadata
            });
            unchecked {
                ++i;
            }
        }
        return activeAssets;
    }

    /**
     * @notice Used to get the pending assets of the given token.
     * @dev The full `PendingAsset` looks like this:
     *  [
     *      id,
     *      acceptRejectIndex,
     *      replacesAssetWithId,
     *      metadata
     *  ]
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token to retrieve the pending assets for
     * @return An array of PendingAssets present on the given token
     */
    function getPendingAssets(
        address target,
        uint256 tokenId
    ) public view virtual returns (PendingAsset[] memory) {
        IERC5773 target_ = IERC5773(target);

        uint64[] memory assets = target_.getPendingAssets(tokenId);
        uint256 len = assets.length;
        if (len == uint256(0)) {
            revert RMRKTokenHasNoAssets();
        }

        PendingAsset[] memory pendingAssets = new PendingAsset[](len);
        string memory metadata;
        uint64 replacesAssetWithId;
        for (uint256 i; i < len; ) {
            metadata = target_.getAssetMetadata(tokenId, assets[i]);
            replacesAssetWithId = target_.getAssetReplacements(
                tokenId,
                assets[i]
            );
            pendingAssets[i] = PendingAsset({
                id: assets[i],
                acceptRejectIndex: uint128(i),
                replacesAssetWithId: replacesAssetWithId,
                metadata: metadata
            });
            unchecked {
                ++i;
            }
        }
        return pendingAssets;
    }

    /**
     * @notice Used to retrieve the metadata URI of specified assets in the specified token.
     * @dev Requirements:
     *
     *  - `assetIds` must exist.
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token to retrieve the specified assets for
     * @param assetIds[] An array of asset IDs for which to retrieve the metadata URIs
     * @return An array of metadata URIs belonging to specified assets
     */
    function getAssetsById(
        address target,
        uint256 tokenId,
        uint64[] calldata assetIds
    ) public view virtual returns (string[] memory) {
        IERC5773 target_ = IERC5773(target);
        uint256 len = assetIds.length;
        string[] memory assets = new string[](len);
        for (uint256 i; i < len; ) {
            assets[i] = target_.getAssetMetadata(tokenId, assetIds[i]);
            unchecked {
                ++i;
            }
        }
        return assets;
    }

    /**
     * @notice Used to retrieve the metadata URI of the specified token's asset with the highest priority.
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token for which to retrieve the metadata URI of the asset with the highest priority
     * @return The metadata URI of the asset with the highest priority
     */
    function getTopAssetMetaForToken(
        address target,
        uint256 tokenId
    ) public view returns (string memory) {
        (uint64 maxPriorityAssetId, ) = getAssetIdWithTopPriority(
            target,
            tokenId
        );
        return IERC5773(target).getAssetMetadata(tokenId, maxPriorityAssetId);
    }

    /**
     * @notice Used to retrieve the metadata URI of the specified token's asset with the highest priority for each of the given tokens.
     * @param target Address of the smart contract of the tokens
     * @param tokenIds IDs of the tokens for which to retrieve the metadata URIs
     * @return metadata An array of strings with the top asset metadata for each of the given tokens, in the same order as the tokens passed in the `tokenIds` input array
     */
    function getTopAssetMetadataForTokens(
        address target,
        uint256[] memory tokenIds
    ) public view returns (string[] memory metadata) {
        uint256 len = tokenIds.length;
        metadata = new string[](len);

        for (uint256 i; i < len; ) {
            metadata[i] = getTopAssetMetaForToken(target, tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to retrieve the ID of the specified token's asset with the highest priority.
     * @param target Address of the smart contract of the given token
     * @param tokenId ID of the token for which to retrieve the ID of the asset with the highest priority
     * @return The ID of the asset with the highest priority
     * @return The priority value of the asset with the highest priority
     */
    function getAssetIdWithTopPriority(
        address target,
        uint256 tokenId
    ) public view returns (uint64, uint64) {
        IERC5773 target_ = IERC5773(target);
        uint64[] memory priorities = target_.getActiveAssetPriorities(tokenId);
        uint64[] memory assets = target_.getActiveAssets(tokenId);
        uint256 len = priorities.length;
        if (len == uint256(0)) {
            revert RMRKTokenHasNoAssets();
        }

        uint64 maxPriority = _LOWEST_POSSIBLE_PRIORITY;
        uint64 maxPriorityAssetId;
        for (uint64 i; i < len; ) {
            uint64 currentPrio = priorities[i];
            if (currentPrio < maxPriority) {
                maxPriority = currentPrio;
                maxPriorityAssetId = assets[i];
            }
            unchecked {
                ++i;
            }
        }
        return (maxPriorityAssetId, maxPriority);
    }

    /**
     * @notice Used to retrieve ID, priority value and metadata URI of the asset with the highest priority that is
     *  present on a specified token.
     * @param target Collection smart contract of the token for which to retireve the top asset
     * @param tokenId ID of the token for which to retrieve the top asset
     * @return topAssetId ID of the asset with the highest priority
     * @return topAssetPriority Priotity value of the asset with the highest priority
     * @return topAssetMetadata Metadata URI of the asset with the highest priority
     */
    function getTopAsset(
        address target,
        uint256 tokenId
    )
        public
        view
        returns (
            uint64 topAssetId,
            uint64 topAssetPriority,
            string memory topAssetMetadata
        )
    {
        (topAssetId, topAssetPriority) = getAssetIdWithTopPriority(
            target,
            tokenId
        );
        topAssetMetadata = IERC5773(target).getAssetMetadata(
            tokenId,
            topAssetId
        );
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "../nestable/IERC6059.sol";
import "../library/RMRKErrors.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

/**
 * @title RMRKNestableRenderUtils
 * @author RMRK team
 * @notice Smart contract of the RMRK Nestable render utils module.
 */
contract RMRKNestableRenderUtils {
    /**
     * @notice Used to retrieve the given child's index in its parent's child tokens array.
     * @param parentAddress Address of the parent token's collection smart contract
     * @param parentId ID of the parent token
     * @param childAddress Address of the child token's colection smart contract
     * @param childId ID of the child token
     * @return The index of the child token in the parent token's child tokens array
     */
    function getChildIndex(
        address parentAddress,
        uint256 parentId,
        address childAddress,
        uint256 childId
    ) public view returns (uint256) {
        IERC6059.Child[] memory children = IERC6059(parentAddress).childrenOf(
            parentId
        );
        (parentId);
        uint256 len = children.length;
        for (uint256 i; i < len; ) {
            if (
                children[i].tokenId == childId &&
                children[i].contractAddress == childAddress
            ) return i;
            unchecked {
                ++i;
            }
        }
        revert RMRKChildNotFoundInParent();
    }

    /**
     * @notice Used to retrieve the given child's index in its parent's pending child tokens array.
     * @param parentAddress Address of the parent token's collection smart contract
     * @param parentId ID of the parent token
     * @param childAddress Address of the child token's colection smart contract
     * @param childId ID of the child token
     * @return The index of the child token in the parent token's pending child tokens array
     */
    function getPendingChildIndex(
        address parentAddress,
        uint256 parentId,
        address childAddress,
        uint256 childId
    ) public view returns (uint256) {
        IERC6059.Child[] memory children = IERC6059(parentAddress)
            .pendingChildrenOf(parentId);
        (parentId);
        uint256 len = children.length;
        for (uint256 i; i < len; ) {
            if (
                children[i].tokenId == childId &&
                children[i].contractAddress == childAddress
            ) return i;
            unchecked {
                ++i;
            }
        }
        revert RMRKChildNotFoundInParent();
    }

    /**
     * @notice Used to retrieve the contract address and ID of the parent token of the specified child token.
     * @dev Reverts if child token is not owned by an NFT.
     * @param childAddress Address of the child token's collection smart contract
     * @param childId ID of the child token
     * @return parentAddress Address of the parent token's collection smart contract
     * @return parentId ID of the parent token
     */
    function getParent(
        address childAddress,
        uint256 childId
    ) public view returns (address parentAddress, uint256 parentId) {
        bool isNFT;
        (parentAddress, parentId, isNFT) = IERC6059(childAddress).directOwnerOf(
            childId
        );
        if (!isNFT) revert RMRKParentIsNotNFT();
    }

    /**
     * @notice Used to retrieve the immediate owner of the given token, and whether it is on the parent's active or pending children list.
     * @dev If the immediate owner is not an NFT, the function returns false for both `inParentsActiveChildren` and `inParentsPendingChildren`.
     * @param collection Address of the token's collection smart contract
     * @param tokenId ID of the token
     * @return directOwner Address of the given token's owner
     * @return ownerId The ID of the parent token. Should be `0` if the owner is an externally owned account
     * @return isNFT The boolean value signifying whether the owner is an NFT or not
     * @return inParentsActiveChildren A boolean value signifying whether the token is in the parent's active children list
     * @return inParentsPendingChildren A boolean value signifying whether the token is in the parent's pending children list
     */
    function directOwnerOfWithParentsPerspective(
        address collection,
        uint256 tokenId
    )
        public
        view
        returns (
            address directOwner,
            uint256 ownerId,
            bool isNFT,
            bool inParentsActiveChildren,
            bool inParentsPendingChildren
        )
    {
        (directOwner, ownerId, isNFT) = IERC6059(collection).directOwnerOf(
            tokenId
        );
        if (!isNFT) {
            inParentsActiveChildren = false;
            inParentsPendingChildren = false;
        } else {
            IERC6059.Child[] memory activeChildren = IERC6059(directOwner)
                .childrenOf(ownerId);
            IERC6059.Child[] memory pendingChildren = IERC6059(directOwner)
                .pendingChildrenOf(ownerId);

            uint256 len = activeChildren.length;
            for (uint256 i; i < len; ) {
                if (
                    activeChildren[i].tokenId == tokenId &&
                    activeChildren[i].contractAddress == collection
                ) {
                    inParentsActiveChildren = true;
                    break;
                }
                unchecked {
                    ++i;
                }
            }
            if (!inParentsActiveChildren) {
                // Cannot be on both lists
                len = pendingChildren.length;
                for (uint256 i; i < len; ) {
                    if (
                        pendingChildren[i].tokenId == tokenId &&
                        pendingChildren[i].contractAddress == collection
                    ) {
                        inParentsPendingChildren = true;
                        break;
                    }
                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    /**
     * @notice Used to identify if the given token is rejected or abandoned. That is, it's parent is an NFT but this token is neither on the parent's active nor pending children list.
     * @dev Returns false if the immediate owner is not an NFT.
     * @param collection Address of the token's collection smart contract
     * @param tokenId ID of the token
     * @return isRejectedOrAbandoned Whether the token is rejected or abandoned
     */
    function isTokenRejectedOrAbandoned(
        address collection,
        uint256 tokenId
    ) public view returns (bool isRejectedOrAbandoned) {
        (
            ,
            ,
            bool parentIsNft,
            bool inParentsActiveChildren,
            bool inParentsPendingChildren
        ) = directOwnerOfWithParentsPerspective(collection, tokenId);
        return
            parentIsNft &&
            !inParentsActiveChildren &&
            !inParentsPendingChildren;
    }

    /**
     * @notice Check if the child is owned by the expected parent.
     * @dev Reverts if child token is not owned by an NFT.
     * @dev Reverts if child token is not owned by the expected parent.
     * @param childAddress Address of the child contract
     * @param childId ID of the child token
     * @param expectedParent Address of the expected parent contract
     * @param expectedParentId ID of the expected parent token
     */
    function checkExpectedParent(
        address childAddress,
        uint256 childId,
        address expectedParent,
        uint256 expectedParentId
    ) public view {
        address parentAddress;
        uint256 parentId;
        (parentAddress, parentId) = getParent(childAddress, childId);
        if (parentAddress != expectedParent || expectedParentId != parentId)
            revert RMRKUnexpectedParent();
    }

    /**
     * @notice Used to validate whether the specified child token is owned by a given parent token.
     * @param parentAddress Address of the parent token's collection smart contract
     * @param childAddress Address of the child token's collection smart contract
     * @param parentId ID of the parent token
     * @param childId ID of the child token
     * @return A boolean value indicating whether the child token is owned by the parent token or not
     */
    function validateChildOf(
        address parentAddress,
        address childAddress,
        uint256 parentId,
        uint256 childId
    ) public view returns (bool) {
        if (
            !IERC165(childAddress).supportsInterface(type(IERC6059).interfaceId)
        ) {
            return false;
        }

        (address directOwner, uint256 ownerId, ) = IERC6059(childAddress)
            .directOwnerOf(childId);

        return (directOwner == parentAddress && ownerId == parentId);
    }

    /**
     * @notice Used to validate whether the specified child token is owned by a given parent token.
     * @param parentAddress Address of the parent token's collection smart contract
     * @param childAddresses An array of the child token's collection smart contract addresses
     * @param parentId ID of the parent token
     * @param childIds An array of child token IDs to verify
     * @return A boolean value indicating whether all of the child tokens are owned by the parent token or not
     * @return An array of boolean values indicating whether each of the child tokens are owned by the parent token or
     *  not
     */
    function validateChildrenOf(
        address parentAddress,
        address[] memory childAddresses,
        uint256 parentId,
        uint256[] memory childIds
    ) public view returns (bool, bool[] memory) {
        if (childAddresses.length != childIds.length) {
            revert RMRKMismachedArrayLength();
        }

        address directOwner;
        uint256 ownerId;
        bool[] memory validityOfChildren = new bool[](childAddresses.length);
        bool isValid = true;

        for (uint256 i; i < childAddresses.length; ) {
            validityOfChildren[i] = validateChildOf(
                parentAddress,
                childAddresses[i],
                parentId,
                childIds[i]
            );

            if (isValid && !validityOfChildren[i]) {
                isValid = false;
            }

            delete directOwner;
            delete ownerId;

            unchecked {
                ++i;
            }
        }

        return (isValid, validityOfChildren);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../access/Ownable.sol";
import "../equippable/RMRKEquippable.sol";
import "../extension/soulbound/RMRKSoulbound.sol";
import "../library/RMRKLib.sol";
import "../library/RMRKErrors.sol";
import "./RMRKMintingUtils.sol";
import "./RMRKTokenURI.sol";

/**
 * @title RMRKRenderUtils
 * @author RMRK team
 * @notice Smart contract of the RMRK render utils module.
 * @dev Extra utility functions for RMRK contracts.
 */
contract RMRKRenderUtils {
    /**
     * @notice Structure used to represent the extended NFT.
     * @return tokenMetadataUri Metadata URI of the specified token
     * @return directOwner Address of the direct owner of the token (smart contract if the token is nested, otherwise
     *  EOA)
     * @return rootOwner Address of the root owner
     * @return activeAssetCount Number of active assets present on the token
     * @return pendingAssetcount Number of pending assets on the token
     * @return priorities The array of priorities of the active asset
     * @return maxSupply The maximum supply of the collection the specified token belongs to
     * @return totalSupply The total supply of the collection the specified token belongs to
     * @return issuer Address of the issuer of the token's collection
     * @return name Name of the collection the token belongs to
     * @return symbol Symbol of the collection the token belongs to
     * @return activeChildrenNumber Number of active child tokens of the given token (only account for direct child
     *  tokens)
     * @return pendingChildrenNumber Number of pending child tokens of the given token (only account for direct child
     *  tokens)
     * @return isSoulbound Boolean value signifying whether the token is soulbound or not
     * @return hasMultiAssetInterface Boolean value signifying whether the toke supports MultiAsset interface
     * @return hasNestingInterface Boolean value signifying whether the toke supports Nestable interface
     * @return hasEquippableInterface Boolean value signifying whether the toke supports Equippable interface
     */
    struct ExtendedNft {
        string tokenMetadataUri;
        address directOwner;
        address rootOwner;
        uint256 activeAssetCount;
        uint256 pendingAssetCount;
        uint64[] priorities;
        uint256 maxSupply;
        uint256 totalSupply;
        address issuer;
        string name;
        string symbol;
        uint256 activeChildrenNumber;
        uint256 pendingChildrenNumber;
        bool isSoulbound;
        bool hasMultiAssetInterface;
        bool hasNestingInterface;
        bool hasEquippableInterface;
    }

    /**
     * @notice Used to get a list of existing token IDs in the range between `pageStart` and `pageSize`.
     * @dev It is not optimized to avoid checking IDs out of max supply nor total supply, since this is not meant to be
     *  used during transaction execution; it is only meant to be used as a getter.
     * @dev The resulting array might be smaller than the given `pageSize` since no-existent IDs are not included.
     * @param target Address of the collection smart contract of the given token
     * @param pageStart The first ID to check
     * @param pageSize The number of IDs to check
     * @return page An array of IDs of the existing tokens
     */
    function getPaginatedMintedIds(
        address target,
        uint256 pageStart,
        uint256 pageSize
    ) public view returns (uint256[] memory page) {
        uint256[] memory tmpIds = new uint[](pageSize);
        uint256 found;
        for (uint256 i = 0; i < pageSize; ) {
            try IERC721(target).ownerOf(pageStart + i) returns (address) {
                tmpIds[i] = pageStart + i;
                unchecked {
                    found += 1;
                }
            } catch {
                // do nothing
            }
            unchecked {
                ++i;
            }
        }
        page = new uint256[](found);
        uint256 actualIndex;
        for (uint256 i = 0; i < pageSize; ) {
            if (tmpIds[i] != 0) {
                page[actualIndex] = tmpIds[i];
                unchecked {
                    ++actualIndex;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Used to get extended information about a specified token.
     * @dev The full `ExtendedNft` struct looks like this:
     *  [
     *      tokenMetadataUri,
     *      directOwner,
     *      rootOwner,
     *      activeAssetCount,
     *      pendingAssetCount
     *      priorities,
     *      maxSupply,
     *      totalSupply,
     *      issuer,
     *      name,
     *      symbol,
     *      activeChildrenNumber,
     *      pendingChildrenNumber,
     *      isSoulbound,
     *      hasMultiAssetInterface,
     *      hasNestingInterface,
     *      hasEquippableInterface
     *  ]
     * @param tokenId ID of the token for which to retireve the `ExtendedNft` struct
     * @param targetCollection Address of the collection to which the specified token belongs to
     * @return data The `ExtendedNft` struct containing the specified token's data
     */
    function getExtendedNft(
        uint256 tokenId,
        address targetCollection
    ) public view returns (ExtendedNft memory data) {
        RMRKEquippable target = RMRKEquippable(targetCollection);
        data.hasMultiAssetInterface = target.supportsInterface(
            type(IERC5773).interfaceId
        );
        data.hasNestingInterface = target.supportsInterface(
            type(IERC6059).interfaceId
        );
        data.hasEquippableInterface = target.supportsInterface(
            type(IERC6220).interfaceId
        );
        if (data.hasNestingInterface) {
            (data.directOwner, , ) = target.directOwnerOf(tokenId);
            data.activeChildrenNumber = target.childrenOf(tokenId).length;
            data.pendingChildrenNumber = target
                .pendingChildrenOf(tokenId)
                .length;
        }
        if (data.hasMultiAssetInterface) {
            data.activeAssetCount = target.getActiveAssets(tokenId).length;
            data.pendingAssetCount = target.getPendingAssets(tokenId).length;
            data.priorities = target.getActiveAssetPriorities(tokenId);
        }
        if (target.supportsInterface(type(IERC6454).interfaceId)) {
            data.isSoulbound = !IERC6454(targetCollection).isTransferable(
                tokenId,
                address(0),
                address(0)
            );
        }
        data.rootOwner = target.ownerOf(tokenId);
        if (data.directOwner == address(0x0)) {
            data.directOwner = data.rootOwner;
        }
        data.name = target.name();
        try IERC721Metadata(targetCollection).tokenURI(tokenId) returns (
            string memory metadataUri_
        ) {
            data.tokenMetadataUri = metadataUri_;
        } catch {
            // Retain default value
        }
        try RMRKMintingUtils(targetCollection).totalSupply() returns (
            uint256 totalSupplly_
        ) {
            data.totalSupply = totalSupplly_;
        } catch {
            // Retain default value
        }
        try RMRKMintingUtils(targetCollection).maxSupply() returns (
            uint256 maxSupplly_
        ) {
            data.maxSupply = maxSupplly_;
        } catch {
            // Retain default value
        }
        try Ownable(targetCollection).owner() returns (address issuer_) {
            data.issuer = issuer_;
        } catch {
            // Retain default value
        }
        data.symbol = target.symbol();
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title RMRKTokenURI
 * @author RMRK team
 * @notice Implementation of token URI with option to be enumerable.
 */
contract RMRKTokenURI {
    using Strings for uint256;

    string private _tokenUri;
    uint256 private _tokenUriIsEnumerable;

    /**
     * @notice Used to initiate the smart contract.
     * @param tokenURI_ Metadata URI to apply to all tokens, either as base or as full URI for every token
     * @param isEnumerable Whether to treat the tokenURI as enumerable or not. If true, the tokenID will be appended to
     *  the base when getting the tokenURI
     */
    constructor(string memory tokenURI_, bool isEnumerable) {
        _setTokenURI(tokenURI_, isEnumerable);
    }

    /**
     * @notice Used to retrieve the metadata URI of a token.
     * @param tokenId ID of the token to retrieve the metadata URI for
     * @return Metadata URI of the specified token
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual returns (string memory) {
        return
            _tokenUriIsEnumerable == uint256(0)
                ? _tokenUri
                : string(abi.encodePacked(_tokenUri, tokenId.toString()));
    }

    /**
     * @notice Used to set the token URI configuration.
     * @param tokenURI_ Metadata URI to apply to all tokens, either as base or as full URI for every token
     * @param isEnumerable Whether to treat the tokenURI as enumerable or not. If true, the tokenID will be appended to
     *  the base when getting the tokenURI
     */
    function _setTokenURI(
        string memory tokenURI_,
        bool isEnumerable
    ) internal virtual {
        _tokenUri = tokenURI_;
        _tokenUriIsEnumerable = isEnumerable ? 1 : 0;
    }
}