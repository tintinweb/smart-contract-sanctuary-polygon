/**
 *Submitted for verification at polygonscan.com on 2023-04-21
*/

// SPDX-License-Identifier: MIT

// Sources flattened with hardhat v2.13.0 https://hardhat.org

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


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC721/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
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

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

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

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

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

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

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

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File contracts/RelinkdDomain.sol


pragma solidity 0.8.19;



contract RelinkdDomain is ERC721 {
    address public immutable FACTORY;

    uint8 internal constant DEFAULT_FONT_SIZE = 10;
    uint8 internal constant MAX_DOMAIN_LENGTH = 31;
    uint8 internal constant MAX_DOMAIN_LENGTH_WITH_DEFAULT_FONT_SIZE = 16;

    uint256 private _counter;
    ImageDesign private _design;

    mapping(string => uint256) public domainToTokenId;
    mapping(uint256 => DomainInfo) public tokenToInfo;
    mapping(uint256 => mapping(address => string)) public profileToDomain;
    mapping(bytes => bool) private _usedDomains;

    struct DomainInfo {
        string domain;
        address linkedProfile;
        uint256 profileChainId;
    }

    struct ImageDesign {
        string font;
        string fontColor;
        string logo;
        string backgroundColor;
    }

    event Minted(
        address indexed receiver,
        string domain,
        uint256 tokenId,
        address indexed linkedProfile,
        uint256 profileChainId
    );
    event Burned(address indexed owner, uint256 tokenId);
    event DomainRelinked(
        address indexed owner,
        string domain,
        uint256 tokenId,
        address indexed newProfile,
        uint256 newChainId
    );

    constructor(address factory) ERC721("", "") {
        require(factory != address(0), "RelinkdDomain: zero address");
        FACTORY = factory;

        _design = ImageDesign(
            "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",
            "fff",
            '<path class="cls-1" d="M39.3,35.71v-2H35.08v2Zm-4.22,18.4V35.71H33v18.4Zm-2.11,2v-2h-2.1v2Zm-2.1,2v-2h-4.2v2ZM33,60.24V58.19h-2.1v2.05Zm2.11,18.38V60.24H33V78.62Zm4.22,2v-2H35.08v2Z"/><path class="cls-1" d="M57.2,70.45v-2H55.09V52.07H57.2V50H55.09V45.93H53v2H50.88V50h-2.1v2h2.1V68.42h-2.1v2Zm8.41-18.38V48H57.2V50h4.21v2Z"/><path class="cls-1" d="M78.24,35.71v-2H74v2Zm2.11,18.4V35.71H78.24v18.4Zm2.1,2v-2h-2.1v2Zm4.22,2v-2H82.45v2Zm-4.22,2.05V58.19h-2.1v2.05Zm-2.1,18.38V60.24H78.24V78.62Zm-2.11,2v-2H74v2Z"/>',
            "000"
        );
    }

    modifier factoryIsSender() {
        require(_msgSender() == FACTORY, "RelinkdDomain: wrong sender");
        _;
    }

    modifier senderIsTokenOwner(uint256 tokenId) {
        require(tx.origin == ownerOf(tokenId), "RelinkdDomain: not an owner");
        if (tx.origin != _msgSender())
            require(
                _msgSender() == FACTORY,
                "RelinkdDomain: dangerous interaction"
            );
        _;
    }

    modifier notLinkedProfile(address profile, uint256 chainId) {
        // check profile not linked
        if (profile != address(0))
            require(
                bytes(profileToDomain[chainId][profile]).length == 0,
                "RelinkdDomain: profile has already linked"
            );
        _;
    }

    /** @dev method used to create new domain
     * @notice only factory available
     * @param receiver address
     * @param domainName domain name
     * @param profile contract (if exist)
     * @param chainId chain id of deployed profile address
     */
    function mint(
        address receiver,
        string memory domainName,
        address profile,
        uint256 chainId
    ) external factoryIsSender notLinkedProfile(profile, chainId) {
        bytes memory byteDomain = bytes(domainName);
        require(
            byteDomain.length > 0 && byteDomain.length <= MAX_DOMAIN_LENGTH,
            "RelinkdDomain: wrong domain length"
        );
        require(!_usedDomains[byteDomain], "RelinkdDomain: busy domain");
        _usedDomains[byteDomain] = true;
        domainToTokenId[domainName] = _counter;
        for (uint256 i; i < byteDomain.length; i++) {
            require(
                byteDomain[i] == "." ||
                    byteDomain[i] == "_" ||
                    byteDomain[i] == "-" ||
                    (byteDomain[i] >= "0" && byteDomain[i] <= "9") ||
                    (byteDomain[i] >= "a" && byteDomain[i] <= "z"),
                "RelinkdDomain: wrong symbol"
            );
        }
        if (profile != address(0))
            profileToDomain[chainId][profile] = domainName;
        tokenToInfo[_counter] = DomainInfo(domainName, profile, chainId);
        _safeMint(receiver, _counter);

        emit Minted(receiver, domainName, _counter++, profile, chainId);
    }

    /** @dev method used to delete (burn) domain
     * @notice only domain owner available
     * @param tokenId ID of domain NFT
     */
    function burn(uint256 tokenId) external senderIsTokenOwner(tokenId) {
        delete (
            profileToDomain[tokenToInfo[tokenId].profileChainId][
                tokenToInfo[tokenId].linkedProfile
            ]
        );
        delete (_usedDomains[bytes(tokenToInfo[tokenId].domain)]);
        delete (domainToTokenId[tokenToInfo[tokenId].domain]);
        delete (tokenToInfo[tokenId]);
        _burn(tokenId);
        emit Burned(_msgSender(), tokenId);
    }

    /** @dev method used to link domain and profile
     * @notice only domain owner available
     * @param tokenId ID of domain NFT
     * @param newProfile contract address
     * @param chainId chain id of deploed profile contract
     */
    function relinkDomain(
        uint256 tokenId,
        address newProfile,
        uint256 chainId
    )
        external
        senderIsTokenOwner(tokenId)
        notLinkedProfile(newProfile, chainId)
    {
        delete (
            profileToDomain[tokenToInfo[tokenId].profileChainId][
                tokenToInfo[tokenId].linkedProfile
            ]
        );
        if (newProfile != address(0))
            profileToDomain[chainId][newProfile] = tokenToInfo[tokenId].domain;
        tokenToInfo[tokenId].linkedProfile = newProfile;
        tokenToInfo[tokenId].profileChainId = chainId;

        emit DomainRelinked(
            _msgSender(),
            tokenToInfo[tokenId].domain,
            tokenId,
            newProfile,
            chainId
        );
    }

    /** @dev method used to change text font on NFT image
     * @notice only factory available
     * @param _font new font
     */
    function setFont(string memory _font) external factoryIsSender {
        _design.font = _font;
    }

    /** @dev method used to change text color on NFT image
     * @notice only factory available
     * @param _color new color
     */
    function setFontColor(string memory _color) external factoryIsSender {
        _design.fontColor = _color;
    }

    /** @dev method used to change project logo on NFT image
     * @notice only factory available
     * @param _logo new logo
     */
    function setLogo(string memory _logo) external factoryIsSender {
        _design.logo = _logo;
    }

    /** @dev method used to change background color on NFT image
     * @notice only factory available
     * @param _color new color
     */
    function setBackgroundColor(string memory _color) external factoryIsSender {
        _design.backgroundColor = _color;
    }

    /** @dev method used to get linked profile by domain NFT id
     * @param tokenId domain NFT id
     * @return linked profile
     */
    function getProfileByTokenId(
        uint256 tokenId
    ) external view returns (address) {
        return tokenToInfo[tokenId].linkedProfile;
    }

    /** @dev method used to get domain info
     * @param name domain name
     * @return busy true - domain is busy, else - false
     * @return linkedProfile linked profile contract address
     * @return owner owner address
     * @return tokenId id of domain NFT
     */
    function getDomainInfo(
        string memory name
    )
        external
        view
        returns (
            bool busy,
            address linkedProfile,
            address owner,
            uint256 tokenId
        )
    {
        tokenId = domainToTokenId[name];
        busy = _usedDomains[bytes(name)];
        linkedProfile = tokenToInfo[tokenId].linkedProfile;
        owner = busy ? ownerOf(tokenId) : address(0);
    }

    /** @dev method used to get metadata
     * @param tokenId domain NFT id
     * @return metadata in base64 format
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        string memory alphaDomain = string(
            abi.encodePacked("@", tokenToInfo[tokenId].domain)
        );
        if (tokenToInfo[tokenId].linkedProfile != address(0))
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '{"name":"',
                                alphaDomain,
                                '","description":"',
                                alphaDomain,
                                ' - Relinkd Domain","image":"data:image/svg+xml;base64,',
                                _getSVGImageBase64Encoded(alphaDomain),
                                '","attributes":[{"trait_type":"id","value":"#',
                                Strings.toString(tokenId),
                                '"},{"trait_type":"owner","value":"',
                                Strings.toHexString(uint160(ownerOf(tokenId))),
                                '"},{"trait_type":"domain","value":"',
                                alphaDomain,
                                '"},{"trait_type":"profile","value":"',
                                Strings.toHexString(
                                    uint160(tokenToInfo[tokenId].linkedProfile)
                                ),
                                '"},{"trait_type":"chainId","value":"#',
                                Strings.toString(
                                    tokenToInfo[tokenId].profileChainId
                                ),
                                '"}]}'
                            )
                        )
                    )
                );
        else
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '{"name":"',
                                alphaDomain,
                                '","description":"',
                                alphaDomain,
                                ' - Relinkd Domain","image":"data:image/svg+xml;base64,',
                                _getSVGImageBase64Encoded(alphaDomain),
                                '","attributes":[{"trait_type":"id","value":"#',
                                Strings.toString(tokenId),
                                '"},{"trait_type":"owner","value":"',
                                Strings.toHexString(uint160(ownerOf(tokenId))),
                                '"},{"trait_type":"domain","value":"',
                                alphaDomain,
                                '"}]}'
                            )
                        )
                    )
                );
    }

    function _getSVGImageBase64Encoded(
        string memory alphaDomain
    ) internal view returns (string memory) {
        return
            Base64.encode(
                abi.encodePacked(
                    '<svg id="Layer_1" data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 113.33 113.33"><defs><style>.cls-2{fill:#',
                    _design.backgroundColor,
                    ';}</style></defs><defs><style>.cls-1{fill:#fff;}@font-face{font-family:"Space Grotesk";src:url(data:application/font-woff;charset=utf-8;base64,',
                    _design.font,
                    ') format("woff");} </style></defs><title>Artboard 1</title><rect class="cls-2" width="113.33" height="113.33"/>',
                    _design.logo,
                    '<text x="50%" y="85%" dominant-baseline="middle" text-anchor="middle" fill="#',
                    _design.fontColor,
                    '" font-family="Space Grotesk" font-size="',
                    Strings.toString(
                        _domainLengthToFontSize(bytes(alphaDomain).length)
                    ),
                    '" font-weight="500" letter-spacing="0em">',
                    alphaDomain,
                    "</text></svg>"
                )
            );
    }

    function _domainLengthToFontSize(
        uint256 domainLength
    ) internal pure returns (uint256) {
        return
            domainLength <= MAX_DOMAIN_LENGTH_WITH_DEFAULT_FONT_SIZE
                ? DEFAULT_FONT_SIZE
                : DEFAULT_FONT_SIZE - (domainLength - 15) / 2;
    }

    function _beforeTokenTransfer(
        address from,
        address,
        uint256 firstTokenId,
        uint256
    ) internal override {
        if (from != address(0)) {
            delete (
                profileToDomain[tokenToInfo[firstTokenId].profileChainId][
                    tokenToInfo[firstTokenId].linkedProfile
                ]
            );
            tokenToInfo[firstTokenId].linkedProfile = address(0);
        }
    }
}