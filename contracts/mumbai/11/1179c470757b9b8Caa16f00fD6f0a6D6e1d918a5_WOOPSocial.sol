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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Poseidon2 {
    function poseidon(uint256[2] memory) public pure returns (uint256) {}
}

library Poseidon3 {
    function poseidon(uint256[3] memory) public pure returns (uint256) {}
}

library Poseidon5 {
    function poseidon(uint256[5] memory) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {UnirepTypes} from '../types/UnirepTypes.sol';

interface IUnirep is UnirepTypes {
    event UserSignedUp(
        uint256 indexed epoch,
        uint256 indexed identityCommitment,
        uint256 attesterId,
        uint256 airdropAmount,
        uint256 leafIndex
    );

    event UserStateTransitioned(
        uint256 indexed epoch,
        uint256 indexed hashedLeaf,
        uint256 indexed leafIndex,
        uint256 firstEpkNullifier
    );

    event AttestationSubmitted(
        uint256 indexed epoch,
        uint256 indexed epochKey,
        address indexed attester,
        Attestation attestation
    );

    event NewGSTLeaf(
        uint256 indexed epoch,
        uint256 indexed leaf,
        uint256 indexed index
    );

    event EpochTreeLeaf(
        uint256 indexed epoch,
        uint256 indexed leaf,
        uint256 indexed index
    );

    event EpochEnded(uint256 indexed epoch);

    enum AttestationFieldError {
        POS_REP,
        NEG_REP,
        GRAFFITI
    }

    // error
    error UserAlreadySignedUp(uint256 identityCommitment);
    error ReachedMaximumNumberUserSignedUp();
    error AttesterAlreadySignUp(address attester);
    error AttesterNotSignUp(address attester);
    error ProofAlreadyUsed(bytes32 nullilier);
    error NullifierAlreadyUsed(uint256 nullilier);
    error AttestingFeeInvalid();
    error AttesterIdNotMatch(uint256 attesterId);
    error AirdropWithoutAttester();

    error InvalidSignature();
    error InvalidProofIndex();
    error InvalidSignUpFlag();
    error InvalidEpochKey();
    error EpochNotMatch();
    error InvalidTransitionEpoch();
    error InvalidBlindedUserState(uint256 blindedUserState);
    error InvalidBlindedHashChain(uint256 blindedHashChain);

    error InvalidSNARKField(AttestationFieldError); // better name???
    error EpochNotEndYet();
    error InvalidSignals();
    error InvalidProof();
    error InvalidGlobalStateTreeRoot(uint256 globalStateTreeRoot);
    error InvalidEpochTreeRoot(uint256 epochTreeRoot);

    /**
     * Sign up an attester using the address who sends the transaction
     */
    function attesterSignUp() external;

    /**
     * Sign up an attester using the claimed address and the signature
     * @param attester The address of the attester who wants to sign up
     * @param signature The signature of the attester
     */
    function attesterSignUpViaRelayer(
        address attester,
        bytes calldata signature
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Verifier interface
// Verifier should follow IVerifer interface.
interface IVerifier {
    /**
     * @return bool Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(uint256[8] calldata proof, uint256[] calldata input)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Snark contants that is used in Unirep
 */
contract SnarkConstants {
    // The scalar field
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // A nothing-up-my-sleeve zero value
    // Should be equal to 16916383162496104613127564537688207714240750091683495371401923915264313510848
    uint256 ZERO_VALUE =
        uint256(keccak256(abi.encodePacked('Unirep'))) % SNARK_SCALAR_FIELD;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

// verify signature use for relayer
// NOTE: This method not safe, contract may attack by signature replay.
contract VerifySignature {
    /**
     * Verify if the signer has a valid signature as claimed
     * @param signer The address of user who wants to perform an action
     * @param signature The signature signed by the signer
     */
    function isValidSignature(address signer, bytes memory signature)
        internal
        view
        returns (bool)
    {
        // Attester signs over it's own address concatenated with this contract address
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                '\x19Ethereum Signed Message:\n32',
                keccak256(abi.encodePacked(signer, this))
            )
        );
        return ECDSA.recover(messageHash, signature) == signer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SnarkConstants} from './SnarkConstants.sol';

/**
 * @dev zkSNARK helper for verifying snark constants
 */
contract zkSNARKHelper is SnarkConstants {
    function isSNARKField(uint256 value) internal pure returns (bool) {
        return value < SNARK_SCALAR_FIELD;
    }

    function isValidSignals(uint256[] memory signals)
        internal
        pure
        returns (bool)
    {
        uint256 len = signals.length;
        for (uint256 i = 0; i < len; ++i) {
            if (!isSNARKField(signals[i])) return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Poseidon2} from './Hash.sol';

struct SparseTreeData {
    uint256 depth;
    uint256 root;
    // depth to zero node
    mapping(uint256 => uint256) zeroes;
    // depth to index to leaf
    mapping(uint256 => mapping(uint256 => uint256)) leaves;
}

library SparseMerkleTree {
    uint8 internal constant MAX_DEPTH = 255;
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    function init(
        SparseTreeData storage self,
        uint256 depth,
        uint256 _zero
    ) public {
        require(_zero < SNARK_SCALAR_FIELD);
        require(depth > 0 && depth <= MAX_DEPTH);

        uint256 zero = _zero;

        self.depth = depth;

        for (uint8 i = 0; i < depth; ) {
            self.zeroes[i] = zero;
            zero = Poseidon2.poseidon([zero, zero]);

            unchecked {
                i++;
            }
        }
        self.root = zero;
    }

    function update(
        SparseTreeData storage self,
        uint256 index,
        uint256 leaf
    ) public {
        uint256 depth = self.depth;
        require(leaf < SNARK_SCALAR_FIELD);
        require(index < 2**depth);

        uint256 hash = leaf;
        uint256 lastLeftElement;
        uint256 lastRightElement;

        for (uint8 i = 0; i < depth; ) {
            self.leaves[i][index] = hash;
            if (index & 1 == 0) {
                uint256 siblingLeaf = self.leaves[i][index + 1];
                if (siblingLeaf == 0) siblingLeaf = self.zeroes[i];
                lastLeftElement = hash;
                lastRightElement = siblingLeaf;
            } else {
                uint256 siblingLeaf = self.leaves[i][index - 1];
                if (siblingLeaf == 0) siblingLeaf = self.zeroes[i];
                lastLeftElement = siblingLeaf;
                lastRightElement = hash;
            }

            hash = Poseidon2.poseidon([lastLeftElement, lastRightElement]);
            index >>= 1;

            unchecked {
                i++;
            }
        }

        self.root = hash;
    }

    function generateProof(SparseTreeData storage self, uint256 index)
        public
        view
        returns (uint256[] memory)
    {
        require(index < 2**self.depth);
        uint256[] memory proof = new uint256[](self.depth);
        for (uint8 i = 0; i < self.depth; ) {
            if (index & 1 == 0) {
                uint256 siblingLeaf = self.leaves[i][index + 1];
                if (siblingLeaf == 0) siblingLeaf = self.zeroes[i];
                proof[i] = siblingLeaf;
            } else {
                uint256 siblingLeaf = self.leaves[i][index - 1];
                if (siblingLeaf == 0) siblingLeaf = self.zeroes[i];
                proof[i] = siblingLeaf;
            }
            index >>= 1;
            unchecked {
                i++;
            }
        }
        return proof;
    }

    function computeRoot(
        SparseTreeData storage self,
        uint256 index,
        uint256 leaf
    ) public view returns (uint256) {
        uint256 depth = self.depth;
        require(leaf < SNARK_SCALAR_FIELD);
        require(index < 2**depth);

        uint256 hash = leaf;
        uint256 lastLeftElement;
        uint256 lastRightElement;

        for (uint8 i = 0; i < depth; ) {
            if (index & 1 == 0) {
                uint256 siblingLeaf = self.zeroes[i];
                lastLeftElement = hash;
                lastRightElement = siblingLeaf;
            } else {
                uint256 siblingLeaf = self.zeroes[i];
                lastLeftElement = siblingLeaf;
                lastRightElement = hash;
            }

            hash = Poseidon2.poseidon([lastLeftElement, lastRightElement]);
            index >>= 1;

            unchecked {
                i++;
            }
        }

        return hash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface UnirepTypes {
    struct Attestation {
        // The attester’s ID
        uint256 attesterId;
        // Positive reputation
        uint256 posRep;
        // Negative reputation
        uint256 negRep;
        // A hash of an arbitary string
        uint256 graffiti;
        // A flag to indicate if user has signed up in the attester's app
        uint256 signUp;
    }

    struct Config {
        // circuit config
        uint8 globalStateTreeDepth;
        uint8 userStateTreeDepth;
        uint8 epochTreeDepth;
        uint256 numEpochKeyNoncePerEpoch;
        uint256 maxReputationBudget;
        uint256 numAttestationsPerProof;
        // contract config
        uint256 epochLength;
        uint256 attestingFee;
        uint256 maxUsers;
        uint256 maxAttesters;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import {zkSNARKHelper} from './libraries/zkSNARKHelper.sol';
import {VerifySignature} from './libraries/VerifySignature.sol';

import {IUnirep} from './interfaces/IUnirep.sol';
import {IVerifier} from './interfaces/IVerifier.sol';
import {Poseidon5, Poseidon2} from './Hash.sol';
import {SparseMerkleTree, SparseTreeData} from './SparseMerkleTree.sol';

import {IncrementalBinaryTree, IncrementalTreeData} from '@zk-kit/incremental-merkle-tree.sol/IncrementalBinaryTree.sol';

/**
 * @title Unirep
 * @dev Unirep is a reputation which uses ZKP to preserve users' privacy.
 * Attester can give attestations to users, and users can optionally prove that how much reputation they have.
 *
 * In this contract, it stores all events in the Unirep protocol.
 * They consists of 3 main events:
 *   1. User sign up events
 *   2. Attestation events
 *   3. User state transition events
 * After events are successfully emitted, everyone can verify the proofs and generate a valid Unirep state
 * Then users can generate another proofs to interact with Unirep protocol.
 */
contract Unirep is IUnirep, zkSNARKHelper, VerifySignature {
    using SafeMath for uint256;

    // All verifier contracts
    IVerifier internal epkValidityVerifier;
    IVerifier internal startTransitionVerifier;
    IVerifier internal processAttestationsVerifier;
    IVerifier internal userStateTransitionVerifier;
    IVerifier internal reputationVerifier;
    IVerifier internal userSignUpVerifier;

    // Circuits configurations and contracts configurations
    Config public config;

    // The max epoch key can be computed by 2** config.epochTreeDepth
    uint256 public immutable maxEpochKey;
    uint256 public currentEpoch = 1;
    uint256 public latestEpochTransitionTime;
    uint256 public numUserSignUps = 0;

    // The index of all proofs, 0 is reserved for index not found in getProofIndex
    uint256 internal proofIndex = 1;

    // Mapping of proof nullifiers and the proof index
    mapping(bytes32 => uint256) public getProofIndex;
    mapping(uint256 => bool) public hasUserSignedUp;
    mapping(uint256 => mapping(uint256 => uint256))
        public attestationHashchains;

    mapping(uint256 => SparseTreeData) public epochTrees;
    mapping(uint256 => IncrementalTreeData) public globalStateTree;
    // epoch => root => bool
    mapping(uint256 => mapping(uint256 => bool)) public globalStateTreeRoots;
    SparseTreeData internal initUST;

    // Attesting fee collected so far
    uint256 public collectedAttestingFee;

    // Mapping of voluteers that execute epoch transition to compensation they earned
    mapping(address => uint256) public epochTransitionCompensation;

    //  A mapping between each attesters’ address and their attester ID.
    // Attester IDs are incremental and start from 1.
    // No attesters with and ID of 0 should exist.
    mapping(address => uint256) public attesters;
    uint256 public nextAttesterId = 1;
    // Mapping of existing nullifiers to the epoch of emitted
    mapping(uint256 => uint256) public usedNullifiers;
    // Mapping of existing blinded user states
    mapping(uint256 => bool) public submittedBlindedUserStates;
    // Mapping of existing blinded hash chains
    mapping(uint256 => bool) public submittedBlindedHashChains;

    constructor(
        Config memory _config,
        IVerifier _epkValidityVerifier,
        IVerifier _startTransitionVerifier,
        IVerifier _processAttestationsVerifier,
        IVerifier _userStateTransitionVerifier,
        IVerifier _reputationVerifier,
        IVerifier _userSignUpVerifier
    ) {
        config = _config;

        // Set the verifier contracts
        epkValidityVerifier = _epkValidityVerifier;
        startTransitionVerifier = _startTransitionVerifier;
        processAttestationsVerifier = _processAttestationsVerifier;
        userStateTransitionVerifier = _userStateTransitionVerifier;
        reputationVerifier = _reputationVerifier;
        userSignUpVerifier = _userSignUpVerifier;

        latestEpochTransitionTime = block.timestamp;

        // Check and store the maximum number of signups
        // It is the user's responsibility to ensure that the state tree depth
        // is just large enough and not more, or they will waste gas.
        uint256 GSTMaxLeafIndex = uint256(2)**config.globalStateTreeDepth - 1;
        require(
            config.maxUsers <= GSTMaxLeafIndex,
            'Unirep: invalid maxUsers value'
        );

        uint256 USTMaxLeafIndex = uint256(2)**config.userStateTreeDepth - 1;
        require(
            config.maxAttesters <= USTMaxLeafIndex,
            'Unirep: invalid maxAttesters value'
        );

        maxEpochKey = uint256(2)**config.epochTreeDepth - 1;
        uint256 zero = 0;
        uint256 one = 1;
        uint256 defaultUSTLeaf = Poseidon5.poseidon(
            [zero, zero, zero, zero, zero]
        );
        uint256 defaultEpochTreeLeaf = Poseidon2.poseidon([one, zero]);
        SparseMerkleTree.init(
            initUST,
            config.userStateTreeDepth,
            defaultUSTLeaf
        );
        SparseMerkleTree.init(
            epochTrees[currentEpoch],
            config.epochTreeDepth,
            defaultEpochTreeLeaf
        );
        IncrementalBinaryTree.init(
            globalStateTree[currentEpoch],
            config.globalStateTreeDepth,
            0
        );
        globalStateTreeRoots[currentEpoch][
            globalStateTree[currentEpoch].root
        ] = true;
    }

    // Verify input data - Should found better way to handle it.
    function verifyAttesterSignUp(address attester) private view {
        if (attesters[attester] == 0) revert AttesterNotSignUp(attester);
    }

    function verifyProofNullifier(bytes32 proofNullifier) private view {
        if (getProofIndex[proofNullifier] != 0)
            revert ProofAlreadyUsed(proofNullifier);
    }

    function verifyNullifier(uint256 nullifier) private {
        require(nullifier != 0);
        if (usedNullifiers[nullifier] > 0)
            revert NullifierAlreadyUsed(nullifier);
        // Mark the nullifier as used
        usedNullifiers[nullifier] = currentEpoch;
    }

    /**
     * @dev User signs up by providing an identity commitment. It also inserts a fresh state leaf into the state tree.
     * An attester may specify an `initBalance` of reputation the user can use in the current epoch
     * @param identityCommitment Commitment of the user's identity which is a semaphore identity.
     * @param initBalance the starting reputation balance
     */
    function userSignUp(uint256 identityCommitment, uint256 initBalance)
        public
    {
        if (hasUserSignedUp[identityCommitment] == true)
            revert UserAlreadySignedUp(identityCommitment);
        if (numUserSignUps >= config.maxUsers)
            revert ReachedMaximumNumberUserSignedUp();

        uint256 attesterId = attesters[msg.sender];
        if (attesterId == 0 && initBalance != 0)
            revert AirdropWithoutAttester();

        hasUserSignedUp[identityCommitment] = true;
        numUserSignUps++;

        uint256 root = initUST.root;
        if (attesterId > 0) {
            uint256 initUSTLeaf = Poseidon5.poseidon(
                [
                    initBalance, // posRep
                    0, // negRep
                    0, // graffiti
                    1, // signup
                    0
                ]
            );
            // calculate the initial smt root by inserting at attesterId index
            root = SparseMerkleTree.computeRoot(
                initUST,
                attesterId,
                initUSTLeaf
            );
        }

        uint256 newGSTLeaf = Poseidon2.poseidon([identityCommitment, root]);
        emit UserSignedUp(
            currentEpoch,
            identityCommitment,
            attesterId,
            initBalance,
            globalStateTree[currentEpoch].numberOfLeaves
        );
        emit NewGSTLeaf(
            currentEpoch,
            newGSTLeaf,
            globalStateTree[currentEpoch].numberOfLeaves
        );
        IncrementalBinaryTree.insert(globalStateTree[currentEpoch], newGSTLeaf);
        globalStateTreeRoots[currentEpoch][
            globalStateTree[currentEpoch].root
        ] = true;
    }

    /**
     * overload, see above
     */
    function userSignUp(uint256 identityCommitment) public {
        userSignUp(identityCommitment, 0);
    }

    /**
     * @dev Check if attester can successfully sign up in Unirep.
     */
    function _attesterSignUp(address attester) private {
        if (attesters[attester] != 0) revert AttesterAlreadySignUp(attester);

        if (nextAttesterId >= config.maxAttesters)
            revert ReachedMaximumNumberUserSignedUp();

        attesters[attester] = nextAttesterId;
        nextAttesterId++;
    }

    /**
     * @dev Sign up an attester using the address who sends the transaction
     */
    function attesterSignUp() external override {
        _attesterSignUp(msg.sender);
    }

    /**
     * @dev Sign up an attester using the claimed address and the signature
     * @param attester The address of the attester who wants to sign up
     * @param signature The signature of the attester
     */
    function attesterSignUpViaRelayer(
        address attester,
        bytes calldata signature
    ) external override {
        if (!isValidSignature(attester, signature)) revert InvalidSignature();
        _attesterSignUp(attester);
    }

    /**
     * @dev Check the validity of the attestation and the attester, emit the attestation event.
     * @param attester The address of the attester
     * @param attestation The attestation including positive reputation, negative reputation or graffiti
     * @param epochKey The epoch key which receives attestation
     */
    function assertValidAttestation(
        address attester,
        Attestation memory attestation,
        uint256 epochKey
    ) internal view {
        verifyAttesterSignUp(attester);
        if (msg.value < config.attestingFee) revert AttestingFeeInvalid();
        if (attesters[attester] != attestation.attesterId)
            revert AttesterIdNotMatch(attestation.attesterId);

        if (attestation.signUp != 0 && attestation.signUp != 1)
            revert InvalidSignUpFlag();

        if (epochKey > maxEpochKey) revert InvalidEpochKey();

        // Validate attestation data
        if (!isSNARKField(attestation.posRep))
            revert InvalidSNARKField(AttestationFieldError.POS_REP);

        if (!isSNARKField(attestation.negRep))
            revert InvalidSNARKField(AttestationFieldError.NEG_REP);

        if (!isSNARKField(attestation.graffiti))
            revert InvalidSNARKField(AttestationFieldError.GRAFFITI);
    }

    // increment the hashchain and leave the chain unsealed.
    // Also store a sealed copy of the hashchain in the epoch tree
    function storeAttestation(Attestation memory attestation, uint256 epochKey)
        internal
    {
        uint256 attestationHash = Poseidon5.poseidon(
            [
                attestation.attesterId,
                attestation.posRep,
                attestation.negRep,
                attestation.graffiti,
                attestation.signUp
            ]
        );
        uint256 currentHashchain = attestationHashchains[currentEpoch][
            epochKey
        ];
        uint256 newHashchain = Poseidon2.poseidon(
            [attestationHash, currentHashchain]
        );
        // store the latest unsealed hashchain so we can add to it later
        attestationHashchains[currentEpoch][epochKey] = newHashchain;
        // then store the sealed hashchain
        uint256 sealedHashchain = Poseidon2.poseidon([1, newHashchain]);
        SparseMerkleTree.update(
            epochTrees[currentEpoch],
            epochKey,
            sealedHashchain
        );

        emit EpochTreeLeaf(currentEpoch, sealedHashchain, epochKey);
    }

    /**
     * @dev An attester submit the attestation with a proof index that the attestation will be sent to
     * and(or) a proof index that the attestation is from
     * If the fromProofIndex is non-zero, it should be valid then the toProofIndex can receive the attestation
     * @param attestation The attestation that the attester wants to send to the epoch key
     * @param epochKey The epoch key which receives attestation
     */
    function submitAttestation(
        Attestation calldata attestation,
        uint256 epochKey
    ) external payable {
        assertValidAttestation(msg.sender, attestation, epochKey);

        if (epochKey > maxEpochKey) revert InvalidEpochKey();

        collectedAttestingFee = collectedAttestingFee.add(msg.value);

        emit AttestationSubmitted(
            currentEpoch,
            epochKey,
            msg.sender,
            attestation
        );

        storeAttestation(attestation, epochKey);
    }

    /**
     * @dev An attester submit the attestation with an epoch key proof via a relayer
     * @param attester The address of the attester
     * @param signature The signature of the attester
     * @param attestation The attestation including positive reputation, negative reputation or graffiti
     * @param epochKey The epoch key which receives attestation
     */
    function submitAttestationViaRelayer(
        address attester,
        bytes calldata signature,
        Attestation calldata attestation,
        uint256 epochKey
    ) external payable {
        if (!isValidSignature(attester, signature)) revert InvalidSignature();
        assertValidAttestation(attester, attestation, epochKey);
        if (epochKey > maxEpochKey) revert InvalidEpochKey();

        collectedAttestingFee = collectedAttestingFee.add(msg.value);

        emit AttestationSubmitted(
            currentEpoch,
            epochKey,
            attester,
            attestation
        );

        storeAttestation(attestation, epochKey);
    }

    /**
     * @dev A user should submit an epoch key proof and get a proof index
     * publicSignals[0] = [ epochKey ]
     * publicSignals[1] = [ globalStateTree ]
     * publicSignals[2] = [ epoch ]
     * @param publicSignals The public signals of the epoch key proof
     * @param proof The The proof of the epoch key proof
     */
    function assertValidEpochKeyProof(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) external view {
        uint256 _epoch = publicSignals[2];
        uint256 _globalStateTreeRoot = publicSignals[1];

        // check if proof is submitted before
        if (_epoch != currentEpoch) revert EpochNotMatch();
        if (publicSignals[0] > maxEpochKey) revert InvalidEpochKey();

        // verify global state tree root
        if (globalStateTreeRoots[_epoch][_globalStateTreeRoot] == false)
            revert InvalidGlobalStateTreeRoot(_globalStateTreeRoot);

        // verify proof
        bool isValid = verifyEpochKeyValidity(publicSignals, proof);
        if (isValid == false) revert InvalidProof();
    }

    /**
     * @dev A user spend reputation via an attester, the non-zero nullifiers will be processed as a negative attestation
     * publicSignals[0] = [ epochKey ]
     * publicSignals[1] = [ globalStateTree ]
     * publicSignals[2: maxReputationBudget + 2] = [ reputationNullifiers ]
     * publicSignals[maxReputationBudget + 2] = [ epoch ]
     * publicSignals[maxReputationBudget + 3] = [ attesterId ]
     * publicSignals[maxReputationBudget + 4] = [ proveReputationAmount ]
     * publicSignals[maxReputationBudget + 5] = [ minRep ]
     * publicSignals[maxReputationBudget + 6] = [ minRep ]
     * publicSignals[maxReputationBudget + 7] = [ proveGraffiti ]
     * publicSignals[maxReputationBudget + 8] = [ graffitiPreImage ]
     * @param publicSignals The public signals of the reputation proof
     * @param proof The The proof of the reputation proof
     */
    function spendReputation(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) external payable {
        // check if proof is submitted before
        bytes32 proofNullifier = keccak256(
            abi.encodePacked(publicSignals, proof)
        );
        uint256 _maxReputationBudget = config.maxReputationBudget;
        uint256 _epoch = publicSignals[_maxReputationBudget + 2];
        uint256 _globalStateTreeRoot = publicSignals[1];
        uint256 _epochKey = publicSignals[0];

        if (getProofIndex[proofNullifier] != 0)
            revert ProofAlreadyUsed(proofNullifier);

        if (publicSignals[_maxReputationBudget + 2] != currentEpoch)
            revert EpochNotMatch();

        for (uint256 index = 2; index < 2 + _maxReputationBudget; index++) {
            if (publicSignals[index] > 0) verifyNullifier(publicSignals[index]);
        }

        // verify global state tree root
        if (globalStateTreeRoots[_epoch][_globalStateTreeRoot] == false)
            revert InvalidGlobalStateTreeRoot(_globalStateTreeRoot);

        // verify proof
        bool isValid = verifyReputation(publicSignals, proof);
        if (isValid == false) revert InvalidProof();

        // attestation of spending reputation
        Attestation memory attestation;
        attestation.attesterId = publicSignals[_maxReputationBudget + 3];
        attestation.negRep = publicSignals[_maxReputationBudget + 4];

        assertValidAttestation(msg.sender, attestation, _epochKey);
        // Add to the cumulated attesting fee
        collectedAttestingFee = collectedAttestingFee.add(msg.value);

        emit AttestationSubmitted(
            currentEpoch,
            _epochKey,
            msg.sender,
            attestation
        );
        getProofIndex[proofNullifier] = 1;
        storeAttestation(attestation, _epochKey);
    }

    /**
     * @dev Perform an epoch transition, current epoch increases by 1
     */
    function beginEpochTransition() external {
        uint256 initGas = gasleft();

        if (block.timestamp - latestEpochTransitionTime < config.epochLength)
            revert EpochNotEndYet();

        // Mark epoch transitioned as complete and increase currentEpoch
        emit EpochEnded(currentEpoch);

        latestEpochTransitionTime = block.timestamp;
        currentEpoch++;

        // avoid calling init by manually copying zero values and root
        for (uint8 i; i < config.epochTreeDepth; i++) {
            epochTrees[currentEpoch].zeroes[i] = epochTrees[currentEpoch - 1]
                .zeroes[i];
        }
        epochTrees[currentEpoch].root = Poseidon2.poseidon(
            [
                epochTrees[currentEpoch].zeroes[config.epochTreeDepth - 1],
                epochTrees[currentEpoch].zeroes[config.epochTreeDepth - 1]
            ]
        );
        epochTrees[currentEpoch].depth = config.epochTreeDepth;
        for (uint8 i; i < config.globalStateTreeDepth; i++) {
            globalStateTree[currentEpoch].zeroes[i] = globalStateTree[
                currentEpoch - 1
            ].zeroes[i];
        }
        globalStateTree[currentEpoch].root = Poseidon2.poseidon(
            [
                globalStateTree[currentEpoch].zeroes[
                    config.globalStateTreeDepth - 1
                ],
                globalStateTree[currentEpoch].zeroes[
                    config.globalStateTreeDepth - 1
                ]
            ]
        );
        globalStateTree[currentEpoch].depth = config.globalStateTreeDepth;
        globalStateTreeRoots[currentEpoch][
            globalStateTree[currentEpoch].root
        ] = true;

        uint256 gasUsed = initGas.sub(gasleft());
        epochTransitionCompensation[msg.sender] = epochTransitionCompensation[
            msg.sender
        ].add(gasUsed.mul(tx.gasprice));
    }

    /**
     * @dev User submit a start user state transition proof
     * publicSignals[0] = [ globalStateTree ]
     * publicSignals[1] = [ blindedUserState ]
     * publicSignals[2] = [ blindedHashChain ]
     * @param publicSignals The public signals of the start user state transition proof
     * @param proof The The proof of the start user state transition proof
     */
    function startUserStateTransition(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) external {
        // check if proof is submitted before
        bytes32 proofNullifier = keccak256(
            abi.encodePacked(publicSignals, proof)
        );
        if (getProofIndex[proofNullifier] != 0)
            revert ProofAlreadyUsed(proofNullifier);

        // verify proof
        bool isValid = verifyStartTransitionProof(publicSignals, proof);
        if (isValid == false) revert InvalidProof();

        submittedBlindedUserStates[publicSignals[1]] = true;
        submittedBlindedHashChains[publicSignals[2]] = true;

        getProofIndex[proofNullifier] = 1;
    }

    /**
     * @dev User submit a process attestations proof
     * publicSignals[0] = [ outputBlindedUserState ]
     * publicSignals[1] = [ outputBlindedHashChain ]
     * publicSignals[2] = [ inputBlindedUserState ]
     * @param publicSignals The public signals of the process attestations proof
     * @param proof The process attestations proof
     */
    function processAttestations(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) external {
        // check if proof is submitted before
        bytes32 proofNullifier = keccak256(
            abi.encodePacked(publicSignals, proof)
        );
        if (getProofIndex[proofNullifier] != 0)
            revert ProofAlreadyUsed(proofNullifier);

        uint256 _inputBlindedUserState = publicSignals[2];
        if (submittedBlindedUserStates[_inputBlindedUserState] == false)
            revert InvalidBlindedUserState(_inputBlindedUserState);

        submittedBlindedUserStates[publicSignals[0]] = true;
        submittedBlindedHashChains[publicSignals[1]] = true;

        // verify proof
        bool isValid = verifyProcessAttestationProof(publicSignals, proof);
        if (isValid == false) revert InvalidProof();

        getProofIndex[proofNullifier] = 1;
    }

    /**
     * @dev User submit the latest user state transition proof
     * publicSignals[0] = [ fromGlobalStateTree ]
     * publicSignals[1] = [ newGlobalStateTreeLeaf ]
     * publicSignals[2: 2 + numEpochKeyNoncePerEpoch] = [ epkNullifiers ]
     * publicSignals[2 + numEpochKeyNoncePerEpoch] = [ transitionFromEpoch ]
     * publicSignals[3 + numEpochKeyNoncePerEpoch:
                     5+  numEpochKeyNoncePerEpoch] = [ blindedUserStates ]
     * publicSignals[5+  numEpochKeyNoncePerEpoch:
                     5+2*numEpochKeyNoncePerEpoch] = [ blindedHashChains ]
     * publicSignals[5+2*numEpochKeyNoncePerEpoch] = [ fromEpochTree ]
     * @param publicSignals The the public signals of the user state transition proof
     * @param proof The proof of the user state transition proof
     */
    function updateUserStateRoot(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) external {
        // check if proof is submitted before
        bytes32 proofNullifier = keccak256(
            abi.encodePacked(publicSignals, proof)
        );
        if (getProofIndex[proofNullifier] != 0)
            revert ProofAlreadyUsed(proofNullifier);
        uint256 _numEpochKeyNoncePerEpoch = config.numEpochKeyNoncePerEpoch;
        // NOTE: this impl assumes all attestations are processed in a single snark.
        if (publicSignals[2 + _numEpochKeyNoncePerEpoch] >= currentEpoch)
            revert InvalidTransitionEpoch();

        for (uint256 index = 2; index < 2 + _numEpochKeyNoncePerEpoch; index++)
            verifyNullifier(publicSignals[index]);

        // verify blindned user states
        for (
            uint256 index = 3 + _numEpochKeyNoncePerEpoch;
            index < 5 + _numEpochKeyNoncePerEpoch;
            index++
        ) {
            if (submittedBlindedUserStates[publicSignals[index]] == false)
                revert InvalidBlindedUserState(publicSignals[index]);
        }

        // verify blinded hash chains
        for (
            uint256 index = 5 + _numEpochKeyNoncePerEpoch;
            index < 5 + 2 * _numEpochKeyNoncePerEpoch;
            index++
        ) {
            if (submittedBlindedHashChains[publicSignals[index]] == false)
                revert InvalidBlindedHashChain(publicSignals[index]);
        }
        // check the from gst root
        uint256 fromEpoch = publicSignals[2 + _numEpochKeyNoncePerEpoch];
        uint256 fromGSTRoot = publicSignals[0];
        if (globalStateTreeRoots[fromEpoch][fromGSTRoot] == false)
            revert InvalidGlobalStateTreeRoot(fromGSTRoot);
        // check the from epoch tree root
        uint256 fromEpochTreeRoot = publicSignals[
            5 + 2 * _numEpochKeyNoncePerEpoch
        ];
        if (epochRoots(fromEpoch) != fromEpochTreeRoot)
            revert InvalidEpochTreeRoot(fromEpochTreeRoot);

        // verify proof
        bool isValid = verifyUserStateTransition(publicSignals, proof);
        if (isValid == false) revert InvalidProof();

        // update global state tree
        emit NewGSTLeaf(
            currentEpoch,
            publicSignals[1],
            globalStateTree[currentEpoch].numberOfLeaves
        );
        IncrementalBinaryTree.insert(
            globalStateTree[currentEpoch],
            publicSignals[1]
        );
        globalStateTreeRoots[currentEpoch][
            globalStateTree[currentEpoch].root
        ] = true;

        getProofIndex[proofNullifier] = 1;

        emit UserStateTransitioned(
            currentEpoch,
            publicSignals[1],
            globalStateTree[currentEpoch].numberOfLeaves,
            publicSignals[2] // first epoch key nullifier
        );
    }

    /**
     * @dev Verify epoch transition proof
     * publicSignals[0] = [ globalStateTree ]
     * publicSignals[1] = [ epoch ]
     * publicSignals[2] = [ epochKey ]
     * @param publicSignals The public signals of the epoch key proof
     * @param proof The The proof of the epoch key proof
     */
    function verifyEpochKeyValidity(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) public view returns (bool) {
        // Before attesting to a given epoch key, an attester must verify validity of the epoch key:
        // 1. user has signed up
        // 2. nonce is no greater than numEpochKeyNoncePerEpoch
        // 3. user has transitioned to the epoch(by proving membership in the globalStateTree of that epoch)
        // 4. epoch key is correctly computed

        // Ensure that each public input is within range of the snark scalar
        // field.
        // TODO: consider having more granular revert reasons
        if (!isValidSignals(publicSignals)) revert InvalidSignals();

        // Verify the proof
        return epkValidityVerifier.verifyProof(proof, publicSignals);
    }

    /**
     * @dev Verify start user state transition proof
     * publicSignals[0] = [ blindedUserState ]
     * publicSignals[1] = [ blindedHashChain ]
     * publicSignals[2] = [ globalStateTree ]
     * @param publicSignals The public signals of the start user state transition proof
     * @param proof The The proof of the start user state transition proof
     */
    function verifyStartTransitionProof(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) public view returns (bool) {
        // The start transition proof checks that
        // 1. user has signed up
        // 2. blinded user state is computed by: hash(identity, UST_root, epoch, epoch_key_nonce)
        // 3. blinded hash chain is computed by: hash(identity, hash_chain = 0, epoch, epoch_key_nonce)
        // 4. user has transitioned to some epoch(by proving membership in the globalStateTree of that epoch)

        // Ensure that each public input is within range of the snark scalar
        // field.
        // TODO: consider having more granular revert reasons
        if (!isValidSignals(publicSignals)) revert InvalidSignals();

        // Verify the proof
        return startTransitionVerifier.verifyProof(proof, publicSignals);
    }

    /**
     * @dev Verify process attestations proof
     * publicSignals[0] = [ outputBlindedUserState ]
     * publicSignals[1] = [ outputBlindedHashChain ]
     * publicSignals[2] = [ inputBlindedUserState ]
     * @param publicSignals The public signals of the process attestations proof
     * @param proof The process attestations proof
     */
    function verifyProcessAttestationProof(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) public view returns (bool) {
        // The process attestations proof checks that
        // 1. user processes attestations correctly and update the hash chain and user state tree
        // 2. input blinded state is computed by: hash(identity, user_state_tree_root, epoch, from_epk_nonce)
        // 3. output blinded state is computed by: hash(identity, user_state_tree_root, epoch, to_epk_nonce)
        // 4. output hash chain is computed by:  hash(identity, hash_chain, epoch, to_epk_nonce)

        // Ensure that each public input is within range of the snark scalar
        // field.
        if (!isValidSignals(publicSignals)) revert InvalidSignals();

        // Verify the proof
        return processAttestationsVerifier.verifyProof(proof, publicSignals);
    }

    /**
     * @dev Verify user state transition proof
     * publicSignals[0                                    ] = [ newGlobalStateTreeLeaf ]
     * publicSignals[1: this.numEpochKeyNoncePerEpoch + 1 ] = [ epkNullifiers          ]
     * publicSignals[this.numEpochKeyNoncePerEpoch + 1    ] = [ transitionFromEpoch    ]
     * publicSignals[this.numEpochKeyNoncePerEpoch + 2,
     *               this.numEpochKeyNoncePerEpoch + 4    ] = [ blindedUserStates      ]
     * publicSignals[4 + this.numEpochKeyNoncePerEpoch    ] = [ fromGlobalStateTree    ]
     * publicSignals[5 + this.numEpochKeyNoncePerEpoch,
     *               5 + 2 * this.numEpochKeyNoncePerEpoch] = [ blindedHashChains      ]
     * publicSignals[5 + 2 * this.numEpochKeyNoncePerEpoch] = [ fromEpochTree          ]
     * @param publicSignals The public signals of the sign up proof
     * @param proof The The proof of the sign up proof
     */
    function verifyUserStateTransition(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) public view returns (bool) {
        // Verify validity of new user state:
        // 1. User's identity and state exist in the provided global state tree
        // 2. All epoch key nonces are processed and blinded hash chains are computed
        // 3. All epoch key nonces are processed and user state trees are computed
        // 4. Compute new global state tree leaf: hash(id, user_state_tree_root)

        if (!isValidSignals(publicSignals)) revert InvalidSignals();

        // Verify the proof
        return userStateTransitionVerifier.verifyProof(proof, publicSignals);
    }

    /**
     * @dev Verify reputation proof
     * publicSignals[0: maxReputationBudget ] = [ reputationNullifiers ]
     * publicSignals[maxReputationBudget    ] = [ epoch ]
     * publicSignals[maxReputationBudget + 1] = [ epochKey ]
     * publicSignals[maxReputationBudget + 2] = [ globalStateTree ]
     * publicSignals[maxReputationBudget + 3] = [ attesterId ]
     * publicSignals[maxReputationBudget + 4] = [ proveReputationAmount ]
     * publicSignals[maxReputationBudget + 5] = [ minRep ]
     * publicSignals[maxReputationBudget + 6] = [ proveGraffiti ]
     * publicSignals[maxReputationBudget + 7] = [ graffitiPreImage ]
     * @param publicSignals The public signals of the reputation proof
     * @param proof The The proof of the reputation proof
     */
    function verifyReputation(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) public view returns (bool) {
        // User prove his reputation by an attester:
        // 1. User exists in GST
        // 2. It is the latest state user transition to
        // 3. (optional) different reputation nullifiers equals to prove reputation amount
        // 4. (optional) (positive reputation - negative reputation) is greater than `_minRep`
        // 5. (optional) hash of graffiti pre-image matches

        // Ensure that each public input is within range of the snark scalar
        // field.
        if (!isValidSignals(publicSignals)) revert InvalidSignals();

        // Verify the proof
        return reputationVerifier.verifyProof(proof, publicSignals);
    }

    /**
     * @dev Verify user sign up proof
     * publicSignals[0] = [ epoch ]
     * publicSignals[1] = [ epochKey ]
     * publicSignals[2] = [ globalStateTree ]
     * publicSignals[3] = [ attesterId ]
     * publicSignals[4] = [ userHasSignedUp ]
     * @param publicSignals The public signals of the sign up proof
     * @param proof The The proof of the sign up proof
     */
    function verifyUserSignUp(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) public view returns (bool) {
        // User prove his reputation by an attester:
        // 1. User exists in GST
        // 2. It is the latest state user transition to
        // 3. User has a signUp flag in the attester's leaf

        // Ensure that each public input is within range of the snark scalar
        // field.
        if (!isValidSignals(publicSignals)) revert InvalidSignals();

        // Verify the proof
        return userSignUpVerifier.verifyProof(proof, publicSignals);
    }

    /**
     * @dev Functions to burn fee and collect compenstation.
     * TODO: Should use attester fee, shouldn't burn like this.
     */
    function burnAttestingFee() external {
        uint256 amount = collectedAttestingFee;
        collectedAttestingFee = 0;
        Address.sendValue(payable(address(0)), amount);
    }

    /**
     * @dev Users who helps to perform epoch transition can get compensation
     */
    function collectEpochTransitionCompensation() external {
        // NOTE: currently there are no revenue to pay for epoch transition compensation
        uint256 amount = epochTransitionCompensation[msg.sender];
        epochTransitionCompensation[msg.sender] = 0;
        Address.sendValue(payable(msg.sender), amount);
    }

    function globalStateTreeDepth() public view returns (uint8) {
        return config.globalStateTreeDepth;
    }

    function userStateTreeDepth() public view returns (uint8) {
        return config.userStateTreeDepth;
    }

    function epochTreeDepth() public view returns (uint8) {
        return config.epochTreeDepth;
    }

    function numEpochKeyNoncePerEpoch() public view returns (uint256) {
        return config.numEpochKeyNoncePerEpoch;
    }

    function maxReputationBudget() public view returns (uint256) {
        return config.maxReputationBudget;
    }

    function numAttestationsPerProof() public view returns (uint256) {
        return config.numAttestationsPerProof;
    }

    function epochLength() public view returns (uint256) {
        return config.epochLength;
    }

    function attestingFee() public view returns (uint256) {
        return config.attestingFee;
    }

    function maxUsers() public view returns (uint256) {
        return config.maxUsers;
    }

    function maxAttesters() public view returns (uint256) {
        return config.maxAttesters;
    }

    function epochTreeProof(uint256 epoch, uint256 leafIndex)
        public
        view
        returns (uint256[] memory)
    {
        return SparseMerkleTree.generateProof(epochTrees[epoch], leafIndex);
    }

    function epochRoots(uint256 epoch) public view returns (uint256) {
        return epochTrees[epoch].root;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library PoseidonT3 {
    function poseidon(uint256[2] memory) public pure returns (uint256) {}
}

library PoseidonT6 {
    function poseidon(uint256[5] memory) public pure returns (uint256) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {PoseidonT3} from "./Hashes.sol";

// Each incremental tree has certain properties and data that will
// be used to add new leaves.
struct IncrementalTreeData {
    uint256 depth; // Depth of the tree (levels - 1).
    uint256 root; // Root hash of the tree.
    uint256 numberOfLeaves; // Number of leaves of the tree.
    mapping(uint256 => uint256) zeroes; // Zero hashes used for empty nodes (level -> zero hash).
    // The nodes of the subtrees used in the last addition of a leaf (level -> [left node, right node]).
    mapping(uint256 => uint256[2]) lastSubtrees; // Caching these values is essential to efficient appends.
}

/// @title Incremental binary Merkle tree.
/// @dev The incremental tree allows to calculate the root hash each time a leaf is added, ensuring
/// the integrity of the tree.
library IncrementalBinaryTree {
    uint8 internal constant MAX_DEPTH = 32;
    uint256 internal constant SNARK_SCALAR_FIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /// @dev Initializes a tree.
    /// @param self: Tree data.
    /// @param depth: Depth of the tree.
    /// @param zero: Zero value to be used.
    function init(
        IncrementalTreeData storage self,
        uint256 depth,
        uint256 zero
    ) public {
        require(zero < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(depth > 0 && depth <= MAX_DEPTH, "IncrementalBinaryTree: tree depth must be between 1 and 32");

        self.depth = depth;

        for (uint8 i = 0; i < depth; ) {
            self.zeroes[i] = zero;
            zero = PoseidonT3.poseidon([zero, zero]);

            unchecked {
                ++i;
            }
        }

        self.root = zero;
    }

    /// @dev Inserts a leaf in the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be inserted.
    function insert(IncrementalTreeData storage self, uint256 leaf) public {
        uint256 depth = self.depth;

        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(self.numberOfLeaves < 2**depth, "IncrementalBinaryTree: tree is full");

        uint256 index = self.numberOfLeaves;
        uint256 hash = leaf;

        for (uint8 i = 0; i < depth; ) {
            if (index & 1 == 0) {
                self.lastSubtrees[i] = [hash, self.zeroes[i]];
            } else {
                self.lastSubtrees[i][1] = hash;
            }

            hash = PoseidonT3.poseidon(self.lastSubtrees[i]);
            index >>= 1;

            unchecked {
                ++i;
            }
        }

        self.root = hash;
        self.numberOfLeaves += 1;
    }

    /// @dev Updates a leaf in the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be updated.
    /// @param newLeaf: New leaf.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function update(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256 newLeaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        require(
            verify(self, leaf, proofSiblings, proofPathIndices),
            "IncrementalBinaryTree: leaf is not part of the tree"
        );

        uint256 depth = self.depth;
        uint256 hash = newLeaf;

        uint256 updateIndex;
        for (uint8 i = 0; i < depth; ) {
            updateIndex |= uint256(proofPathIndices[i] & 1) << uint256(i);
            if (proofPathIndices[i] == 0) {
                if (proofSiblings[i] == self.lastSubtrees[i][1]) {
                    self.lastSubtrees[i][0] = hash;
                }

                hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
            } else {
                if (proofSiblings[i] == self.lastSubtrees[i][0]) {
                    self.lastSubtrees[i][1] = hash;
                }

                hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
            }

            unchecked {
                ++i;
            }
        }
        require(updateIndex < self.numberOfLeaves, "IncrementalBinaryTree: leaf index out of range");

        self.root = hash;
    }

    /// @dev Removes a leaf from the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    function remove(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) public {
        update(self, leaf, self.zeroes[0], proofSiblings, proofPathIndices);
    }

    /// @dev Verify if the path is correct and the leaf is part of the tree.
    /// @param self: Tree data.
    /// @param leaf: Leaf to be removed.
    /// @param proofSiblings: Array of the sibling nodes of the proof of membership.
    /// @param proofPathIndices: Path of the proof of membership.
    /// @return True or false.
    function verify(
        IncrementalTreeData storage self,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) private view returns (bool) {
        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        uint256 depth = self.depth;
        require(
            proofPathIndices.length == depth && proofSiblings.length == depth,
            "IncrementalBinaryTree: length of path is not correct"
        );

        uint256 hash = leaf;

        for (uint8 i = 0; i < depth; ) {
            require(
                proofSiblings[i] < SNARK_SCALAR_FIELD,
                "IncrementalBinaryTree: sibling node must be < SNARK_SCALAR_FIELD"
            );

            if (proofPathIndices[i] == 0) {
                hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
            } else {
                hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
            }

            unchecked {
                ++i;
            }
        }

        return hash == self.root;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma abicoder v2;
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import { Unirep } from "@unirep/contracts/Unirep.sol";
import { zkSNARKHelper } from '@unirep/contracts/libraries/zkSNARKHelper.sol';

interface IVerifier {
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[5] memory input
    ) external view returns (bool r);
    function verifyProof(
        uint[2] memory a,
        uint[2][2] memory b,
        uint[2] memory c,
        uint[6] memory input
    ) external view returns (bool r);
}

contract WOOPSocial is zkSNARKHelper {
    using SafeMath for uint256;

    Unirep public unirep;
    IVerifier internal negativeReputationVerifier;
    IVerifier internal subsidyKeyVerifier;

    // Before WOOPSocial integrates with InterRep
    // We use an admin to controll user sign up
    address internal admin;

    // WOOP social's attester ID
    uint256 immutable public attesterId;

    // The amount of karma required to publish a post
    uint256 immutable public postReputation;

    // The amount of karma required to submit a comment
    uint256 immutable public commentReputation;

    // The amount of karma airdropped to user when user signs up and executes user state transition
    uint256 immutable public airdroppedReputation;

    // A mapping between user’s epoch key and if they request airdrop in the current epoch;
    // One epoch key is allowed to get airdrop once an epoch
    mapping(uint256 => bool) public isEpochKeyGotAirdrop;

    // A mapping between username and if they're already claimed;
    mapping(uint256 => bool) public usernames;
    // epoch number to epoch key to amount spent
    mapping(uint256 => mapping(uint256 => uint256)) public subsidies;
    // proof nullifier
    mapping(bytes32 => bool) public usedProofNullifier;

    uint256 immutable public subsidy;

    // assign posts/comments with an id
    uint256 public contentId = 1;

    // post/comment id => hashed content => epoch key
    mapping(uint256 => mapping(bytes32 => uint256)) public hashedContentMapping;

    // help WOOP Social track event
    event UserSignedUp(
        uint256 indexed _epoch,
        uint256 indexed _identityCommitment
    );

    event AirdropSubmitted(
        uint256 indexed _epoch,
        uint256 indexed _epochKey
    );

    event PostSubmitted(
        uint256 indexed _epoch,
        uint256 indexed _postId,
        uint256 indexed _epochKey,
        bytes32 _contentHash,
        uint256 minRep
    );

    event CommentSubmitted(
        uint256 indexed _epoch,
        uint256 indexed _postId,
        uint256 indexed _epochKey,
        uint256 _commentId,
        bytes32 _contentHash,
        uint256 minRep
    );

    event ContentUpdated(
        uint256 indexed _id,
        bytes32 _oldContentHash,
        bytes32 _newContentHash
    );

    event VoteSubmitted(
        uint256 indexed _epoch,
        uint256 indexed _fromEpochKey,
        uint256 indexed _toEpochKey,
        uint256 upvoteValue,
        uint256 downvoteValue,
        uint256 minRep
    );


    constructor(
        Unirep _unirepContract,
        IVerifier _negativeReputationVerifier,
        IVerifier _subsidyKeyVerifier,
        uint256 _postReputation,
        uint256 _commentReputation,
        uint256 _airdroppedReputation,
        uint256 _subsidy
    ) {
        // Set the woop contracts
        unirep = _unirepContract;
        negativeReputationVerifier = _negativeReputationVerifier;
        subsidyKeyVerifier = _subsidyKeyVerifier;
        // Set admin user
        admin = msg.sender;

        // signup WOOP Social contract as an attester in WOOP contract
        unirep.attesterSignUp();
        attesterId = unirep.attesters(address(this));

        postReputation = _postReputation;
        commentReputation = _commentReputation;
        airdroppedReputation = _airdroppedReputation;
        subsidy = _subsidy;
    }

    /*
     * Call WOOP contract to perform user signing up if user hasn't signed up in WOOP
     * @param _identityCommitment Commitment of the user's identity which is a semaphore identity.
     */
    function userSignUp(uint256 _identityCommitment) external {
        require(msg.sender == admin, "WOOP Social: sign up should through an admin");
        unirep.userSignUp(_identityCommitment, airdroppedReputation);

        emit UserSignedUp(
            unirep.currentEpoch(),
            _identityCommitment
        );
    }

    /*
     * Try to spend subsidy for an epoch key in an epoch
     * @param epoch The epoch the subsidy belongs to
     * @param epochKey The epoch key that receives the subsidy
     * @param amount The amount requesting to be spent
     */
    function trySpendSubsidy(
      uint256 epoch,
      uint256 subsidyKey,
      uint256 amount
    ) private {
        uint256 spentSubsidy = subsidies[epoch][subsidyKey];
        assert(spentSubsidy <= subsidy);
        uint256 remainingSubsidy = subsidy - spentSubsidy;
        require(amount <= remainingSubsidy, 'WOOP Social: requesting too much subsidy');
        require(epoch == unirep.currentEpoch(), 'WOOP Social: wrong epoch');
        subsidies[epoch][subsidyKey] += amount;
    }

    function verifyNegativeRepProof(uint256[5] memory publicSignals, uint256[8] memory proof) internal view returns (bool) {
        return negativeReputationVerifier.verifyProof(
            [proof[0], proof[1]],
            [[proof[2], proof[3]], [proof[4], proof[5]]],
            [proof[6], proof[7]],
            publicSignals
        );
    }

    function verifySubsidyKeyProof(uint256[6] memory publicSignals, uint256[8] memory proof) internal view returns (bool) {
        return subsidyKeyVerifier.verifyProof(
            [proof[0], proof[1]],
            [[proof[2], proof[3]], [proof[4], proof[5]]],
            [proof[6], proof[7]],
            publicSignals
        );
    }

    /**
     * Accepts a negative reputation proof
     * publicSignals[0] - GST root
     * publicSignals[1] - epoch key
     * publicSignals[2] - epoch
     * publicSignals[3] - attester id
     * publicSignals[4] - maxRep
     **/
    function getSubsidyAirdrop(
      uint256[5] memory publicSignals,
      uint256[8] memory proof
    ) public payable {
        (,,,,,,,uint attestingFee,,) = unirep.config();
        // check if proof is submitted before
        bytes32 proofNullifier = keccak256(
            abi.encodePacked(publicSignals, proof)
        );
        require(!usedProofNullifier[proofNullifier], "WOOP Social: the proof is submitted before");
        usedProofNullifier[proofNullifier] = true;

        require(publicSignals[3] == attesterId, "WOOP Social: submit a proof with different attester ID from WOOP Social");

        // verify the proof
        require(verifyNegativeRepProof(publicSignals, proof));

        // update the stored subsidy balances
        uint requestedSubsidy = publicSignals[4]; // the amount proved
        uint receivedSubsidy = subsidy < requestedSubsidy ? subsidy : requestedSubsidy;
        uint epoch = publicSignals[2];
        trySpendSubsidy(epoch, publicSignals[1], receivedSubsidy);
        subsidies[epoch][publicSignals[1]] = subsidy; // don't allow a user to double request or spend more
        require(unirep.globalStateTreeRoots(epoch, publicSignals[0]), "WOOP Social: GST root does not exist in epoch");

        // Submit attestation to receiver's first epoch key
        Unirep.Attestation memory attestation;
        attestation.attesterId = attesterId;
        attestation.posRep = receivedSubsidy;
        attestation.negRep = 0;
        unirep.submitAttestation{value: attestingFee}(
            attestation,
            publicSignals[1] // first epoch key
        );
    }

    /**
     * Accepts a prove subsidy key proof
     * publicSignals[0] - GST root
     * publicSignals[1] - epoch key
     * publicSignals[2] - epoch
     * publicSignals[3] - attester id
     * publicSignals[4] - min rep
     * publicSignals[5] - not epoch key
     **/
    function publishPostSubsidy(
        bytes32 contentHash,
        uint256[6] memory publicSignals,
        uint256[8] memory proof
    ) external payable {
        // check if proof is submitted before
        bytes32 proofNullifier = keccak256(
            abi.encodePacked(publicSignals, proof)
        );
        require(!usedProofNullifier[proofNullifier], "WOOP Social: the proof is submitted before");
        usedProofNullifier[proofNullifier] = true;
        require(publicSignals[3] == attesterId, "WOOP Social: submit a proof with different attester ID from WOOP Social");
        uint256 epoch = publicSignals[2];
        uint256 epochKey = publicSignals[1];
        require(verifySubsidyKeyProof(publicSignals, proof));
        trySpendSubsidy(epoch, publicSignals[1], postReputation);
        require(unirep.globalStateTreeRoots(epoch, publicSignals[0]), "WOOP Social: GST root does not exist in epoch");

        // saved post id and hashed content
        uint256 postId = contentId;
        hashedContentMapping[postId][contentHash] = epochKey;

        emit PostSubmitted(
            epoch,
            postId,
            epochKey,
            contentHash,
            publicSignals[4] // min rep
        );

        // update content Id
        contentId ++;
    }

    function publishCommentSubsidy(
        uint256 postId,
        bytes32 contentHash,
        uint256[6] memory publicSignals,
        uint256[8] memory proof
    ) external payable {
        // check if proof is submitted before
        bytes32 proofNullifier = keccak256(
            abi.encodePacked(publicSignals, proof)
        );
        require(!usedProofNullifier[proofNullifier], "WOOP Social: the proof is submitted before");
        usedProofNullifier[proofNullifier] = true;
        require(publicSignals[3] == attesterId, "WOOP Social: submit a proof with different attester ID from WOOP Social");
        uint256 epoch = publicSignals[2];
        uint256 epochKey = publicSignals[1];
        require(verifySubsidyKeyProof(publicSignals, proof));
        trySpendSubsidy(epoch, publicSignals[1], commentReputation);
        require(unirep.globalStateTreeRoots(epoch, publicSignals[0]), "WOOP Social: GST root does not exist in epoch");

        // saved post id and hashed content
        uint256 commentId = contentId;
        hashedContentMapping[commentId][contentHash] = epochKey;

        emit CommentSubmitted(
            epoch,
            postId,
            epochKey,
            commentId,
            contentHash,
            publicSignals[4] // min rep
        );

         // update content Id
        contentId ++;
    }

    function voteSubsidy(
        uint256 upvoteValue,
        uint256 downvoteValue,
        uint256 toEpochKey,
        uint256[6] memory publicSignals,
        uint256[8] memory proof
    ) external payable {
        uint attestingFee = unirep.attestingFee();
        // check if proof is submitted before
        bytes32 proofNullifier = keccak256(
            abi.encodePacked(publicSignals, proof)
        );
        require(!usedProofNullifier[proofNullifier], "WOOP Social: the proof is submitted before");
        usedProofNullifier[proofNullifier] = true;
        require(publicSignals[3] == attesterId, "WOOP Social: submit a proof with different attester ID from WOOP Social");
        require(verifySubsidyKeyProof(publicSignals, proof));
        uint256 voteValue = upvoteValue + downvoteValue;
        require(voteValue > 0, "WOOP Social: should submit a positive vote value");
        require(upvoteValue * downvoteValue == 0, "WOOP Social: should only choose to upvote or to downvote");

        uint256 epoch = publicSignals[2];
        trySpendSubsidy(epoch, publicSignals[1], voteValue);
        require(unirep.globalStateTreeRoots(epoch, publicSignals[0]), "WOOP Social: GST root does not exist in epoch");
        require(publicSignals[5] == toEpochKey, "WOOP Social: must prove non-ownership of epk");

        // Submit attestation to receiver's epoch key
        Unirep.Attestation memory attestation;
        attestation.attesterId = attesterId;
        attestation.posRep = upvoteValue;
        attestation.negRep = downvoteValue;
        unirep.submitAttestation{value: attestingFee}(
            attestation,
            toEpochKey
        );

        emit VoteSubmitted(
            epoch,
            publicSignals[1], // from epoch key
            toEpochKey,
            upvoteValue,
            downvoteValue,
            publicSignals[4] // min rep
        );
    }

    /*
     * Publish a post on chain with a reputation proof to prove that the user has enough karma to spend
     * @param contentHash The hashed content of the post
     * @param _proofRelated The reputation proof that the user proves that he has enough karma to post
     */
    function publishPost(
        bytes32 contentHash,
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) external payable {
        (,,,,uint maxReputationBudget,,,uint attestingFee,,) = unirep.config();
        uint256 epochKey = publicSignals[0];
        // check if proof is submitted before
        bytes32 proofNullifier = keccak256(
            abi.encodePacked(publicSignals, proof)
        );
        require(!usedProofNullifier[proofNullifier], "WOOP Social: the proof is submitted before");
        usedProofNullifier[proofNullifier] = true;
        require(publicSignals[maxReputationBudget + 3] == attesterId, "WOOP Social: submit a proof with different attester ID from WOOP Social");

        uint256 epoch = publicSignals[maxReputationBudget + 2];
        uint256 proofSpendAmount = publicSignals[maxReputationBudget + 4];
        require(proofSpendAmount == postReputation, "WOOP Social: submit different nullifiers amount from the required amount for post");

        // Spend reputation
        unirep.spendReputation{value: attestingFee}(publicSignals, proof);

        // saved post id and hashed content
        uint256 postId = contentId;
        hashedContentMapping[postId][contentHash] = epochKey;

        emit PostSubmitted(
            epoch,
            postId,
            epochKey,
            contentHash,
            publicSignals[maxReputationBudget + 5] // min rep
        );

        // update content Id
        contentId ++;
    }

    /*
     * Leave a comment on chain with a reputation proof to prove that the user has enough karma to spend
     * @param postId The transaction hash of the post
     * @param contentHash The hashed content of the post
     * @param _proofRelated The reputation proof that the user proves that he has enough karma to comment
     */
    function leaveComment(
        uint256 postId,
        bytes32 contentHash,
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) external payable {
        (,,,,uint maxReputationBudget,,,uint attestingFee,,) = unirep.config();
        uint256 epochKey = publicSignals[0];
        require(publicSignals[maxReputationBudget + 4] == commentReputation, "WOOP Social: submit different nullifiers amount from the required amount for comment");
        // check if proof is submitted before
        bytes32 proofNullifier = keccak256(
            abi.encodePacked(publicSignals, proof)
        );
        require(!usedProofNullifier[proofNullifier], "WOOP Social: the proof is submitted before");
        usedProofNullifier[proofNullifier] = true;
        require(publicSignals[maxReputationBudget + 3] == attesterId, "WOOP Social: submit a proof with different attester ID from WOOP Social");
        require(postId < contentId, "WOOP Social: the post id is not valid");

        uint256 epoch = publicSignals[maxReputationBudget + 2];
        uint256 proofSpendAmount = publicSignals[maxReputationBudget + 4];
        require(proofSpendAmount == commentReputation, "WOOP Social: submit different nullifiers amount from the required amount for comment");

        // Spend reputation
        unirep.spendReputation{value: attestingFee}(publicSignals, proof);

        // saved post id and hashed content
        uint256 commentId = contentId;
        hashedContentMapping[commentId][contentHash] = epochKey;

        emit CommentSubmitted(
            epoch,
            postId,
            epochKey,
            commentId,
            contentHash,
            publicSignals[maxReputationBudget + 5] // min rep
        );

        // update comment Id
        contentId ++;
    }

    /*
     * Update a published post/comment content
     * @param id The post ID or the comment ID
     * @param oldContentHash The old hashed content of the post/comment
     * @param newContentHash The new hashed content of the post/comment
     * @param publicSignals The public signals of the epoch key proof of the author of the post/comment
     * @param proof The epoch key proof of the author of the post/comment
     */
    function edit(
        uint256 id,
        bytes32 oldContentHash,
        bytes32 newContentHash,
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) external payable {
        uint256 epochKey = publicSignals[0];
        require(unirep.verifyEpochKeyValidity(publicSignals, proof), "WOOP Social: The epoch key proof is invalid");
        require(unirep.globalStateTreeRoots(publicSignals[2], publicSignals[1]) == true, "WOOP Social: Invalid global state tree root");
        require(hashedContentMapping[id][oldContentHash] == epochKey, "WOOP Social: Mismatched epoch key proof to the post or the comment id");

        hashedContentMapping[id][oldContentHash] = 0;
        hashedContentMapping[id][newContentHash] = epochKey;

        emit ContentUpdated(id, oldContentHash, newContentHash);
    }

    /*
     * Vote an epoch key with a reputation proof to prove that the user has enough karma to spend
     * @param upvoteValue How much the user wants to upvote the epoch key receiver
     * @param downvoteValue How much the user wants to downvote the epoch key receiver
     * @param toEpochKey The vote receiver
     * @param toEPochKeyProofIndex the proof index of the epoch key on woop
     * @param _proofRelated The reputation proof that the user proves that he has enough karma to vote
     */
    function vote(
        uint256 upvoteValue,
        uint256 downvoteValue,
        uint256 toEpochKey,
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) external payable {
        (,,,,uint maxReputationBudget,,,uint attestingFee,,) = unirep.config();
        uint256 voteValue = upvoteValue + downvoteValue;
        // check if proof is submitted before
        bytes32 proofNullifier = keccak256(
            abi.encodePacked(publicSignals, proof)
        );
        require(!usedProofNullifier[proofNullifier], "WOOP Social: the proof is submitted before");
        usedProofNullifier[proofNullifier] = true;
        require(voteValue > 0, "WOOP Social: should submit a positive vote value");
        require(upvoteValue * downvoteValue == 0, "WOOP Social: should only choose to upvote or to downvote");
        require(publicSignals[maxReputationBudget + 3] == attesterId, "WOOP Social: submit a proof with different attester ID from WOOP Social");
        uint256 proofSpendAmount = publicSignals[maxReputationBudget + 4];
        require(proofSpendAmount == voteValue, "WOOP Social: submit different nullifiers amount from the vote value");

        // Spend reputation
        unirep.spendReputation{value: attestingFee}(publicSignals, proof);

        // Submit attestation to receiver's epoch key
        Unirep.Attestation memory attestation;
        attestation.attesterId = attesterId;
        attestation.posRep = upvoteValue;
        attestation.negRep = downvoteValue;
        unirep.submitAttestation{value: attestingFee}(
            attestation,
            toEpochKey
        );

        emit VoteSubmitted(
            unirep.currentEpoch(),
            publicSignals[0], // from epoch key
            toEpochKey,
            upvoteValue,
            downvoteValue,
            publicSignals[maxReputationBudget + 5] // min rep
        );
    }

    /*
     * Call WOOP contract to perform start user state transition
     * @param _blindedUserState Blind user state tree before user state transition
     * @param _blindedHashChain Blind hash chain before user state transition
     * @param _GSTRoot User proves that he has already signed up in the global state tree
     * @param _proof The snark proof
     */
    function startUserStateTransition(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) external {
        unirep.startUserStateTransition(publicSignals, proof);
    }

    /*
     * Call WOOP contract to perform user state transition
     * @param _outputBlindedUserState Blind intermediate user state tree before user state transition
     * @param _outputBlindedHashChain Blind intermediate hash chain before user state transition
     * @param _inputBlindedUserState Input a submitted blinded user state before process the proof
     * @param _proof The snark proof
     */
    function processAttestations(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) external {
        unirep.processAttestations(publicSignals, proof);
    }

    /*
     * Call WOOP contract to perform user state transition
     * @param userTransitionedData The public signals and proof of the user state transition
     * @param proofIndexes The proof indexes of start user state transition and process attestations
     */
    function updateUserStateRoot(
        uint256[] memory publicSignals,
        uint256[8] memory proof
    ) external {
        unirep.updateUserStateRoot(publicSignals, proof);
    }

     /*
     * Set new user name for an epochKey
     * @param epochKey epoch key that attempts to set a new uername
     * @param oldUsername oldusername that the eppch key previously claimed
     * @param newUsername requested new user name
     */
     function setUsername(
        uint256 epochKey,
        uint256 oldUsername,
        uint256 newUsername
     ) external payable {
        uint attestingFee = unirep.attestingFee();

        // check if the new username is not taken
        require(usernames[newUsername] == false, "This username is already taken");

        // only admin can call this function
        require(msg.sender == admin, "Only admin can send transactions to this contract");

        usernames[oldUsername] = false;
        usernames[newUsername] = true;

        // attest to the epoch key to give the key the username
        Unirep.Attestation memory attestation;
        attestation.attesterId = attesterId;
        attestation.posRep = 0;
        attestation.negRep = 0;
        attestation.graffiti = newUsername;

        unirep.submitAttestation{value: attestingFee}(
            attestation,
            epochKey
        );
     }
}