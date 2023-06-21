// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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

import "../../utils/introspection/IERC165Upgradeable.sol";

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

pragma solidity 0.8.18;

import '../../libraries/OspDataTypes.sol';
import '../../libraries/OspErrors.sol';

abstract contract EIP712Base {
    bytes32 internal constant EIP712_REVISION_HASH = keccak256('1');
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
        );

    /**
     * @dev Wrapper for ecrecover to reduce code size, used in meta-tx specific functions.
     */
    function _validateRecoveredAddress(
        bytes32 digest,
        address expectedAddress,
        OspDataTypes.EIP712Signature calldata sig
    ) internal view {
        if (sig.deadline < block.timestamp) revert OspErrors.SignatureExpired();
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        if (recoveredAddress == address(0) || recoveredAddress != expectedAddress)
            revert OspErrors.SignatureInvalid();
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator() internal view virtual returns (bytes32);

    /**
     * @dev Calculates EIP712 digest based on the current DOMAIN_SEPARATOR.
     *
     * @param hashedMessage The message hash from which the digest should be calculated.
     *
     * @return bytes32 A 32-byte output representing the EIP712 digest.
     */
    function _calculateDigest(bytes32 hashedMessage) internal view returns (bytes32) {
        bytes32 digest;
        unchecked {
            digest = keccak256(
                abi.encodePacked('\x19\x01', _calculateDomainSeparator(), hashedMessage)
            );
        }
        return digest;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import '../../libraries/OspDataTypes.sol';

interface IERC721Burnable {
    /**
     * @notice Burns an NFT, removing it from circulation and essentially destroying it. This function can only
     * be called by the NFT to burn's owner.
     *
     * @param tokenId The token ID of the token to burn.
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Implementation of an EIP-712 permit-style function for token burning. Allows anyone to burn
     * a token on behalf of the owner with a signature.
     *
     * @param tokenId The token ID of the token to burn.
     * @param sig The EIP712 signature struct.
     */
    function burnWithSig(uint256 tokenId, OspDataTypes.EIP712Signature calldata sig) external;

    function sigNonces(address addr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import '../../libraries/OspEvents.sol';
import '../../libraries/OspDataTypes.sol';
import '../../libraries/OspErrors.sol';

/**
 * @title OspMultiState
 *
 * @notice This is an abstract contract that implements internal OSP state setting and validation.
 *
 * whenNotPaused: Either publishingPaused or Unpaused.
 * whenPublishingEnabled: When Unpaused only.
 */
abstract contract OspMultiState {
    struct ProtocolStateStorage {
        OspDataTypes.ProtocolState state;
    }
    bytes32 internal constant STATE_STORAGE_POSITION = keccak256('osp.state.storage');

    function protocolStateStorage()
        internal
        pure
        returns (ProtocolStateStorage storage protocolState)
    {
        bytes32 position = STATE_STORAGE_POSITION;
        assembly {
            protocolState.slot := position
        }
    }

    modifier whenNotPaused() {
        _validateNotPaused();
        _;
    }

    modifier whenPublishingEnabled() {
        _validatePublishingEnabled();
        _;
    }

    /**
     * @notice Returns the current protocol state.
     *
     * @return ProtocolState The Protocol state, an enum, where:
     *      0: Unpaused
     *      1: PublishingPaused
     *      2: Paused
     */
    function _getState() internal view returns (OspDataTypes.ProtocolState) {
        return protocolStateStorage().state;
    }

    function _setState(OspDataTypes.ProtocolState newState) internal {
        OspDataTypes.ProtocolState prevState = protocolStateStorage().state;
        protocolStateStorage().state = newState;
        emit OspEvents.StateSet(msg.sender, prevState, newState, block.timestamp);
    }

    function _validatePublishingEnabled() internal view {
        if (protocolStateStorage().state != OspDataTypes.ProtocolState.Unpaused) {
            revert OspErrors.PublishingPaused();
        }
    }

    function _validateNotPaused() internal view {
        if (protocolStateStorage().state == OspDataTypes.ProtocolState.Paused) revert OspErrors.Paused();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import '../../../libraries/OspDataTypes.sol';
import '../../base/IERC721Burnable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol';

/**
 * @title IProfileLogic
 * @author OpenSocial Protocol
 *
 * @notice This is the interface for the ProfileLogic contract.
 */
interface IProfileLogic is IERC721Burnable, IERC721MetadataUpgradeable,IERC721EnumerableUpgradeable {
    /**
     * @notice Creates a profile with the specified parameters, minting a profile NFT to the sender.
     *
     * @param vars A CreateProfileData struct containing the following params:
     *      handle: The handle to set for the profile, must be unique and non-empty.
     *      followModule: The follow module to use, can be the zero address.
     *      followModuleInitData: The follow module initialization data, if any.
     */
    function createProfile(OspDataTypes.CreateProfileData calldata vars) external returns (uint256);

    /**
     * @notice Creates a profile with the specified parameters, minting a profile NFT to the given recipient.
     *
     * @param vars A CreateProfileWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function createProfileWithSig(
        OspDataTypes.CreateProfileWithSigData calldata vars
    ) external returns (uint256);

    /**
     * @notice Sets a profile's follow module, must be called by the profile owner.
     *
     * @param profileId The token ID of the profile to set the follow module for.
     * @param followModule The follow module to set for the given profile, must be whitelisted.
     * @param followModuleInitData The data to be passed to the follow module for initialization.
     */
    function setFollowModule(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData
    ) external;

    /**
     * @notice Sets a profile's follow module via signature with the specified parameters.
     *
     * @param vars A SetFollowModuleWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setFollowModuleWithSig(OspDataTypes.SetFollowModuleWithSigData calldata vars) external;

    /**
    /**
     * @notice Sets a profile's dispatcher, giving that dispatcher rights to publish to that profile.
     *
     * @param profileId The token ID of the profile of the profile to set the dispatcher for.
     * @param dispatcher The dispatcher address to set for the given profile ID.
     */
    function setDispatcher(uint256 profileId, address dispatcher) external;

    /**
     * @notice Sets a profile's dispatcher via signature with the specified parameters.
     *
     * @param vars A SetDispatcherWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setDispatcherWithSig(OspDataTypes.SetDispatcherWithSigData calldata vars) external;

    /// ************************
    /// *****VIEW FUNCTIONS*****
    /// ************************
    /**
     * @notice Returns the dispatcher associated with a profile.
     *
     * @param profileId The token ID of the profile to query the dispatcher for.
     *
     * @return address The dispatcher address associated with the profile.
     */
    function getDispatcher(uint256 profileId) external view returns (address);

    /**
     * @notice Returns the FollowSBT associated with a given profile, if any.
     *
     * @param profileId The token ID of the profile to query the FollowSBT for.
     *
     * @return address The FollowSBT associated with the given profile.
     */
    function getFollowSBT(uint256 profileId) external view returns (address);

    /**
     * @notice Returns the FollowSBT URI associated with a given profile.
     *
     * @param profileId The token ID of the profile to query the FollowSBT URI for.
     *
     * @return string The FollowSBT URI associated with the given profile.
     */
    function getFollowSBTURI(uint256 profileId) external view returns (string memory);

    /**
     * @notice Returns the follow module associated witha  given profile, if any.
     *
     * @param profileId The token ID of the profile to query the follow module for.
     *
     * @return address The address of the follow module associated with the given profile.
     */
    function getFollowModule(uint256 profileId) external view returns (address);

    /**
     * @notice Returns the handle associated with a profile.
     *
     * @param profileId The token ID of the profile to query the handle for.
     *
     * @return string The handle associated with the profile.
     */
    function getHandle(uint256 profileId) external view returns (string memory);

    /**
     * @notice Returns the profile token ID according to a given handle.
     *
     * @param handle The handle to resolve the profile token ID with.
     *
     * @return uint256 The profile ID the passed handle points to.
     */
    function getProfileIdByHandle(string calldata handle) external view returns (uint256);

    /**
     * @notice Returns the full profile struct associated with a given profile token ID.
     *
     * @param profileId The token ID of the profile to query.
     *
     * @return ProfileStruct The profile struct of the given profile.
     */
    function getProfile(
        uint256 profileId
    ) external view returns (OspDataTypes.ProfileStruct memory);

    /**
     * @notice Returns the profile ID according to a given address.
     *
     * @param addr The address to query the profile ID for.
     *
     * @return uint256 The profile ID the passed address points to.
     */
    function getProfileIdByAddress(address addr) external view returns (uint256);

    /**
     *@notice Returns the address nonce.

     * @param addr The address to query the profile ID for.
     */
    function sigNonces(address addr) external view returns (uint256);

    /**
     * @notice Returns the domain separator for the EIP712 standard.
     */
    function getDomainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import {OspStorage} from '../storage/OspStorage.sol';
import {OspErrors} from '../../libraries/OspErrors.sol';
import {OspEvents} from '../../libraries/OspEvents.sol';
import {OspMultiState} from '../base/OspMultiState.sol';
import '../../libraries/OspDataTypes.sol';
import '../base/EIP712Base.sol';
// import '../../interfaces/IOspNFTBase.sol';

contract OspLogicBase is OspMultiState, OspStorage, EIP712Base {
    /*///////////////////////////////////////////////////////////////
                            modifier
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev This modifier reverts if the caller is not the configured governance address.
     */
    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/
    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _getGovernanceStorage()._governance) revert OspErrors.NotGovernance();
    }

    function _validateCallerIsProfileOwnerOrDispatcher(uint256 profileId) internal view {
        if (
            msg.sender == _ownerOf(profileId) ||
            msg.sender == _getProfileStorage()._profileById[profileId].dispatcher
        ) {
            return;
        }
        revert OspErrors.NotProfileOwnerOrDispatcher();
    }

    function _validateCallerIsProfileOwner(uint256 profileId) internal view {
        if (msg.sender != _ownerOf(profileId)) revert OspErrors.NotProfileOwner();
    }

    function _validateHasProfile(address addr)internal view returns (uint256){
        uint256 profileId=_getProfileStorage()._profileIdByAddress[addr];
        if (profileId==0) revert OspErrors.NotHasProfile();
        return profileId;
    }

    /**
     * @dev Calculates EIP712 DOMAIN_SEPARATOR based on the current contract and chain ID.
     */
    function _calculateDomainSeparator() internal view virtual override returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(_getGovernanceStorage()._name)),
                    EIP712_REVISION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

    function _ownerOf(uint256 profileId) internal view returns (address) {
        return _getProfileStorage()._profileById[profileId].owner;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import './interfaces/IProfileLogic.sol';
import './OspLogicBase.sol';
import '../../libraries/Constants.sol';
import '../../interfaces/IFollowModule.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract ProfileLogic is IProfileLogic, OspLogicBase {
    using Strings for uint256;
    bytes32 internal constant SET_FOLLOW_MODULE_WITH_SIG_TYPEHASH =
        keccak256(
            'SetFollowModuleWithSig(uint256 profileId,address followModule,bytes followModuleInitData,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant SET_DISPATCHER_WITH_SIG_TYPEHASH =
        keccak256(
            'SetDispatcherWithSig(uint256 profileId,address dispatcher,uint256 nonce,uint256 deadline)'
        );
    bytes32 internal constant BURN_WITH_SIG_TYPEHASH =
        keccak256('BurnWithSig(uint256 profileId,uint256 nonce,uint256 deadline)');
    bytes32 internal constant CREATE_PROFILE_WITH_SIG_TYPEHASH =
        keccak256(
            'CreateProfileWithSig(address to,string handle,address followModule,bytes followModuleInitData,uint256 nonce,uint256 deadline)'
        );

    /*///////////////////////////////////////////////////////////////
                        Public functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IProfileLogic
    function createProfile(
        OspDataTypes.CreateProfileData calldata vars
    ) external override whenNotPaused returns (uint256) {
        return
            _createProfile(msg.sender, vars.handle, vars.followModule, vars.followModuleInitData);
    }

    /// @inheritdoc IProfileLogic
    function createProfileWithSig(
        OspDataTypes.CreateProfileWithSigData calldata vars
    ) external override whenNotPaused returns (uint256) {
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            CREATE_PROFILE_WITH_SIG_TYPEHASH,
                            vars.to,
                            keccak256(bytes(vars.handle)),
                            vars.followModule,
                            keccak256(vars.followModuleInitData),
                            _getProfileStorage()._sigNonces[vars.to]++,
                            vars.sig.deadline
                        )
                    )
                ),
                vars.to,
                vars.sig
            );
        }
        return _createProfile(vars.to, vars.handle, vars.followModule, vars.followModuleInitData);
    }

    /// @inheritdoc IProfileLogic
    function setFollowModule(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData
    ) external override whenNotPaused {
        _validateCallerIsProfileOwner(profileId);
        _setFollowModule(
            profileId,
            followModule,
            followModuleInitData,
            _getProfileStorage()._profileById[profileId]
        );
    }

    /// @inheritdoc IProfileLogic
    function setFollowModuleWithSig(
        OspDataTypes.SetFollowModuleWithSigData calldata vars
    ) external override whenNotPaused {
        ProfileStorage storage profileStorage = _getProfileStorage();
        address owner = ownerOf(vars.profileId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_FOLLOW_MODULE_WITH_SIG_TYPEHASH,
                            vars.profileId,
                            vars.followModule,
                            keccak256(vars.followModuleInitData),
                            profileStorage._sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    )
                ),
                owner,
                vars.sig
            );
        }
        _setFollowModule(
            vars.profileId,
            vars.followModule,
            vars.followModuleInitData,
            profileStorage._profileById[vars.profileId]
        );
    }

    /// @inheritdoc IProfileLogic
    function setDispatcher(uint256 profileId, address dispatcher) external override whenNotPaused {
        _validateCallerIsProfileOwner(profileId);
        _setDispatcher(profileId, dispatcher);
    }

    /// @inheritdoc IProfileLogic
    function setDispatcherWithSig(
        OspDataTypes.SetDispatcherWithSigData calldata vars
    ) external override whenNotPaused {
        address owner = ownerOf(vars.profileId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            SET_DISPATCHER_WITH_SIG_TYPEHASH,
                            vars.profileId,
                            vars.dispatcher,
                            _getProfileStorage()._sigNonces[owner]++,
                            vars.sig.deadline
                        )
                    )
                ),
                owner,
                vars.sig
            );
        }
        _setDispatcher(vars.profileId, vars.dispatcher);
    }

    function burn(uint256 profileId) external override whenNotPaused {
        _validateCallerIsProfileOwnerOrDispatcher(profileId);
        _burn(profileId);
    }

    function burnWithSig(
        uint256 profileId,
        OspDataTypes.EIP712Signature calldata sig
    ) external override {
        address owner = ownerOf(profileId);
        unchecked {
            _validateRecoveredAddress(
                _calculateDigest(
                    keccak256(
                        abi.encode(
                            BURN_WITH_SIG_TYPEHASH,
                            profileId,
                            _getProfileStorage()._sigNonces[owner]++,
                            sig.deadline
                        )
                    )
                ),
                owner,
                sig
            );
        }
        _burn(profileId);
    }

    /*///////////////////////////////////////////////////////////////
                        Public Read functions
    //////////////////////////////////////////////////////////////*/
    /// @inheritdoc IERC165Upgradeable
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            interfaceId == type(IERC721EnumerableUpgradeable).interfaceId ||
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId||
            interfaceId == type(IERC165Upgradeable).interfaceId ;
    }

    /// @inheritdoc IERC721Upgradeable
    function ownerOf(uint256 tokenId) public view override returns (address owner) {
        require(
            _getProfileStorage()._profileById[tokenId].owner != address(0),
            'ERC721: owner query for nonexistent token'
        );
        return _getProfileStorage()._profileById[tokenId].owner;
    }

    /// @inheritdoc IERC721MetadataUpgradeable
    function name() external view override returns (string memory) {
        return _getGovernanceStorage()._name;
    }

    /// @inheritdoc IERC721MetadataUpgradeable
    function symbol() external view override returns (string memory) {
        return _getGovernanceStorage()._symbol;
    }

    // @inheritdoc IERC721MetadataUpgradeable
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        string memory baseURI = _getGovernanceStorage()._baseURI;
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, 'profile/', tokenId.toString()))
                : tokenId.toString();
    }

    /// @inheritdoc IERC721Upgradeable
    function balanceOf(address owner) public view override returns (uint256 balance) {
        return _getProfileStorage()._profileIdByAddress[owner] != 0 ? 1 : 0;
    }

    /// @inheritdoc IERC721EnumerableUpgradeable
    function totalSupply() external view override returns (uint256) {
        return _getProfileStorage()._allTokens.length;
    }

    /// @inheritdoc IProfileLogic
    function getDomainSeparator() external view override returns (bytes32) {
        return _calculateDomainSeparator();
    }

    /// @inheritdoc IProfileLogic
    function getDispatcher(uint256 profileId) external view override returns (address) {
        return _getProfileStorage()._profileById[profileId].dispatcher;
    }

    /// @inheritdoc IProfileLogic
    function getFollowSBT(uint256 profileId) external view override returns (address) {
        return _getProfileStorage()._profileById[profileId].FollowSBT;
    }

    /// @inheritdoc IProfileLogic
    function getFollowSBTURI(uint256 profileId) external view override returns (string memory) {
        //todo SVG
    }

    /// @inheritdoc IProfileLogic
    function getFollowModule(uint256 profileId) external view override returns (address) {
        return _getProfileStorage()._profileById[profileId].followModule;
    }

    /// @inheritdoc IProfileLogic
    function getHandle(uint256 profileId) external view override returns (string memory) {
        return _getProfileStorage()._profileById[profileId].handle;
    }

    /// @inheritdoc IProfileLogic
    function getProfileIdByHandle(string calldata handle) external view override returns (uint256) {
        return _getProfileStorage()._profileIdByHandleHash[keccak256(bytes(handle))];
    }

    /// @inheritdoc IProfileLogic
    function getProfileIdByAddress(address addr) external view override returns (uint256) {
        return _getProfileStorage()._profileIdByAddress[addr];
    }

    /// @inheritdoc IProfileLogic
    function getProfile(
        uint256 profileId
    ) external view override returns (OspDataTypes.ProfileStruct memory) {
        return _getProfileStorage()._profileById[profileId];
    }

    /// @inheritdoc IProfileLogic
    function sigNonces(address addr) external view returns (uint256) {
        return _getProfileStorage()._sigNonces[addr];
    }

    /// @inheritdoc IERC721EnumerableUpgradeable
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view override returns (uint256) {
        require(index == 0 || balanceOf(owner) == 0, 'ERC721Enumerable: owner index out of bounds');
        return _getProfileStorage()._profileIdByAddress[owner];
    }

    /// @inheritdoc IERC721EnumerableUpgradeable
    function tokenByIndex(uint256 index) external view override returns (uint256) {
        return _getProfileStorage()._allTokens[index];
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    function _mint(address to) internal returns (uint256) {
        ProfileStorage storage profileStorage = _getProfileStorage();
        if (profileStorage._profileIdByAddress[to] != 0) revert OspErrors.SBTTokenAlreadyExists();
        uint256 tokenId = ++profileStorage._profileCounter;
        _addTokenToAllTokensEnumeration(tokenId);
        profileStorage._profileById[tokenId].owner = to;
        profileStorage._profileById[tokenId].mintTimestamp = uint96(block.timestamp);
        profileStorage._profileIdByAddress[to] = tokenId;
        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }

    function _burn(uint256 tokenId) internal {
        revert OspErrors.SBTTransferNotAllowed();
        // _removeTokenFromAllTokensEnumeration(tokenId);
        // ProfileStorage storage profileStorage = _getProfileStorage();
        // address owner = _ownerOf(tokenId);
        // delete profileStorage._profileById[tokenId].owner;
        // delete profileStorage._profileById[tokenId].dispatcher;
        // delete profileStorage._profileIdByAddress[owner];
        // delete profileStorage._profileIdByHandleHash[
        //     keccak256(bytes(profileStorage._profileById[tokenId].handle))
        // ];
        // delete profileStorage._profileById[tokenId].handle;
        // delete profileStorage._profileById[tokenId].followModule;
        // emit Transfer(owner, address(0), tokenId);
    }

    function _validateHandle(string memory handle) internal pure {
        bytes memory byteHandle = bytes(handle);
        if (
            byteHandle.length < Constants.MIN_HANDLE_LENGTH ||
            byteHandle.length > Constants.MAX_HANDLE_LENGTH
        ) revert OspErrors.HandleLengthInvalid();

        uint256 byteHandleLength = byteHandle.length;
        for (uint256 i = 0; i < byteHandleLength; ) {
            if (
                (byteHandle[i] < '0' ||
                    byteHandle[i] > 'z' ||
                    (byteHandle[i] > '9' && byteHandle[i] < 'a')) && byteHandle[i] != '_'
            ) revert OspErrors.HandleContainsInvalidCharacters();
            unchecked {
                ++i;
            }
        }
    }

    function _createProfile(
        address to,
        string memory handle,
        address followModule,
        bytes memory followModuleInitData
    ) internal returns (uint256) {
        _validateHandle(handle);
        ProfileStorage storage profileStorage = _getProfileStorage();
        mapping(bytes32 => uint256) storage _profileIdByHandleHash = profileStorage
            ._profileIdByHandleHash;
        mapping(uint256 => OspDataTypes.ProfileStruct) storage _profileById = profileStorage
            ._profileById;
        //mint SBT
        uint256 profileId = _mint(to);
        //set handle
        bytes32 handleHash = keccak256(bytes(handle));
        if (_profileIdByHandleHash[handleHash] != 0) revert OspErrors.HandleTaken();
        _profileById[profileId].handle = handle;
        _profileIdByHandleHash[handleHash] = profileId;
        //init follow module
        bytes memory followModuleReturnData;
        if (followModule != address(0)) {
            _profileById[profileId].followModule = followModule;
            followModuleReturnData = _initFollowModule(
                profileId,
                followModule,
                followModuleInitData
            );
        }
        _emitProfileCreated(to, profileId, handle, followModule, followModuleReturnData);
        return profileId;
    }

    function _setFollowModule(
        uint256 profileId,
        address followModule,
        bytes calldata followModuleInitData,
        OspDataTypes.ProfileStruct storage _profile
    ) internal {
        if (followModule != _profile.followModule) {
            _profile.followModule = followModule;
        }

        bytes memory followModuleReturnData;
        if (followModule != address(0))
            followModuleReturnData = _initFollowModule(
                profileId,
                followModule,
                followModuleInitData
            );
        emit OspEvents.FollowModuleSet(
            profileId,
            followModule,
            followModuleReturnData,
            block.timestamp
        );
    }

    function _setDispatcher(uint256 profileId, address dispatcher) internal {
        _getProfileStorage()._profileById[profileId].dispatcher = dispatcher;
        emit OspEvents.DispatcherSet(profileId, dispatcher, block.timestamp);
    }

    function _initFollowModule(
        uint256 profileId,
        address followModule,
        bytes memory followModuleInitData
    ) internal returns (bytes memory) {
        if (!_getGovernanceStorage()._followModuleWhitelisted[followModule])
            revert OspErrors.FollowModuleNotWhitelisted();
        return IFollowModule(followModule).initializeFollowModule(profileId, followModuleInitData);
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        ProfileStorage storage profileStorage = _getProfileStorage();
        profileStorage._allTokensIndex[tokenId] = profileStorage._allTokens.length;
        profileStorage._allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        ProfileStorage storage profileStorage = _getProfileStorage();
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = profileStorage._allTokens.length - 1;
        uint256 tokenIndex = profileStorage._allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = profileStorage._allTokens[lastTokenIndex];

        profileStorage._allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        profileStorage._allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete profileStorage._allTokensIndex[tokenId];
        profileStorage._allTokens.pop();
    }

    function _emitProfileCreated(
        address to,
        uint256 profileId,
        string memory handle,
        address followModule,
        bytes memory followModuleReturnData
    ) internal {
        emit OspEvents.ProfileCreated(
            profileId,
            msg.sender, // Creator is always the msg sender
            to,
            handle,
            followModule,
            followModuleReturnData,
            block.timestamp
        );
    }

    /*///////////////////////////////////////////////////////////////
                        UnSpport functions
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {
        revert OspErrors.SBTTransferNotAllowed();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external override {
        revert OspErrors.SBTTransferNotAllowed();
    }

    function transferFrom(address from, address to, uint256 tokenId) external override {
        revert OspErrors.SBTTransferNotAllowed();
    }

    function approve(address to, uint256 tokenId) external override {
        revert OspErrors.SBTTransferNotAllowed();
    }

    function setApprovalForAll(address operator, bool _approved) external override {
        revert OspErrors.SBTTransferNotAllowed();
    }

    function getApproved(uint256 tokenId) external view override returns (address operator) {
        revert OspErrors.SBTTransferNotAllowed();
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) external view override returns (bool) {
        revert OspErrors.SBTTransferNotAllowed();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import '../../libraries/OspDataTypes.sol';

/**
 * @title OspStorage
 * @author OpenSocial Protocol
 *
 * @notice This is an abstract contract that *only* contains storage for the OSP contract. This
 * *must* be inherited last (bar interfaces) in order to preserve the OSP storage layout. Adding
 * storage variables should be done solely at the bottom of this contract.
 */
abstract contract OspStorage {
    /*///////////////////////////////////////////////////////////////
                            ProfileStorage
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant PROFILE_STORAGE_POSITION = keccak256('osp.profile.storage');
    struct ProfileStorage {
        // Array with all token ids, used for enumeration
        uint256[] _allTokens;
        // Mapping from token id to position in the allTokens array
        mapping(uint256 => uint256) _allTokensIndex;
        mapping(bytes32 => uint256) _profileIdByHandleHash;
        mapping(uint256 => OspDataTypes.ProfileStruct) _profileById;
        mapping(address => uint256) _profileIdByAddress;
        uint256 _profileCounter;
        mapping(address => uint256) _sigNonces;
    }

    function _getProfileStorage() internal pure returns (ProfileStorage storage profileStorage) {
        bytes32 position = PROFILE_STORAGE_POSITION;
        assembly {
            profileStorage.slot := position
        }
    }

    /*///////////////////////////////////////////////////////////////
                            PublicationStorage
    //////////////////////////////////////////////////////////////*/
    bytes32 constant CONTENT_LIKE_COUNT = keccak256('CONTENT_LIKE_COUNT');
    bytes32 internal constant PUBLICATION_STORAGE_POSITION = keccak256('osp.publication.storage');
    struct PublicationStorage {
        mapping(uint256 => mapping(uint256 => OspDataTypes.ContentStruct)) _contentByIdByProfile;
        //profileId => contentId => key => value
        mapping(uint256 => mapping(uint256 => mapping(bytes32 => bytes))) _contentMetadataByIdByProfile;
        //profileId => referencedProfileId => referencedContentId => reactionType => reactionData
        mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(OspDataTypes.ReactionType => bytes)))) _reactionMetadata;
    }

    function _getPublicationStorage()
        internal
        pure
        returns (PublicationStorage storage publicationStorage)
    {
        bytes32 position = PUBLICATION_STORAGE_POSITION;
        assembly {
            publicationStorage.slot := position
        }
    }

    /*///////////////////////////////////////////////////////////////
                            PermissionStorage
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant GOVERNANCE_STORAGE_POSITION = keccak256('osp.permission.storage');
    struct GovernanceStorage {
        address _governance;
        address _emergencyAdmin;
        string _baseURI;
        mapping(address => bool) _superCommunityCreatorWhitelisted;
        mapping(address => bool) _followModuleWhitelisted;
        mapping(address => bool) _collectModuleWhitelisted;
        mapping(address => bool) _referenceModuleWhitelisted;
        mapping(address => bool) _joinModuleWhitelisted;
        mapping(address => bool) _communityConditionWhitelisted;
        mapping(bytes32 => bool) _reserveCommunityHandleHash;
        string _name;
        string _symbol;
        address _collectNFTImpl;
        address _followSBTImpl;
        address _joinNFTImpl;
        address _communityNFT;
    }

    function _getGovernanceStorage()
        internal
        pure
        returns (GovernanceStorage storage governanceStorage)
    {
        bytes32 position = GOVERNANCE_STORAGE_POSITION;
        assembly {
            governanceStorage.slot := position
        }
    }

    /*///////////////////////////////////////////////////////////////
                          CommunityStorage
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant COMMUNITY_STORAGE_POSITION = keccak256('osp.community.storage');
    struct CommunityStorage {
        // address -> tokenId -> communityId
        mapping(uint256 => OspDataTypes.CommunityStruct) _communityById;
        mapping(bytes32 => uint256) _communityIdByHandleHash;
    }

    function _getCommunityStorage()
        internal
        pure
        returns (CommunityStorage storage communityStorage)
    {
        bytes32 position = COMMUNITY_STORAGE_POSITION;
        assembly {
            communityStorage.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title IFollowModule
 * @author OpenSocial Protocol
 *
 * @notice This is the standard interface for all OSP-compatible FollowModules.
 */
interface IFollowModule {
    /**
     * @notice Initializes a follow module for a given OSP profile. This can only be called by the osp contract.
     *
     * @param profileId The token ID of the profile to initialize this follow module for.
     * @param data Arbitrary data passed by the profile creator.
     *
     * @return bytes The encoded data to emit in the osp.
     */
    function initializeFollowModule(uint256 profileId, bytes calldata data)
        external
        returns (bytes memory);

    /**
     * @notice Processes a given follow, this can only be called from the OSP contract.
     *
     * @param follower The follower address.
     * @param profileId The token ID of the profile being followed.
     * @param data Arbitrary data passed by the follower.
     */
    function processFollow(
        address follower,
        uint256 profileId,
        bytes calldata data
    ) external;

    /**
     * @notice This is a transfer hook that is called upon follow NFT transfer in `beforeTokenTransfer. This can
     * only be called from the OSP contract.
     *
     * NOTE: Special care needs to be taken here: It is possible that follow NFTs were issued before this module
     * was initialized if the profile's follow module was previously different. This transfer hook should take this
     * into consideration, especially when the module holds state associated with individual follow NFTs.
     *
     * @param profileId The token ID of the profile associated with the follow NFT being transferred.
     * @param from The address sending the follow NFT.
     * @param to The address receiving the follow NFT.
     * @param FollowSBTTokenId The token ID of the follow NFT being transferred.
     */
    function followModuleTransferHook(
        uint256 profileId,
        address from,
        address to,
        uint256 FollowSBTTokenId
    ) external;

    /**
     * @notice This is a helper function that could be used in conjunction with specific collect modules.
     *
     * NOTE: This function IS meant to replace a check on follower NFT ownership.
     *
     * NOTE: It is assumed that not all collect modules are aware of the token ID to pass. In these cases,
     * this should receive a `FollowSBTTokenId` of 0, which is impossible regardless.
     *
     * One example of a use case for this would be a subscription-based following system:
     *      1. The collect module:
     *          - Decodes a follower NFT token ID from user-passed data.
     *          - Fetches the follow module from the osp.
     *          - Calls `isFollowing` passing the profile ID, follower & follower token ID and checks it returned true.
     *      2. The follow module:
     *          - Validates the subscription status for that given NFT, reverting on an invalid subscription.
     *
     * @param profileId The token ID of the profile to validate the follow for.
     * @param follower The follower address to validate the follow for.
     * @param FollowSBTTokenId The FollowSBT token ID to validate the follow for.
     *
     * @return true if the given address is following the given profile ID, false otherwise.
     */
    function isFollowing(
        uint256 profileId,
        address follower,
        uint256 FollowSBTTokenId
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library Constants {
    string internal constant FOLLOW_NFT_NAME_SUFFIX = '-Follower';
    string internal constant FOLLOW_NFT_SYMBOL_SUFFIX = '-Fl';
    string internal constant COLLECT_NFT_NAME_INFIX = '-Collect-';
    string internal constant COLLECT_NFT_SYMBOL_INFIX = '-Cl-';
    string internal constant JOIN_NFT_NAME_INFIX = '-Join-';
    string internal constant JOIN_NFT_SYMBOL_INFIX = '-Jn-';
    uint8 internal constant MAX_HANDLE_LENGTH = 100;
    uint8 internal constant MIN_HANDLE_LENGTH = 6;
    uint16 internal constant MAX_PROFILE_IMAGE_URI_LENGTH = 6000;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title OspDataTypes
 * @author OpenSocial Protocol
 *
 * @notice A standard library of data types used throughout the OpenSocial Protocol.
 */
library OspDataTypes {
    /**
     * @notice An enum containing the different states the protocol can be in, limiting certain actions.
     *
     * @param Unpaused The fully unpaused state.
     * @param PublishingPaused The state where only content creation functions are paused.
     * @param Paused The fully paused state.
     */
    enum ProtocolState {
        Unpaused,
        PublishingPaused,
        Paused
    }

    /**
     * @notice An enum specifically used in a helper function to easily retrieve the content type for integrations.
     *
     * @param Post A standard post, having a URI, a collect module but no pointer to another publication.
     * @param Comment A comment, having a URI, a collect module and a pointer to another publication.
     * @param Mirror A mirror, having a pointer to another publication, but no URI or collect module.
     */
    enum ContentType {
        Post,
        Comment,
        Mirror
    }

    enum ReactionType {
        Like
    }

    /**
     * @notice A struct containing the necessary information to reconstruct an EIP-712 typed data signature.
     *
     * @param v The signature's recovery parameter.
     * @param r The signature's r parameter.
     * @param s The signature's s parameter
     * @param deadline The signature's deadline
     */
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    /**
     * @notice A struct containing profile data.
     *
     * @param contentCount The number of publications made to this profile.
     * @param followModule The address of the current follow module in use by this profile, can be empty.
     * @param FollowSBT The address of the FollowSBT associated with this profile, can be empty..
     * @param handle The profile's associated handle.
     * @param owner The profile's owner.
     * @param dispatcher The profile's dispatcher.
     * @param mintTimestamp The timestamp at which this profile was minted.
     */
    struct ProfileStruct {
        uint256 contentCount;
        address followModule;
        address FollowSBT;
        string handle;
        address owner;
        address dispatcher;
        uint96 mintTimestamp;
    }

    /**
     * @notice A struct containing data associated with each new publication.
     *
     * @param contentType The type of publication, can be post, comment or mirror.
     * @param communityId The community's token ID.
     * @param referencedProfileId The profile token ID this content points to, for mirrors and comments.
     * @param referencedContentId The content ID this content points to, for mirrors and comments.
     * @param contentURI The URI associated with this publication.
     * @param referenceModule The address of the current reference module in use by this publication, can be empty.
     * @param collectModule The address of the collect module associated with this publication, this exists for all publication.
     * @param collectNFT The address of the collectNFT associated with this publication, if any.
     */
    struct ContentStruct {
        ContentType contentType;
        uint256 communityId;
        uint256 referencedProfileId;
        uint256 referencedContentId;
        string contentURI;
        address referenceModule;
        address collectModule;
        address collectNFT;
    }

    /**
     * @notice A struct containing the parameters required for the `createProfile()` function.
     *
     * @param handle The handle to set for the profile, must be unique and non-empty.
     * @param followModule The follow module to use, can be the zero address.
     * @param followModuleInitData The follow module initialization data, if any.
     */
    struct CreateProfileData {
        string handle;
        address followModule;
        bytes followModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `createProfileWithSig()` function. Parameters are
     * the same as the regular `createProfile()` function, with an added EIP712Signature.
     *
     * @param to The address to mint the profile to.
     * @param handle The handle to set for the profile, must be unique and non-empty.
     * @param followModule The follow module to use, can be the zero address.
     * @param followModuleInitData The follow module initialization data, if any.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct CreateProfileWithSigData {
        address to;
        string handle;
        address followModule;
        bytes followModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setFollowModuleWithSig()` function. Parameters are
     * the same as the regular `setFollowModule()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to change the followModule for.
     * @param followModule The followModule to set for the given profile, must be whitelisted.
     * @param followModuleInitData The data to be passed to the followModule for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetFollowModuleWithSigData {
        uint256 profileId;
        address followModule;
        bytes followModuleInitData;
        EIP712Signature sig;
    }

    struct SetJoinModuleWithSigData {
        uint256 communityId;
        address joinModule;
        bytes joinModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setDispatcherWithSig()` function. Parameters are the same
     * as the regular `setDispatcher()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to set the dispatcher for.
     * @param dispatcher The dispatcher address to set for the profile.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetDispatcherWithSigData {
        uint256 profileId;
        address dispatcher;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setProfileImageURIWithSig()` function. Parameters are the same
     * as the regular `setProfileImageURI()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to set the URI for.
     * @param imageURI The URI to set for the given profile image.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetProfileImageURIWithSigData {
        uint256 profileId;
        string imageURI;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setFollowSBTURIWithSig()` function. Parameters are the same
     * as the regular `setFollowSBTURI()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile for which to set the FollowSBT URI.
     * @param FollowSBTURI The follow NFT URI to set.
     * @param sig The EIP712Signature struct containing the FollowSBT's associated profile owner's signature.
     */
    struct SetFollowSBTURIWithSigData {
        uint256 profileId;
        string followSBTURI;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `post()` function.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param communityId The token ID of the community to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param collectModule The collect module to set for this new publication.
     * @param collectModuleInitData The data to pass to the collect module's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct PostData {
        uint256 profileId;
        uint256 communityId;
        string contentURI;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `postWithSig()` function. Parameters are the same as
     * the regular `post()` function, with an added EIP712Signature.
     *
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param collectModule The collectModule to set for this new publication.
     * @param collectModuleInitData The data to pass to the collectModule's initialization.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct PostWithSigData {
        uint256 profileId;
        uint256 communityId;
        string contentURI;
        address collectModule;
        bytes collectModuleInitData;
        address referenceModule;
        bytes referenceModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `addContentReaction()` function.
     *
     * @param reactionType The type of reaction to add.
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param referencedProfileId The profile token ID to interact with.
     * @param referencedContentId The content ID to interact with.
     * @param referenceModuleData The data passed to the reference module.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     */
    struct ContentReactionData {
        ContentType reactionType;
        uint256 profileId;
        string contentURI;
        uint256 referencedProfileId;
        uint256 referencedContentId;
        bytes referenceModuleData;
        address referenceModule;
        bytes referenceModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `addContentReactionWithSig()` function. Parameters are the same as
     * the regular `addContentReaction()` function, with an added EIP712Signature.
     *
     * @param reactionType The type of reaction to add.
     * @param profileId The token ID of the profile to publish to.
     * @param contentURI The URI to set for this new publication.
     * @param referencedProfileId The profile token ID to interact with.
     * @param referencedContentId The content ID to interact with.
     * @param referenceModuleData The data passed to the reference module.
     * @param referenceModule The reference module to set for the given publication, must be whitelisted.
     * @param referenceModuleInitData The data to be passed to the reference module for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct ContentReactionWithSigData {
        ContentType reactionType;
        uint256 profileId;
        string contentURI;
        uint256 referencedProfileId;
        uint256 referencedContentId;
        bytes referenceModuleData;
        address referenceModule;
        bytes referenceModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `addReaction()` function.
     *
     * @param reactionType The type of reaction to add.
     * @param profileId The token ID of the profile to publish to.
     * @param referencedProfileId The profile token ID to interact with.
     * @param referencedContentId The content ID to interact with.
     * @param referenceModuleData The data passed to the reference module.
     * @param data The data passed to the reaction logic.
     */
    struct ReactionData {
        ReactionType reactionType;
        uint256 profileId;
        uint256 referencedProfileId;
        uint256 referencedContentId;
        bytes referenceModuleData;
        bytes data;
    }

    /**
     * @notice A struct containing the parameters required for the `addReactionWithSig()` function. Parameters are the same as
     * the regular `addReaction()` function, with an added EIP712Signature.
     *
     * @param reactionType The type of reaction to add.
     * @param profileId The token ID of the profile to publish to.
     * @param referencedProfileId The profile token ID to interact with.
     * @param referencedContentId The content ID to interact with.
     * @param referenceModuleData The data passed to the reference module.
     * @param data The data passed to the reaction logic.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct ReactionWithSigData {
        ReactionType reactionType;
        uint256 profileId;
        uint256 referencedProfileId;
        uint256 referencedContentId;
        bytes referenceModuleData;
        bytes data;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `like()` function.
     *
     * @param profileId The token ID of the profile to like to.
     * @param referencedProfileId The profile token ID to point the like to.
     * @param referencedContentId The content ID to point the like to.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct LikeWithSigData {
        uint256 profileId;
        uint256 referencedProfileId;
        uint256 referencedContentId;
        bool doLike;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `like()` function.
     *
     * @param applicant The address of the applicant joining the community.
     * @param communityId The ID of the community join to.
     * @param data The data passed to the join module.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct JoinWithSigData {
        address applicant;
        uint256 communityId;
        bytes data;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `followWithSig()` function. Parameters are the same
     * as the regular `follow()` function, with the follower's (signer) address and an EIP712Signature added.
     *
     * @param follower The follower which is the message signer.
     * @param profileIds The array of token IDs of the profiles to follow.
     * @param datas The array of arbitrary data to pass to the followModules if needed.
     * @param sig The EIP712Signature struct containing the follower's signature.
     */
    struct FollowWithSigData {
        address follower;
        uint256[] profileIds;
        bytes[] datas;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `collectWithSig()` function. Parameters are the same as
     * the regular `collect()` function, with the collector's (signer) address and an EIP712Signature added.
     *
     * @param collector The collector which is the message signer.
     * @param profileId The token ID of the profile that published the content to collect.
     * @param contentId The content to collect's content ID.
     * @param data The arbitrary data to pass to the collectModule if needed.
     * @param sig The EIP712Signature struct containing the collector's signature.
     */
    struct CollectWithSigData {
        address collector;
        uint256 profileId;
        uint256 contentId;
        bytes data;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setProfileMetadataWithSig()` function.
     *
     * @param profileId The profile ID for which to set the metadata.
     * @param metadata The metadata string to set for the profile and user.
     * @param sig The EIP712Signature struct containing the user's signature.
     */
    struct SetProfileMetadataWithSigData {
        uint256 profileId;
        string metadata;
        EIP712Signature sig;
    }

    struct CreateCommunityData {
        string handle;
        address condition;
        bytes conditionData;
        address joinModule;
        bytes joinModuleInitData;
    }

    struct CreateCommunityWithSigData {
        address to;
        string handle;
        address condition;
        bytes conditionData;
        address joinModule;
        bytes joinModuleInitData;
        EIP712Signature sig;
    }

    struct CommunityStruct {
        string handle;
        address joinModule;
        address joinNFT;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

library OspErrors {
    error CannotInitImplementation();
    error Initialized();
    error SignatureExpired();
    error ZeroSpender();
    error SignatureInvalid();
    error NotOwnerOrApproved();
    error NotOSP();
    error TokenDoesNotExist();
    error NotGovernance();
    error NotGovernanceOrEmergencyAdmin();
    error EmergencyAdminCannotUnpause();
    error CallerNotWhitelistedModule();
    error CollectModuleNotWhitelisted();
    error FollowModuleNotWhitelisted();
    error ReferenceModuleNotWhitelisted();
    error JoinModuleNotWhitelisted();
    error ProfileCreatorNotWhitelisted();
    error NotProfileOwner();
    error NotHasProfile();
    error NotProfileOwnerOrDispatcher();
    error NotDispatcher();
    error PublicationDoesNotExist();
    error HandleTaken();
    error HandleLengthInvalid();
    error HandleContainsInvalidCharacters();
    error HandleFirstCharInvalid();
    error CallerNotFollowSBT();
    error CallerNotCollectNFT();
    error BlockNumberInvalid();
    error ArrayMismatch();
    error NotWhitelisted();
    error InvalidParameter();
    error SBTTransferNotAllowed();
    error SBTTokenAlreadyExists();
    error LikeInvalid();

    // Module Errors
    error InitParamsInvalid();
    error CollectExpired();
    error FollowInvalid();
    error ModuleDataMismatch();
    error FollowNotApproved();
    error MintLimitExceeded();
    error CollectNotAllowed();

    // MultiState Errors
    error Paused();
    error PublishingPaused();

    error SlotNFTNotWhitelisted();
    error TargetNotWhitelisted();
    error NotSlotNFTOwner();
    error SlotNFTAlreadyUsed();
    error NotCommunityOwner();
    error NotJoinCommunity();
    error CommunityConditionNotWhitelisted();
    error InvalidCommunityId();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {OspDataTypes} from './OspDataTypes.sol';

library OspEvents {
    /**
     * @dev Emitted when the NFT contract's name and symbol are set at initialization.
     *
     * @param name The NFT name set.
     * @param symbol The NFT symbol set.
     * @param timestamp The current block timestamp.
     */
    event BaseInitialized(string name, string symbol, uint256 timestamp);

    event OSPInitialized(
        string name,
        string symbol,
        address collectNFTImpl,
        address followSBTImpl,
        address joinNFTImpl,
        address communityNFT,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the osp state is set.
     *
     * @param caller The caller who set the state.
     * @param prevState The previous protocol state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
     * @param newState The newly set state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
     * @param timestamp The current block timestamp.
     */
    event StateSet(
        address indexed caller,
        OspDataTypes.ProtocolState indexed prevState,
        OspDataTypes.ProtocolState indexed newState,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the governance address is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the governance address.
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event GovernanceSet(
        address indexed caller,
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the emergency admin is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the emergency admin address.
     * @param oldEmergencyAdmin The previous emergency admin address.
     * @param newEmergencyAdmin The new emergency admin address set.
     * @param timestamp The current block timestamp.
     */
    event EmergencyAdminSet(
        address indexed caller,
        address indexed oldEmergencyAdmin,
        address indexed newEmergencyAdmin,
        uint256 timestamp
    );

    event BaseURISet(
        string communityNFTBaseURI,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a follow module is added to or removed from the whitelist.
     *
     * @param followModule The address of the follow module.
     * @param whitelisted Whether or not the follow module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event FollowModuleWhitelisted(
        address indexed followModule,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a reference module is added to or removed from the whitelist.
     *
     * @param referenceModule The address of the reference module.
     * @param whitelisted Whether or not the reference module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event ReferenceModuleWhitelisted(
        address indexed referenceModule,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a collect module is added to or removed from the whitelist.
     *
     * @param collectModule The address of the collect module.
     * @param whitelisted Whether or not the collect module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event CollectModuleWhitelisted(
        address indexed collectModule,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a join module is added to or removed from the whitelist.
     *
     * @param joinModule The address of the join module.
     * @param whitelisted Whether or not the collect module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event JoinModuleWhitelisted(
        address indexed joinModule,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a community condition is added to or removed from the whitelist.
     *
     * @param communityCondition The address of the community condition.
     * @param whitelisted Whether or not the collect module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event CommunityConditionWhitelisted(
        address indexed communityCondition,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a super community creator is added to or removed from the whitelist.
     *
     * @param superCommunityCreator The address of the super community creator.
     * @param whitelisted Whether or not the collect module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event SuperCommunityCreatorWhitelisted(
        address indexed superCommunityCreator,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @dev Emitted when add or remove a reserve community handle.
     *
     * @param handleHash The hash of the handle to add or remove.
     * @param handle The handle to add or remove.
     * @param isReserved Whether or not the handle is being added to the reserve list.
     * @param timestamp The current block timestamp.
     */
    event CommunityHandleReserve(
        bytes32 indexed handleHash,
        bool indexed isReserved,
        string handle,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a profile is created.
     *
     * @param profileId The newly created profile's token ID.
     * @param creator The profile creator, who created the token with the given profile ID.
     * @param to The address receiving the profile with the given profile ID.
     * @param handle The handle set for the profile.
     * @param followModule The profile's newly set follow module. This CAN be the zero address.
     * @param followModuleReturnData The data returned from the follow module's initialization. This is abi encoded
     * and totally depends on the follow module chosen.
     * @param timestamp The current block timestamp.
     */
    event ProfileCreated(
        uint256 indexed profileId,
        address indexed creator,
        address indexed to,
        string handle,
        address followModule,
        bytes followModuleReturnData,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a dispatcher is set for a specific profile.
     *
     * @param profileId The token ID of the profile for which the dispatcher is set.
     * @param dispatcher The dispatcher set for the given profile.
     * @param timestamp The current block timestamp.
     */
    event DispatcherSet(uint256 indexed profileId, address indexed dispatcher, uint256 timestamp);

    /**
     * @dev Emitted when a profile's follow module is set.
     *
     * @param profileId The profile's token ID.
     * @param followModule The profile's newly set follow module. This CAN be the zero address.
     * @param followModuleReturnData The data returned from the follow module's initialization. This is abi encoded
     * and totally depends on the follow module chosen.
     * @param timestamp The current block timestamp.
     */
    event FollowModuleSet(
        uint256 indexed profileId,
        address followModule,
        bytes followModuleReturnData,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a "post" is published.
     *
     * @param profileId The profile's token ID.
     * @param contentId The new publication's ID.
     * @param communityId The community's token ID.
     * @param contentURI The URI mapped to this new publication.
     * @param collectModule The collect module mapped to this new publication. This CANNOT be the zero address.
     * @param collectModuleReturnData The data returned from the collect module's initialization for this given
     * publication. This is abi encoded and totally depends on the collect module chosen.
     * @param referenceModule The reference module set for this publication.
     * @param referenceModuleReturnData The data returned from the reference module at initialization. This is abi
     * encoded and totally depends on the reference module chosen.
     * @param timestamp The current block timestamp.
     */
    event PostCreated(
        uint256 indexed profileId,
        uint256 indexed contentId,
        uint256 communityId,
        string contentURI,
        address collectModule,
        bytes collectModuleReturnData,
        address referenceModule,
        bytes referenceModuleReturnData,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a "reaction" is content.
     *
     * @param profileId The profile's token ID.
     * @param contentId The new publication's ID.
     * @param contentType The type of content this reaction is pointing to.
     * @param contentURI The URI mapped to this new publication.
     * @param referencedProfileId The profile token ID that this comment points to.
     * @param referencedContentId The content ID that this comment points to.
     * @param referenceModuleData The data passed to the reference module.
     * @param referenceModule The reference module set for this publication.
     * @param referenceModuleReturnData The data returned from the reference module at initialization. This is abi
     * encoded and totally depends on the reference module chosen.
     * @param timestamp The current block timestamp.
     */
    event ContentReactionCreated(
        uint256 indexed profileId,
        uint256 indexed contentId,
        OspDataTypes.ContentType contentType,
        string contentURI,
        uint256 referencedProfileId,
        uint256 referencedContentId,
        bytes referenceModuleData,
        address referenceModule,
        bytes referenceModuleReturnData,
        uint256 timestamp
    );

    event ReactionCreated(
        uint256 indexed profileId,
        OspDataTypes.ReactionType reactionType,
        uint256 referencedProfileId,
        uint256 referencedContentId,
        bytes referenceModuleData,
        bytes data,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a FollowSBT clone is deployed using a lazy deployment pattern.
     *
     * @param profileId The token ID of the profile to which this FollowSBT is associated.
     * @param followSBT The address of the newly deployed FollowSBT clone.
     * @param timestamp The current block timestamp.
     */
    event FollowSBTDeployed(
        uint256 indexed profileId,
        address indexed followSBT,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a collectNFT clone is deployed using a lazy deployment pattern.
     *
     * @param profileId The publisher's profile token ID.
     * @param contentId The content associated with the newly deployed collectNFT clone's ID.
     * @param collectNFT The address of the newly deployed collectNFT clone.
     * @param timestamp The current block timestamp.
     */
    event CollectNFTDeployed(
        uint256 indexed profileId,
        uint256 indexed contentId,
        address indexed collectNFT,
        uint256 timestamp
    );

    /**
     * @dev Emitted upon a successful collect action.
     *
     * @param collector The address collecting the publication.
     * @param profileId The token ID of the profile that the collect was initiated towards, useful to differentiate mirrors.
     * @param contentId The content ID that the collect was initiated towards, useful to differentiate mirrors.
     * @param rootProfileId The profile token ID of the profile whose content is being collected.
     * @param rootcontentId The content ID of the content being collected.
     * @param collectModuleData The data passed to the collect module.
     * @param timestamp The current block timestamp.
     */
    event Collected(
        address indexed collector,
        uint256 indexed profileId,
        uint256 indexed contentId,
        uint256 rootProfileId,
        uint256 rootcontentId,
        bytes collectModuleData,
        uint256 timestamp
    );

    /**
     * @dev Emitted upon a successful follow action.
     *
     * @param follower The address following the given profiles.
     * @param profileIds The token ID array of the profiles being followed.
     * @param followModuleDatas The array of data parameters passed to each follow module.
     * @param timestamp The current block timestamp.
     */
    event Followed(
        address indexed follower,
        uint256 followerProfileId,
        uint256[] profileIds,
        bytes[] followModuleDatas,
        uint256 timestamp
    );

    /**
     * @dev Emitted via callback when a FollowSBT is transferred.
     *
     * @param profileId The token ID of the profile associated with the FollowSBT being transferred.
     * @param followSBTId The FollowSBT being transferred's token ID.
     * @param from The address the FollowSBT is being transferred from.
     * @param to The address the FollowSBT is being transferred to.
     * @param timestamp The current block timestamp.
     */
    event FollowSBTTransferred(
        uint256 indexed profileId,
        uint256 indexed followSBTId,
        address from,
        address to,
        uint256 timestamp
    );

    /**
     * @dev Emitted via callback when a collectNFT is transferred.
     *
     * @param profileId The token ID of the profile associated with the collectNFT being transferred.
     * @param contentId The content ID associated with the collectNFT being transferred.
     * @param collectNFTId The collectNFT being transferred's token ID.
     * @param from The address the collectNFT is being transferred from.
     * @param to The address the collectNFT is being transferred to.
     * @param timestamp The current block timestamp.
     */
    event CollectNFTTransferred(
        uint256 indexed profileId,
        uint256 indexed contentId,
        uint256 indexed collectNFTId,
        address from,
        address to,
        uint256 timestamp
    );

    /**
     * @dev Emitted via callback when a communityNFT is transferred.
     *
     * @param communityId The token ID of the community associated with the communityNFT being transferred.
     * @param from The address the communityNFT is being transferred from.
     * @param to The address the communityNFT is being transferred to.
     * @param timestamp The current block timestamp.
     */
    event CommunityNFTTransferred(
        uint256 indexed communityId,
        address from,
        address to,
        uint256 timestamp
    );

    /**
     * @dev Emitted via callback when a JoinNFT is transferred.
     *
     * @param joinNFTId The token ID of the profile associated with the JoinNFT being transferred.
     * @param from The address the JoinNFT is being transferred from.
     * @param to The address the JoinNFT is being transferred to.
     * @param timestamp The current block timestamp.
     */
    event JoinNFTTransferred(
        uint256 indexed communityId,
        uint256 indexed joinNFTId,
        address from,
        address to,
        uint256 timestamp
    );

    // Collect/Follow SBT-Specific

    /**
     * @dev Emitted when a newly deployed follow NFT is initialized.
     *
     * @param profileId The token ID of the profile connected to this follow NFT.
     * @param timestamp The current block timestamp.
     */
    event FollowSBTInitialized(uint256 indexed profileId, uint256 timestamp);

    /**
     * @dev Emitted when delegation power in a FollowSBT is changed.
     *
     * @param delegate The delegate whose power has been changed.
     * @param newPower The new governance power mapped to the delegate.
     * @param timestamp The current block timestamp.
     */
    event FollowSBTDelegatedPowerChanged(
        address indexed delegate,
        uint256 indexed newPower,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a newly deployed collect NFT is initialized.
     *
     * @param profileId The token ID of the profile connected to the content mapped to this collect NFT.
     * @param contentId The content ID connected to the content mapped to this collect NFT.
     * @param timestamp The current block timestamp.
     */
    event CollectNFTInitialized(
        uint256 indexed profileId,
        uint256 indexed contentId,
        uint256 timestamp
    );

    // Module-Specific

    /**
     * @notice Emitted when the ModuleGlobals governance address is set.
     *
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event ModuleGlobalsGovernanceSet(
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the ModuleGlobals treasury address is set.
     *
     * @param prevTreasury The previous treasury address.
     * @param newTreasury The new treasury address set.
     * @param timestamp The current block timestamp.
     */
    event ModuleGlobalsTreasurySet(
        address indexed prevTreasury,
        address indexed newTreasury,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the ModuleGlobals treasury fee is set.
     *
     * @param prevTreasuryFee The previous treasury fee in BPS.
     * @param newTreasuryFee The new treasury fee in BPS.
     * @param timestamp The current block timestamp.
     */
    event ModuleGlobalsTreasuryFeeSet(
        uint16 indexed prevTreasuryFee,
        uint16 indexed newTreasuryFee,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a currency is added to or removed from the ModuleGlobals whitelist.
     *
     * @param currency The currency address.
     * @param prevWhitelisted Whether or not the currency was previously whitelisted.
     * @param whitelisted Whether or not the currency is whitelisted.
     * @param timestamp The current block timestamp.
     */
    event ModuleGlobalsCurrencyWhitelisted(
        address indexed currency,
        bool indexed prevWhitelisted,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a module inheriting from the `FeeModuleBase` is constructed.
     *
     * @param moduleGlobals The ModuleGlobals contract address used.
     * @param timestamp The current block timestamp.
     */
    event FeeModuleBaseConstructed(address indexed moduleGlobals, uint256 timestamp);

    /**
     * @notice Emitted when a module inheriting from the `ModuleBase` is constructed.
     *
     * @param osp The OSP contract address used.
     * @param timestamp The current block timestamp.
     */
    event ModuleBaseConstructed(address indexed osp, uint256 timestamp);

    /**
     * @notice Emitted when one or multiple addresses are approved (or disapproved) for following in
     * the `ApprovalFollowModule`.
     *
     * @param owner The profile owner who executed the approval.
     * @param profileId The profile ID that the follow approvals are granted/revoked for.
     * @param addresses The addresses that have had the follow approvals grnated/revoked.
     * @param approved Whether each corresponding address is now approved or disapproved.
     * @param timestamp The current block timestamp.
     */
    event FollowsApproved(
        address indexed owner,
        uint256 indexed profileId,
        address[] addresses,
        bool[] approved,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the user wants to enable or disable follows in the `OSPPeriphery`.
     *
     * @param owner The profile owner who executed the toggle.
     * @param profileIds The array of token IDs of the profiles each FollowSBT is associated with.
     * @param enabled The array of whether each FollowSBT's follow is enabled/disabled.
     * @param timestamp The current block timestamp.
     */
    event FollowsToggled(
        address indexed owner,
        uint256[] profileIds,
        bool[] enabled,
        uint256 timestamp
    );

    /**
     * @dev Emitted when the metadata associated with a profile is set in the `OSPPeriphery`.
     *
     * @param profileId The profile ID the metadata is set for.
     * @param metadata The metadata set for the profile and user.
     * @param timestamp The current block timestamp.
     */
    event ProfileMetadataSet(uint256 indexed profileId, string metadata, uint256 timestamp);

    /**
     * @dev Emitted when a newly deployed join NFT is initialized.
     *
     * @param communityId The unique ID of the community mapped to this collect NFT.
     * @param timestamp The current block timestamp.
     */
    event JoinNFTInitialized(uint256 indexed communityId, uint256 timestamp);

    /**
     * @dev Emitted when a JoinNFT clone is deployed using a lazy deployment pattern.
     *
     * @param communityId The unique ID of the community mapped to this join NFT.
     * @param joinNFT The address of the newly deployed joinNFT clone.
     * @param timestamp The current block timestamp.
     */
    event JoinNFTDeployed(uint256 indexed communityId, address indexed joinNFT, uint256 timestamp);

    /**
     * @dev Emitted when a community is created.
     */
    event CommunityCreated(
        uint256 indexed communityId,
        address indexed to,
        uint256 profileId,
        string handle,
        address conditon,
        bytes conditionReturnData,
        address joinModule,
        bytes joinModuleReturnData,
        address joinNFT,
        uint256 timestamp
    );

    event Joined(
        address indexed joiner,
        uint256 indexed communityId,
        uint256 joinerProfileId,
        bytes joinModuleData,
        uint256 timestamp
    );

    /**
     * @dev Emitted when a community's join module is set.
     *
     * @param communityId The community's token ID.
     * @param joinModule The community's newly set join module. This CAN be the zero address.
     * @param joinModuleReturnData The data returned from the join module's initialization. This is abi encoded
     * and totally depends on the follow module chosen.
     * @param timestamp The current block timestamp.
     */
    event JoinModuleSet(
        uint256 indexed communityId,
        address joinModule,
        bytes joinModuleReturnData,
        uint256 timestamp
    );
}