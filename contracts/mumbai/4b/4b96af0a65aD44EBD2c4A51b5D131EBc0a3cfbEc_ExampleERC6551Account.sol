// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libs/utils/Structs.sol";

interface ISismoConnectVerifier {
  event VerifierSet(bytes32, address);

  error AppIdMismatch(bytes16 receivedAppId, bytes16 expectedAppId);
  error NamespaceMismatch(bytes16 receivedNamespace, bytes16 expectedNamespace);
  error VersionMismatch(bytes32 requestVersion, bytes32 responseVersion);
  error SignatureMessageMismatch(bytes requestMessageSignature, bytes responseMessageSignature);

  function verify(
    SismoConnectResponse memory response,
    SismoConnectRequest memory request,
    SismoConnectConfig memory config
  ) external returns (SismoConnectVerifiedResult memory);

  function SISMO_CONNECT_VERSION() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {RequestBuilder, SismoConnectRequest, SismoConnectResponse, SismoConnectConfig} from "../utils/RequestBuilder.sol";
import {AuthRequestBuilder, AuthRequest, Auth, VerifiedAuth, AuthType} from "../utils/AuthRequestBuilder.sol";
import {ClaimRequestBuilder, ClaimRequest, Claim, VerifiedClaim, ClaimType} from "../utils/ClaimRequestBuilder.sol";
import {SignatureBuilder, SignatureRequest, Signature} from "../utils/SignatureBuilder.sol";
import {VaultConfig} from "../utils/Structs.sol";
import {ISismoConnectVerifier, SismoConnectVerifiedResult} from "../../interfaces/ISismoConnectVerifier.sol";
import {IAddressesProvider} from "../../periphery/interfaces/IAddressesProvider.sol";
import {SismoConnectHelper} from "../utils/SismoConnectHelper.sol";
import {IHydraS3Verifier} from "../../verifiers/IHydraS3Verifier.sol";

contract SismoConnect {
  uint256 public constant SISMO_CONNECT_LIB_VERSION = 2;

  IAddressesProvider public constant ADDRESSES_PROVIDER_V2 =
    IAddressesProvider(0x3Cd5334eB64ebBd4003b72022CC25465f1BFcEe6);

  ISismoConnectVerifier immutable _sismoConnectVerifier;

  // external libraries
  AuthRequestBuilder immutable _authRequestBuilder;
  ClaimRequestBuilder immutable _claimRequestBuilder;
  SignatureBuilder immutable _signatureBuilder;
  RequestBuilder immutable _requestBuilder;

  // config
  bytes16 public immutable APP_ID;
  bool public immutable IS_IMPERSONATION_MODE;

  constructor(SismoConnectConfig memory _config) {
    APP_ID = _config.appId;
    IS_IMPERSONATION_MODE = _config.vault.isImpersonationMode;

    _sismoConnectVerifier = ISismoConnectVerifier(
      ADDRESSES_PROVIDER_V2.get(string("sismoConnectVerifier-v1.2"))
    );
    // external libraries
    _authRequestBuilder = AuthRequestBuilder(
      ADDRESSES_PROVIDER_V2.get(string("authRequestBuilder-v1.1"))
    );
    _claimRequestBuilder = ClaimRequestBuilder(
      ADDRESSES_PROVIDER_V2.get(string("claimRequestBuilder-v1.1"))
    );
    _signatureBuilder = SignatureBuilder(
      ADDRESSES_PROVIDER_V2.get(string("signatureBuilder-v1.1"))
    );
    _requestBuilder = RequestBuilder(ADDRESSES_PROVIDER_V2.get(string("requestBuilder-v1.1")));
  }

  // public function because it needs to be used by this contract and can be used by other contracts
  function config() public view returns (SismoConnectConfig memory) {
    return buildConfig(APP_ID, IS_IMPERSONATION_MODE);
  }

  function buildConfig(bytes16 appId) internal pure returns (SismoConnectConfig memory) {
    return SismoConnectConfig({appId: appId, vault: buildVaultConfig()});
  }

  function buildConfig(
    bytes16 appId,
    bool isImpersonationMode
  ) internal pure returns (SismoConnectConfig memory) {
    return SismoConnectConfig({appId: appId, vault: buildVaultConfig(isImpersonationMode)});
  }

  function buildVaultConfig() internal pure returns (VaultConfig memory) {
    return VaultConfig({isImpersonationMode: false});
  }

  function buildVaultConfig(bool isImpersonationMode) internal pure returns (VaultConfig memory) {
    return VaultConfig({isImpersonationMode: isImpersonationMode});
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim, signature);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    ClaimRequest memory claim
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, claim);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth, signature);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim, signature);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest memory auth
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auth);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest memory claim
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claim);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    SismoConnectRequest memory request
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims, signature, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims, namespace);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims, signature);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, claims);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths, signature);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims, signature);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    AuthRequest[] memory auths
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(auths);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function verify(
    bytes memory responseBytes,
    ClaimRequest[] memory claims
  ) internal returns (SismoConnectVerifiedResult memory) {
    SismoConnectResponse memory response = abi.decode(responseBytes, (SismoConnectResponse));
    SismoConnectRequest memory request = buildRequest(claims);
    return _sismoConnectVerifier.verify(response, request, config());
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value, claimType, extraData);
  }

  function buildClaim(bytes16 groupId) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp);
  }

  function buildClaim(bytes16 groupId, uint256 value) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value);
  }

  function buildClaim(
    bytes16 groupId,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, claimType, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value, claimType);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, value, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, claimType, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType,
    bytes memory extraData
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, claimType, extraData);
  }

  function buildClaim(
    bytes16 groupId,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, groupTimestamp, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, claimType, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return
      _claimRequestBuilder.build(groupId, groupTimestamp, value, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return
      _claimRequestBuilder.build(
        groupId,
        groupTimestamp,
        claimType,
        isOptional,
        isSelectableByUser
      );
  }

  function buildClaim(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return _claimRequestBuilder.build(groupId, value, claimType, isOptional, isSelectableByUser);
  }

  function buildClaim(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (ClaimRequest memory) {
    return
      _claimRequestBuilder.build(
        groupId,
        groupTimestamp,
        value,
        claimType,
        isOptional,
        isSelectableByUser
      );
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, userId, extraData);
  }

  function buildAuth(AuthType authType) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType);
  }

  function buildAuth(AuthType authType, bool isAnon) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon);
  }

  function buildAuth(AuthType authType, uint256 userId) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, userId);
  }

  function buildAuth(
    AuthType authType,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, extraData);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    uint256 userId
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, userId);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, extraData);
  }

  function buildAuth(
    AuthType authType,
    uint256 userId,
    bytes memory extraData
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, userId, extraData);
  }

  function buildAuth(
    AuthType authType,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isOptional, isSelectableByUser);
  }

  function buildAuth(
    AuthType authType,
    bool isOptional,
    bool isSelectableByUser,
    uint256 userId
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isOptional, isSelectableByUser, userId);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    bool isOptional,
    bool isSelectableByUser
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, isOptional, isSelectableByUser);
  }

  function buildAuth(
    AuthType authType,
    uint256 userId,
    bool isOptional
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, userId, isOptional);
  }

  function buildAuth(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional
  ) internal view returns (AuthRequest memory) {
    return _authRequestBuilder.build(authType, isAnon, userId, isOptional);
  }

  function buildSignature(bytes memory message) internal view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message);
  }

  function buildSignature(
    bytes memory message,
    bool isSelectableByUser
  ) internal view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message, isSelectableByUser);
  }

  function buildSignature(
    bytes memory message,
    bytes memory extraData
  ) internal view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message, extraData);
  }

  function buildSignature(
    bytes memory message,
    bool isSelectableByUser,
    bytes memory extraData
  ) internal view returns (SignatureRequest memory) {
    return _signatureBuilder.build(message, isSelectableByUser, extraData);
  }

  function buildSignature(bool isSelectableByUser) internal view returns (SignatureRequest memory) {
    return _signatureBuilder.build(isSelectableByUser);
  }

  function buildSignature(
    bool isSelectableByUser,
    bytes memory extraData
  ) internal view returns (SignatureRequest memory) {
    return _signatureBuilder.build(isSelectableByUser, extraData);
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, signature);
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, signature);
  }

  function buildRequest(
    AuthRequest memory auth,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, signature);
  }

  function buildRequest(
    ClaimRequest memory claim
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    AuthRequest memory auth
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, signature, namespace);
  }

  function buildRequest(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, claim, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, signature, namespace);
  }

  function buildRequest(
    AuthRequest memory auth,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, signature, namespace);
  }

  function buildRequest(
    ClaimRequest memory claim,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claim, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    AuthRequest memory auth,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auth, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, signature);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, signature);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    SignatureRequest memory signature
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, signature);
  }

  function buildRequest(
    ClaimRequest[] memory claims
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    AuthRequest[] memory auths
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, _GET_EMPTY_SIGNATURE_REQUEST());
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, signature, namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, claims, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, signature, namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    SignatureRequest memory signature,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, signature, namespace);
  }

  function buildRequest(
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(claims, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function buildRequest(
    AuthRequest[] memory auths,
    bytes16 namespace
  ) internal view returns (SismoConnectRequest memory) {
    return _requestBuilder.build(auths, _GET_EMPTY_SIGNATURE_REQUEST(), namespace);
  }

  function _GET_EMPTY_SIGNATURE_REQUEST() internal view returns (SignatureRequest memory) {
    return _signatureBuilder.buildEmpty();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title SismoLib
 * @author Sismo
 * @notice This is the Sismo Library of the Sismo protocol
 * It is designed to be the only contract that needs to be imported to integrate Sismo in a smart contract.
 * Its aim is to provide a set of sub-libraries with high-level functions to interact with the Sismo protocol easily.
 */

import "./sismo-connect/SismoConnectLib.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

contract AuthRequestBuilder {
  // default values for Auth Request
  bool public constant DEFAULT_AUTH_REQUEST_IS_ANON = false;
  uint256 public constant DEFAULT_AUTH_REQUEST_USER_ID = 0;
  bool public constant DEFAULT_AUTH_REQUEST_IS_OPTIONAL = false;
  bytes public constant DEFAULT_AUTH_REQUEST_EXTRA_DATA = "";

  error InvalidUserIdAndIsSelectableByUserAuthType();
  error InvalidUserIdAndAuthType();

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional,
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  function build(AuthType authType) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(AuthType authType, bool isAnon) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(AuthType authType, uint256 userId) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  function build(
    AuthType authType,
    uint256 userId,
    bytes memory extraData
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: DEFAULT_AUTH_REQUEST_IS_OPTIONAL,
        extraData: extraData
      });
  }

  // allow dev to choose for isOptional
  // the user is ask to choose isSelectableByUser to avoid the function signature collision
  // between build(AuthType authType, bool isOptional) and build(AuthType authType, bool isAnon)

  function build(
    AuthType authType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bool isOptional,
    bool isSelectableByUser,
    uint256 userId
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  // the user is ask to choose isSelectableByUser to avoid the function signature collision
  // between build(AuthType authType, bool isAnon, bool isOptional) and build(AuthType authType, bool isOptional, bool isSelectableByUser)

  function build(
    AuthType authType,
    bool isAnon,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: DEFAULT_AUTH_REQUEST_USER_ID,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    uint256 userId,
    bool isOptional
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: DEFAULT_AUTH_REQUEST_IS_ANON,
        userId: userId,
        isOptional: isOptional,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional
  ) external pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        extraData: DEFAULT_AUTH_REQUEST_EXTRA_DATA
      });
  }

  function _build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional,
    bytes memory extraData
  ) internal pure returns (AuthRequest memory) {
    return
      _build({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: _authIsSelectableDefaultValue(authType, userId),
        extraData: extraData
      });
  }

  function _build(
    AuthType authType,
    bool isAnon,
    uint256 userId,
    bool isOptional,
    bool isSelectableByUser,
    bytes memory extraData
  ) internal pure returns (AuthRequest memory) {
    // When `userId` is 0, it means the app does not require a specific auth account and the user needs
    // to choose the account they want to use for the app.
    // When `isSelectableByUser` is true, the user can select the account they want to use.
    // The combination of `userId = 0` and `isSelectableByUser = false` does not make sense and should not be used.
    // If this combination is detected, the function will revert with an error.
    if (authType != AuthType.VAULT && userId == 0 && isSelectableByUser == false) {
      revert InvalidUserIdAndIsSelectableByUserAuthType();
    }
    // When requesting an authType VAULT, the `userId` must be 0 and isSelectableByUser must be true.
    if (authType == AuthType.VAULT && userId != 0 && isSelectableByUser == false) {
      revert InvalidUserIdAndAuthType();
    }
    return
      AuthRequest({
        authType: authType,
        isAnon: isAnon,
        userId: userId,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function _authIsSelectableDefaultValue(
    AuthType authType,
    uint256 requestedUserId
  ) internal pure returns (bool) {
    // isSelectableByUser value should always be false in case of VAULT authType.
    // This is because the user can't select the account they want to use for the app.
    // the userId = Hash(VaultSecret, AppId) in the case of VAULT authType.
    if (authType == AuthType.VAULT) {
      return false;
    }
    // When `requestedUserId` is 0, it means no specific auth account is requested by the app,
    // so we want the default value for `isSelectableByUser` to be `true`.
    if (requestedUserId == 0) {
      return true;
    }
    // When `requestedUserId` is not 0, it means a specific auth account is requested by the app,
    // so we want the default value for `isSelectableByUser` to be `false`.
    else {
      return false;
    }
    // However, the dev can still override this default value by setting `isSelectableByUser` to `true`.
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

contract ClaimRequestBuilder {
  // default value for Claim Request
  bytes16 public constant DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP = bytes16("latest");
  uint256 public constant DEFAULT_CLAIM_REQUEST_VALUE = 1;
  ClaimType public constant DEFAULT_CLAIM_REQUEST_TYPE = ClaimType.GTE;
  bool public constant DEFAULT_CLAIM_REQUEST_IS_OPTIONAL = false;
  bool public constant DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER = true;
  bytes public constant DEFAULT_CLAIM_REQUEST_EXTRA_DATA = "";

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        claimType: claimType,
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        claimType: claimType,
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(bytes16 groupId) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(bytes16 groupId, uint256 value) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(bytes16 groupId, ClaimType claimType) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    ClaimType claimType,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType,
    bytes memory extraData
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: claimType,
        isOptional: DEFAULT_CLAIM_REQUEST_IS_OPTIONAL,
        isSelectableByUser: DEFAULT_CLAIM_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  // allow dev to choose for isOptional
  // we force to also set isSelectableByUser
  // otherwise function signatures would be colliding
  // between build(bytes16 groupId, bool isOptional) and build(bytes16 groupId, bool isSelectableByUser)
  // we keep this logic for all function signature combinations

  function build(
    bytes16 groupId,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: DEFAULT_CLAIM_REQUEST_TYPE,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: DEFAULT_CLAIM_REQUEST_VALUE,
        claimType: claimType,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: DEFAULT_CLAIM_REQUEST_GROUP_TIMESTAMP,
        value: value,
        claimType: claimType,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes16 groupId,
    bytes16 groupTimestamp,
    uint256 value,
    ClaimType claimType,
    bool isOptional,
    bool isSelectableByUser
  ) external pure returns (ClaimRequest memory) {
    return
      ClaimRequest({
        groupId: groupId,
        groupTimestamp: groupTimestamp,
        value: value,
        claimType: claimType,
        isOptional: isOptional,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_CLAIM_REQUEST_EXTRA_DATA
      });
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";
import {SignatureBuilder} from "./SignatureBuilder.sol";

contract RequestBuilder {
  // default value for namespace
  bytes16 public constant DEFAULT_NAMESPACE = bytes16(keccak256("main"));
  // default value for a signature request
  SignatureRequest DEFAULT_SIGNATURE_REQUEST =
    SignatureRequest({
      message: "MESSAGE_SELECTED_BY_USER",
      isSelectableByUser: false,
      extraData: ""
    });

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest memory claim,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    ClaimRequest memory claim,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest memory auth,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest memory auth,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest memory auth,
    ClaimRequest memory claim
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest memory auth,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(AuthRequest memory auth) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](1);
    auths[0] = auth;
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest memory claim,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(ClaimRequest memory claim) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    ClaimRequest[] memory claims = new ClaimRequest[](1);
    claims[0] = claim;
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  // build with arrays for auths and claims
  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    ClaimRequest[] memory claims,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    SignatureRequest memory signature,
    bytes16 namespace
  ) external pure returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    bytes16 namespace
  ) external view returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: namespace,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    ClaimRequest[] memory claims
  ) external view returns (SismoConnectRequest memory) {
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    AuthRequest[] memory auths,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(AuthRequest[] memory auths) external view returns (SismoConnectRequest memory) {
    ClaimRequest[] memory claims = new ClaimRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }

  function build(
    ClaimRequest[] memory claims,
    SignatureRequest memory signature
  ) external pure returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: signature
      })
    );
  }

  function build(ClaimRequest[] memory claims) external view returns (SismoConnectRequest memory) {
    AuthRequest[] memory auths = new AuthRequest[](0);
    return (
      SismoConnectRequest({
        namespace: DEFAULT_NAMESPACE,
        auths: auths,
        claims: claims,
        signature: DEFAULT_SIGNATURE_REQUEST
      })
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

contract SignatureBuilder {
  // default values for Signature Request
  bytes public constant DEFAULT_SIGNATURE_REQUEST_MESSAGE = "MESSAGE_SELECTED_BY_USER";
  bool public constant DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER = false;
  bytes public constant DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA = "";

  function build(bytes memory message) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes memory message,
    bool isSelectableByUser
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bytes memory message,
    bytes memory extraData
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: extraData
      });
  }

  function build(
    bytes memory message,
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: message,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function build(bool isSelectableByUser) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: DEFAULT_SIGNATURE_REQUEST_MESSAGE,
        isSelectableByUser: isSelectableByUser,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }

  function build(
    bool isSelectableByUser,
    bytes memory extraData
  ) external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: DEFAULT_SIGNATURE_REQUEST_MESSAGE,
        isSelectableByUser: isSelectableByUser,
        extraData: extraData
      });
  }

  function buildEmpty() external pure returns (SignatureRequest memory) {
    return
      SignatureRequest({
        message: DEFAULT_SIGNATURE_REQUEST_MESSAGE,
        isSelectableByUser: DEFAULT_SIGNATURE_REQUEST_IS_SELECTABLE_BY_USER,
        extraData: DEFAULT_SIGNATURE_REQUEST_EXTRA_DATA
      });
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Structs.sol";

library SismoConnectHelper {
  error AuthTypeNotFoundInVerifiedResult(AuthType authType);

  function getUserId(
    SismoConnectVerifiedResult memory result,
    AuthType authType
  ) internal pure returns (uint256) {
    // get the first userId that matches the authType
    for (uint256 i = 0; i < result.auths.length; i++) {
      if (result.auths[i].authType == authType) {
        return result.auths[i].userId;
      }
    }
    revert AuthTypeNotFoundInVerifiedResult(authType);
  }

  function getUserIds(
    SismoConnectVerifiedResult memory result,
    AuthType authType
  ) internal pure returns (uint256[] memory) {
    // get all userIds that match the authType
    uint256[] memory userIds = new uint256[](result.auths.length);
    for (uint256 i = 0; i < result.auths.length; i++) {
      if (result.auths[i].authType == authType) {
        userIds[i] = result.auths[i].userId;
      }
    }
    return userIds;
  }

  function getSignedMessage(
    SismoConnectVerifiedResult memory result
  ) internal pure returns (bytes memory) {
    return result.signedMessage;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct SismoConnectRequest {
  bytes16 namespace;
  AuthRequest[] auths;
  ClaimRequest[] claims;
  SignatureRequest signature;
}

struct SismoConnectConfig {
  bytes16 appId;
  VaultConfig vault;
}

struct VaultConfig {
  bool isImpersonationMode;
}

struct AuthRequest {
  AuthType authType;
  uint256 userId; // default: 0
  // flags
  bool isAnon; // default: false -> true not supported yet, need to throw if true
  bool isOptional; // default: false
  bool isSelectableByUser; // default: true
  //
  bytes extraData; // default: ""
}

struct ClaimRequest {
  ClaimType claimType; // default: GTE
  bytes16 groupId;
  bytes16 groupTimestamp; // default: bytes16("latest")
  uint256 value; // default: 1
  // flags
  bool isOptional; // default: false
  bool isSelectableByUser; // default: true
  //
  bytes extraData; // default: ""
}

struct SignatureRequest {
  bytes message; // default: "MESSAGE_SELECTED_BY_USER"
  bool isSelectableByUser; // default: false
  bytes extraData; // default: ""
}

enum AuthType {
  VAULT,
  GITHUB,
  TWITTER,
  EVM_ACCOUNT,
  TELEGRAM,
  DISCORD
}

enum ClaimType {
  GTE,
  GT,
  EQ,
  LT,
  LTE
}

struct Auth {
  AuthType authType;
  bool isAnon;
  bool isSelectableByUser;
  uint256 userId;
  bytes extraData;
}

struct Claim {
  ClaimType claimType;
  bytes16 groupId;
  bytes16 groupTimestamp;
  bool isSelectableByUser;
  uint256 value;
  bytes extraData;
}

struct Signature {
  bytes message;
  bytes extraData;
}

struct SismoConnectResponse {
  bytes16 appId;
  bytes16 namespace;
  bytes32 version;
  bytes signedMessage;
  SismoConnectProof[] proofs;
}

struct SismoConnectProof {
  Auth[] auths;
  Claim[] claims;
  bytes32 provingScheme;
  bytes proofData;
  bytes extraData;
}

struct SismoConnectVerifiedResult {
  bytes16 appId;
  bytes16 namespace;
  bytes32 version;
  VerifiedAuth[] auths;
  VerifiedClaim[] claims;
  bytes signedMessage;
}

struct VerifiedAuth {
  AuthType authType;
  bool isAnon;
  uint256 userId;
  bytes extraData;
  bytes proofData;
}

struct VerifiedClaim {
  ClaimType claimType;
  bytes16 groupId;
  bytes16 groupTimestamp;
  uint256 value;
  bytes extraData;
  uint256 proofId;
  bytes proofData;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAddressesProvider {
  /**
   * @dev Sets the address of a contract.
   * @param contractAddress Address of the contract.
   * @param contractName Name of the contract.
   */
  function set(address contractAddress, string memory contractName) external;

  /**
   * @dev Sets the address of multiple contracts.
   * @param contractAddresses Addresses of the contracts.
   * @param contractNames Names of the contracts.
   */
  function setBatch(address[] calldata contractAddresses, string[] calldata contractNames) external;

  /**
   * @dev Returns the address of a contract.
   * @param contractName Name of the contract (string).
   * @return Address of the contract.
   */
  function get(string memory contractName) external view returns (address);

  /**
   * @dev Returns the address of a contract.
   * @param contractNameHash Hash of the name of the contract (bytes32).
   * @return Address of the contract.
   */
  function get(bytes32 contractNameHash) external view returns (address);

  /**
   * @dev Returns the addresses of all contracts inputed.
   * @param contractNames Names of the contracts as strings.
   */
  function getBatch(string[] calldata contractNames) external view returns (address[] memory);

  /**
   * @dev Returns the addresses of all contracts inputed.
   * @param contractNamesHash Names of the contracts as strings.
   */
  function getBatch(bytes32[] calldata contractNamesHash) external view returns (address[] memory);

  /**
   * @dev Returns the addresses of all contracts in `_contractNames`
   * @return Names, Hashed Names and Addresses of all contracts.
   */
  function getAll() external view returns (string[] memory, bytes32[] memory, address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract IHydraS3Verifier {
  error InvalidProof();
  error CallToVerifyProofFailed();
  error InvalidSismoIdentifier(bytes32 userId, uint8 authType);
  error OnlyOneAuthAndOneClaimIsSupported();

  error InvalidVersion(bytes32 version);
  error RegistryRootNotAvailable(uint256 inputRoot);
  error DestinationMismatch(address destinationFromProof, address expectedDestination);
  error CommitmentMapperPubKeyMismatch(
    bytes32 expectedX,
    bytes32 expectedY,
    bytes32 inputX,
    bytes32 inputY
  );

  error ClaimTypeMismatch(uint256 claimTypeFromProof, uint256 expectedClaimType);
  error RequestIdentifierMismatch(
    uint256 requestIdentifierFromProof,
    uint256 expectedRequestIdentifier
  );
  error InvalidExtraData(uint256 extraDataFromProof, uint256 expectedExtraData);
  error ClaimValueMismatch();
  error DestinationVerificationNotEnabled();
  error SourceVerificationNotEnabled();
  error AccountsTreeValueMismatch(
    uint256 accountsTreeValueFromProof,
    uint256 expectedAccountsTreeValue
  );
  error VaultNamespaceMismatch(uint256 vaultNamespaceFromProof, uint256 expectedVaultNamespace);
  error UserIdMismatch(uint256 userIdFromProof, uint256 expectedUserId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Bytecode {
    error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

    /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
    function creationCodeFor(bytes memory _code)
        internal
        pure
        returns (bytes memory)
    {
        /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

        return
            abi.encodePacked(
                hex"63",
                uint32(_code.length),
                hex"80_60_0E_60_00_39_60_00_F3",
                _code
            );
    }

    /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
    function codeSize(address _addr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(_addr)
        }
    }

    /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
    function codeAt(
        address _addr,
        uint256 _start,
        uint256 _end
    ) internal view returns (bytes memory oCode) {
        uint256 csize = codeSize(_addr);
        if (csize == 0) return bytes("");

        if (_start > csize) return bytes("");
        if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end);

        unchecked {
            uint256 reqSize = _end - _start;
            uint256 maxSize = csize - _start;

            uint256 size = maxSize < reqSize ? maxSize : reqSize;

            assembly {
                // allocate output byte array - this could also be done without assembly
                // by using o_code = new bytes(size)
                oCode := mload(0x40)
                // new "memory end" including padding
                mstore(
                    0x40,
                    add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f)))
                )
                // store length in memory
                mstore(oCode, size)
                // actually retrieve the code, this needs assembly
                extcodecopy(_addr, add(oCode, 0x20), _start, size)
            }
        }
    }
}

pragma solidity ^0.8.13;

import "./IERC6551Account.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./Bytecode.sol";
import "@sismo-core/sismo-connect-solidity/contracts/libs/SismoLib.sol";

contract ExampleERC6551Account is
    IERC165,
    IERC1271,
    IERC6551Account,
    SismoConnect
{
    using SismoConnectHelper for SismoConnectVerifiedResult;
    uint256 private _nonce;

    receive() external payable {}

    // add your appId
    bytes16 private _appId = 0xb14aa2b855beee446a9685f4a38e612e;
    // use impersonated mode for testing
    bool private _isImpersonationMode = true;
    mapping(bytes16 => bool) public verifiedGroupIds;
    mapping(bytes16 => bool) public groupIdPreferences;

    event ZkProofsVerified(address currentAddress, bytes16[] newGroupIds);

    event zkPreferencesAdded(address currentAddress, bytes16[] newPreferences);

    function nonce() external view returns (uint256) {
        require(msg.sender == owner(), "Not token owner");
        return _nonce;
    }

    constructor() SismoConnect(buildConfig(_appId, _isImpersonationMode)) {}

    function _getClaimRequests(bytes16[] memory groupIds)
        internal
        view
        returns (ClaimRequest[] memory)
    {
        ClaimRequest[] memory requests = new ClaimRequest[](groupIds.length);
        for (uint i = 0; i < groupIds.length; i++) {
            requests[i] = buildClaim(groupIds[i]);
        }
        return requests;
    }

    function verifyzkProofs(bytes memory response, bytes16[] memory groupIds)
        public
    {
        SismoConnectVerifiedResult memory result = verify({
            responseBytes: response,
            claims: _getClaimRequests(groupIds),
            signature: buildSignature({message: abi.encode(msg.sender)})
        });
        bytes16[] memory _verifiedGroupIds = new bytes16[](
            result.claims.length
        );
        for (uint i = 0; i < result.claims.length; i++) {
            _verifiedGroupIds[i] = result.claims[i].groupId;
            verifiedGroupIds[result.claims[i].groupId] = true;
        }

        emit ZkProofsVerified(address(this), _verifiedGroupIds);
    }

    function verifyFakezkProofs(bytes16[] memory groupIds) public {
        bytes16[] memory _verifiedGroupIds = new bytes16[](groupIds.length);
        for (uint i = 0; i < groupIds.length; i++) {
            _verifiedGroupIds[i] = groupIds[i];
            verifiedGroupIds[groupIds[i]] = true;
        }

        emit ZkProofsVerified(address(this), _verifiedGroupIds);
    }

    function addzkPreferences(bytes16[] memory groupIds) public {
        for (uint i = 0; i < groupIds.length; i++) {
            groupIdPreferences[groupIds[i]] = true;
        }
        emit zkPreferencesAdded(address(this), groupIds);
    }

    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory result) {
        require(msg.sender == owner(), "Not token owner");

        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function token()
        external
        view
        returns (
            uint256 chainId,
            address tokenContract,
            uint256 tokenId
        )
    {
        uint256 length = address(this).code.length;
        return
            abi.decode(
                Bytecode.codeAt(address(this), length - 0x60, length),
                (uint256, address, uint256)
            );
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this
            .token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC6551Account).interfaceId);
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue)
    {
        bool isValid = SignatureChecker.isValidSignatureNow(
            owner(),
            hash,
            signature
        );

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }
}

/// @dev the ERC-165 identifier for this interface is `0x400a0398`
interface IERC6551Account {
    /// @dev Token bound accounts MUST implement a `receive` function.
    ///
    /// Token bound accounts MAY perform arbitrary logic to restrict conditions
    /// under which Ether can be received.
    receive() external payable;

    /// @dev Executes `call` on address `to`, with value `value` and calldata
    /// `data`.
    ///
    /// MUST revert and bubble up errors if call fails.
    ///
    /// By default, token bound accounts MUST allow the owner of the ERC-721 token
    /// which owns the account to execute arbitrary calls using `executeCall`.
    ///
    /// Token bound accounts MAY implement additional authorization mechanisms
    /// which limit the ability of the ERC-721 token holder to execute calls.
    ///
    /// Token bound accounts MAY implement additional execution functions which
    /// grant execution permissions to other non-owner accounts.
    ///
    /// @return The result of the call
    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory);

    /// @dev Returns identifier of the ERC-721 token which owns the
    /// account
    ///
    /// The return value of this function MUST be constant - it MUST NOT change
    /// over time.
    ///
    /// @return chainId The EIP-155 ID of the chain the ERC-721 token exists on
    /// @return tokenContract The contract address of the ERC-721 token
    /// @return tokenId The ID of the ERC-721 token
    function token()
        external
        view
        returns (
            uint256 chainId,
            address tokenContract,
            uint256 tokenId
        );

    /// @dev Returns the owner of the ERC-721 token which controls the account
    /// if the token exists.
    ///
    /// This is value is obtained by calling `ownerOf` on the ERC-721 contract.
    ///
    /// @return Address of the owner of the ERC-721 token which owns the account
    function owner() external view returns (address);

    /// @dev Returns a nonce value that is updated on every successful transaction
    ///
    /// @return The current account nonce
    function nonce() external view returns (uint256);
}