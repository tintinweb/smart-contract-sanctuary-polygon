/**
 *Submitted for verification at polygonscan.com on 2023-07-01
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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
    ) external payable;

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
    ) external payable;
}

// SegMint ERC1155 DB interface
interface SegMintERC1155DBInterface {
    // get holders of a token id
    function getTokenIDHolders(uint256 tokenID_)
        external
        view
        returns (address[] memory);

    // get balance Of
    function getBalanceOf(uint256 tokenID_, address account_)
        external
        view
        returns (uint256);

    function getAvailableBalance(uint256 TokenID_, address account_)
        external
        view
        returns (uint256);
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

// SegMint NFT Locking Contract Interface
interface SegMintNFTLockingContractInterface {
    // get owner Wallet Address
    function getOwnerWalletAddress() external view returns (address);

    // fractioner locks the NFT and pays the gas fee
    function fractionerLock(address contractAddress, uint256 tokenId)
        external
        returns (bool);

    // fractioner unlock the NFT
    function fractionerUnlock(address contractAddress, uint256 tokenId)
        external
        returns (bool);

    // fractioner unlock and transfer NFT
    function fractionerUnlockAndTransfer(
        address contractAddress,
        uint256 tokenId,
        address _transferToAddress
    ) external returns (bool);
}

// SegMint ERC721 Contract Interface
interface SegMintERC721ContractInterface {
    // owner of
    function ownerOf(uint256 tokenId) external view returns (address);

    // fractioner locks the NFT and pays the gas fee
    function fractionerLock(uint256 tokenId) external returns (bool);

    // fractioner unlock the NFT
    function fractionerUnlock(uint256 tokenId) external returns (bool);

    // fractioner unlock and transfer NFT
    function fractionerUnlockAndTransfer(
        uint256 tokenId,
        address _transferToAddress
    ) external returns (bool);
}

// SegMint KYC Contract Interface
interface SegMintKYCContractInterface {
    // is authorized
    function isAuthorizedAddress(address account_) external view returns (bool);
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
    function getGlobalTransactionsFreezeStatus() external view returns(bool);

    // freeze global transaction for specific TokenID
    function freezeGlobalTransactionsSpecificTokenID(uint256 TokenID_) external;

    // unfreeze global transaction for specific TokenID
    function unFreezeGlobalTransactionsSpecificTokenID(uint256 TokenID_) external;

    // get global transaction status for Specific TokenID
    function getGlobalTransactionsFreezeStatusSpecificTokenID(uint256 TokenID_) external view returns(bool);

    // function to lock tokens while listing the NFT
    function lockToken(uint256 TokenID_, address account_, uint256 amount_) external returns (bool);

    // function to un lock tokens while de-listing the NFT
    function unlockToken(uint256 TokenID_, address account_, uint256 amount_) external returns (bool);

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

// strucs
contract SegMintExchangeStructs {
    // locking a NFT and fractionalizing info
    struct lockingAndFractionalizingNFTInfo {
        /* lock and fractionalization index*/
        uint256 lockAndFractionalizationIndex;
        /* NFT Info */
        // NFT creator
        address NFTCreatorAddress;
        // NFT Owner
        address NFTOwnerAddress;
        // NFT contract address
        address NFTContractAddress;
        //NFT token Id
        uint256 NFTTokenID;
        /* Locking Info */
        // is segmint NFT
        // if segmint then its locking contract is zero address
        bool isSegMintNFT;
        // locking contract address
        address lockingContractAddress;
        // locker's address
        address lockerAddress;
        // is locked
        bool isLocked;
        // locking timestamp
        uint256 lockingTimestamp;
        // unlocking timestamp
        uint256 unlockTimestamp;
        /* Fractionalization Info*/
        // is fractionalized
        // if fractionalized then cannot mint fractions again
        bool isFractionalized;
        // ERC1155 token id
        uint256 ERC1155TokenID;
        // fractionalization option (either FREEMARKET or BUYOUTMARKET)
        string fractionalizationOption;
        // total number of fractions
        uint256 totalFractions;
        // buyout price per fraction
        uint256 buyoutPricePerFraction;
        // reserve price per fraction
        uint256 reservePricePerFraction;
        // fractionalization timestamp
        uint256 fractionalizationTimestamp;
        /* Listing Info */
        bool isListed;
    }

    // listing of a security info
    struct ListingInfo {
        /* Listing index*/
        uint256 _listingIndex;
        // lock and fractionalization index for the NFT
        uint256 lockAndFractionalizationIndex;
        /* ERC1155 Info */
        // lister (owner) address
        address ERC1155TokenOwnerAddress;
        // ERC1155 Contract Address
        address ERC1155ContractAddress;
        // ERC1155 Token ID
        uint256 ERC1155TokenID;
        /* Sale Info */
        // sell price per fraction
        uint256 pricePerFraction;
        // number of fractions
        uint256 amount;
        // time of listing
        uint256 listingTimestamp;
        // last update time
        uint256 lastUpdateTimestamp;
        // is delisted
        uint256 delistingTimestamp;
        // listing end date
        uint256 listingEndDateTimestamp;
    }
}

// SegMint Exchange DB
contract SegMintExchangeDB is SegMintExchangeStructs {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // owner address
    address private _owner;

    // SegMint Exchange DB Admin
    address private _SegMintExchangeDBAdmin;


    // SegMint Key Generator
    address private _SegmintKeyGenerator;


    // SegMint ERC1155
    address private _SegMintERC1155ContractAddress;

    // SegMint ERC1155 DB
    address private _SegMintERC1155DBContractAddress;

    // SegMint KYC
    address private _SegMintKYCContractAddress;

    // contract version
    uint256 private _contractVersion = 1;

    /* Locking and Fractionalization Fields */

    // lock and fractionalization counter (
    uint256 private _lockAndFractionalizationIndex = 1; // zero reserved for not locked

    // locked Or fractionalized NFT info: lock and fractionalization index => lockingAndFractionalizingNFTInfo
    mapping(uint256 => lockingAndFractionalizingNFTInfo)
        private _lockingAndFractionalizingNFTInfo;

    // lock and fractionalization index for an NFT: NFT Contract Address => NFT Token ID => lock and fractionaliztion index
    mapping(address => mapping(uint256 => uint256))
        private _NFTLockingAndFractionalizationIndex;

    // All the NFT contract address whose nfts are locked
    address[] private _lockedNFTContracts;

    // NFT contract address locked status: NFT Contract Address => bool
    mapping(address => bool) private _lockedNFTContractsStatus;

    // all tokens ids locked for each NFT contract address
    mapping(address => uint256[]) private _lockedNFTTokenIDs;

    // NFT contract address, Token ID locked status: NFT Contract Address => Token ID => bool
    mapping(address => mapping(uint256 => bool))
        private _lockedNFTTokenIDsStatus;

    // list of NFT contract addresses locked for an owner: owner address => NFT contract address []
    mapping(address => address[]) private _lockedNFTContractsOfOwner;

    // NFT Contract Address locked  status by owner: owner address => NFT Contract Address => bool
    mapping(address => mapping(address => bool))
        private _lockedNFTContractsOfOwnerStatus;

    // list of all NFT token IDs of an NFT contract locked for an owner: owner address => NFT contract address => token ids[]
    mapping(address => mapping(address => uint256[]))
        private _lockedNFTContractTokenIDsOfOwner;

    // NFT token IDs fo an NFT contract locked for an owner status: owner address => NFT Contract Address => Token ID => bool
    mapping(address => mapping(address => mapping(uint256 => bool)))
        private _lockedNFTContractTokenIDsOfOwnerStatus;

    /* Listing Fields */

    // listing counter
    uint256 private _listingIndex = 1; // zero reserved for not listed

    // securities on the market: listing index => ListingsInfo
    mapping(uint256 => ListingInfo) private _listingsInfo;

    // all listed ERC1155 contract addressses
    address[] private _listedERC1155Contracts;

    // listing ERC1155 Contracts status: ERC1155 Contract Address => bool
    mapping(address => bool) private _listedERC1155ContractsStatus;

    // all token IDs listed for a specific ERC1155 contract: ERC1155 contract address => tokenIDs[]
    mapping(address => uint256[]) private _listedERC1155TokenIDs;

    // listed ERC1155 Token ID status: ERC1155 Contract Address => ERC1155 Token ID => bool
    mapping(address => mapping(uint256 => bool))
        private _listedERC1155TokenIDsStatus;

    // lister's address: ERC1155 contract address => Token ID => listers[]
    mapping(address => mapping(uint256 => address[]))
        private _listersOfERC11555TokenID;

    // lister's of a ERC1155 Token ID status: ERC1155 Contract Address => ERC1155 Token ID => lister => bool
    mapping(address => mapping(uint256 => mapping(address => bool)))
        private _listersOfERC11555TokenIDStatus;

    // lister's address: ERC1155 contract address => Token ID => listing indexes[]
    mapping(address => mapping(uint256 => uint256[]))
        private _ERC1155TokenIDListingIndexes;

    // lister's address status: ERC1155 contract address => Token ID => listing indexe => bool
    mapping(address => mapping(uint256 => mapping(uint256 => bool)))
        private _ERC1155TokenIDListingIndexesStatus;

    // lister's listing indexs: ERC1155 contract address => Token ID => owner address => indexes[]
    mapping(address => mapping(uint256 => mapping(address => uint256[])))
        private _ERC1155TokenIDListingIndexesByOwner;

    // lister's listing indexs Status: ERC1155 contract address => Token ID => owner address => indexes => bool
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => bool))))
        private _ERC1155TokenIDListingIndexesByOwnerStatus;

    ///////////////////////////
    ////    constructor    ////
    ///////////////////////////

    constructor() {
        _owner = msg.sender;
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only Owner
    modifier onlyOwner() {
        // require sender be the owner address
        require(
            msg.sender == _owner,
            "SegMint Exchange: Sender is not the Owner address!"
        );
        _;
    }

    // only SegMint Exchange DB Admin
    modifier onlySegMintExchangeDBAdmin() {
        // require sender be the SegMint Exchange DB Admin address
        require(
            msg.sender == _SegMintExchangeDBAdmin || msg.sender == _SegmintKeyGenerator,
            "SegMint Exchange: Sender is not the SegMint Exchange DB Admin address!"
        );
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_, string memory accountName_) {
        // require account not be the zero address
        require(
            account_ != address(0),
            string.concat(
                "SegMint Exchange: ",
                accountName_,
                " cannot be the zero address!"
            )
        );
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    /* Initialization */

    // set SegMint Exchange DB Admin
    function setSegMintExchangeDBAdmin(address SegMintExchangeAddress_)
        public
        onlyOwner
        notNullAddress(
            SegMintExchangeAddress_,
            "SegMint Exchange  Address"
        )
    {
        _SegMintExchangeDBAdmin = SegMintExchangeAddress_;
    }

    // set SegMint Key Generator
    function setSegMintKeyGenerator(address SegmintKeyGenerator_)
        public
        onlyOwner
        notNullAddress(
            SegmintKeyGenerator_,
            "SegMint Key Generator Address"
        )
    {
        _SegmintKeyGenerator = SegmintKeyGenerator_;
    }

    // set SegMint ERC1155
    function setSegMintERC1155Address(address SegMintERC1155ContractAddress_)
        public
        onlyOwner
        notNullAddress(
            SegMintERC1155ContractAddress_,
            "SegMint ERC1155 Address"
        )
    {
        _SegMintERC1155ContractAddress = SegMintERC1155ContractAddress_;
    }

    // set SegMint ERC1155
    function setSegMintERC1155DBAddress(
        address SegMintERC1155DBContractAddress_
    )
        public
        onlyOwner
        notNullAddress(
            SegMintERC1155DBContractAddress_,
            "SegMint ERC1155 DB Address"
        )
    {
        _SegMintERC1155DBContractAddress = SegMintERC1155DBContractAddress_;
    }

    // set SegMint KYC
    function setSegMintKYCAddress(address SegMintKYCContractAddress_)
        public
        onlyOwner
        notNullAddress(SegMintKYCContractAddress_, "SegMint KYC Address")
    {
        _SegMintKYCContractAddress = SegMintKYCContractAddress_;
    }

    /* Locking And Fractionalization Info */

    // create a locking and fractionalization info
    function createLockingAndFractionalizationInfo(
        lockingAndFractionalizingNFTInfo memory INFO
    ) public onlySegMintExchangeDBAdmin {
        _lockingAndFractionalizingNFTInfo[
            _lockAndFractionalizationIndex
        ] = INFO;
    }

    // add NFT Contract address to _lockedNFTContracts if already not in the array
    function addAddressToLockedNFTContracts(address newNFTContractAddress_)
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(newNFTContractAddress_, "NFT Contract Address")
    {
        _addAddressToLockedNFTContracts(newNFTContractAddress_);
    }

    // remove NFT contract address from _lockedNFTContracts if alreay in the array
    function removeAddressFromLockedNFTContracts(
        address NFTContractAddressToRemove_
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(NFTContractAddressToRemove_, "NFT Contract Address")
    {
        _removeAddressFromLockedNFTContracts(NFTContractAddressToRemove_);
    }

    // add NFT Token ID to _lockedNFTTokenIDs if already not in the array
    function addNFTTokenIDToLockedNFTTokenIDs(
        address NFTContractAddress_,
        uint256 NFTTokenID_
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(NFTContractAddress_, "NFT Contract Address")
    {
        _addNFTTokenIDToLockedNFTTokenIDs(NFTContractAddress_, NFTTokenID_);
    }

    // remove NFT Token ID from _lockedNFTTokenIDs if already in the array
    function removeNFTTokenIDFromLockedNFTTokenIDs(
        address NFTContractAddress_,
        uint256 NFTTokenID_
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(NFTContractAddress_, "NFT Contract Address")
    {
        _removeNFTTokenIDFromLockedNFTTokenIDs(
            NFTContractAddress_,
            NFTTokenID_
        );
    }

    // add NFT Contract Address to _lockedNFTContractsOfOwner if already not in the array
    function addAddressToLockedNFTContractsOfOwner(
        address NFTOwnerAddress_,
        address newNFTContracAddress_
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(NFTOwnerAddress_, "NFT Owner Address")
        notNullAddress(newNFTContracAddress_, "NFT Contract Address")
    {
        _addAddressToLockedNFTContractsOfOwner(
            NFTOwnerAddress_,
            newNFTContracAddress_
        );
    }

    // remove NFT contract address from _lockedNFTContractsOfOwner if alreay in the array
    function removeAddressFromLockedNFTContractsOfOwner(
        address NFTOwnerAddress_,
        address NFTContractAddressToRemove_
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(NFTOwnerAddress_, "NFT Owner Address")
        notNullAddress(NFTContractAddressToRemove_, "NFT Contract Address")
    {
        _removeAddressFromLockedNFTContractsOfOwner(
            NFTOwnerAddress_,
            NFTContractAddressToRemove_
        );
    }

    // add NFT Token ID to _lockedNFTContractTokenIDsOfOwner if already not in the array
    function addNFTTokenIDToLockedNFTContractTokenIDsOfOwner(
        address NFTOwnerAddress_,
        address NFTContractAddress_,
        uint256 NFTTokenID_
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(NFTOwnerAddress_, "NFT Owner Address")
        notNullAddress(NFTContractAddress_, "NFT Contract Address")
    {
        _addNFTTokenIDToLockedNFTContractTokenIDsOfOwner(
            NFTOwnerAddress_,
            NFTContractAddress_,
            NFTTokenID_
        );
    }

    // remove NFT Token ID to _lockedNFTContractTokenIDsOfOwner if already in the array
    function removeNFTFromkenIDToLockedNFTContractTokenIDsOfOwner(
        address NFTOwnerAddress_,
        address NFTContractAddress_,
        uint256 NFTTokenID_
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(NFTOwnerAddress_, "NFT Owner Address")
        notNullAddress(NFTContractAddress_, "NFT Contract Address")
    {
        _removeNFTFromkenIDToLockedNFTContractTokenIDsOfOwner(
            NFTOwnerAddress_,
            NFTContractAddress_,
            NFTTokenID_
        );
    }

    // update locking and fractionalization info after reclaiming NFt
    function updateLockingAndFractionalizationByReclaiming(
        uint256 lockAndFractionalizationIndex_
    ) public onlySegMintExchangeDBAdmin {
        _updateLockingAndFractionalizationByReclaiming(
            lockAndFractionalizationIndex_
        );
    }

    /* Listing and Unlisting */

    // create listing info
    function createListingInfo(ListingInfo memory INFO)
        public
        onlySegMintExchangeDBAdmin
    {
        _listingsInfo[_listingIndex] = INFO;
    }

    // delist all listings of a ERC1155 Token ID
    function delistAllListingERC1155TokenID(
        address NFTContractAddress_,
        uint256 NFTTokenID_
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(NFTContractAddress_, "NFT Contract Address")
    {
        _delistAllListingERC1155TokenID(NFTContractAddress_, NFTTokenID_);
    }

    // add ERC1155 Contract address to _listedERC1155Contracts if already not in the array
    function addAddressToListedERC1155Contracts(
        address newERC1155ContractAddress_
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(newERC1155ContractAddress_, "ERC1155 Contract Address")
    {
        _addAddressToListedERC1155Contracts(newERC1155ContractAddress_);
    }

    // add ERC1155 Token ID to _listedERC1155TokenIDs if already not in the array
    function addToListedERC1155TokenIDs(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(ERC1155ContractAddress_, "ERC1155 Contract Address")
    {
        _addToListedERC1155TokenIDs(ERC1155ContractAddress_, ERC1155TokenID_);
    }

    // remove ERC1155 Token ID from _listedERC1155TokenIDs if already in the array
    function removeFromListedERC1155TokenIDs(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(ERC1155ContractAddress_, "ERC1155 Contract Address")
    {
        _removeFromListedERC1155TokenIDs(
            ERC1155ContractAddress_,
            ERC1155TokenID_
        );
    }

    // add ERC1155TokenOwnerAddress to _listersOfERC11555TokenID
    function addListerToListersOfERC155TokenID(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_,
        address lister_
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(ERC1155ContractAddress_, "ERC1155 Contract Address")
        notNullAddress(lister_, "Lister Address")
    {
        _addListerToListersOfERC155TokenID(
            ERC1155ContractAddress_,
            ERC1155TokenID_,
            lister_
        );
    }

    // remove ERC1155TokenOwnerAddress from _listersOfERC11555TokenID
    function removeListerFromListersOfERC155TokenID(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_,
        address lister_
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(ERC1155ContractAddress_, "ERC1155 Contract Address")
        notNullAddress(lister_, "Lister Address")
    {
        _removeListerFromListersOfERC155TokenID(
            ERC1155ContractAddress_,
            ERC1155TokenID_,
            lister_
        );
    }

    // add listing index to _ERC1155TokenIDListingIndexes
    function addListingIndexToERC1155TokenIDListingIndexes(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_,
        uint256 toAddListingIndex
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(ERC1155ContractAddress_, "ERC1155 Contract Address")
    {
        _addListingIndexToERC1155TokenIDListingIndexes(
            ERC1155ContractAddress_,
            ERC1155TokenID_,
            toAddListingIndex
        );
    }

    // remove listing index from _ERC1155TokenIDListingIndexes
    function removeListingIndexFromERC1155TokenIDListingIndexes(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_,
        uint256 toRemoveListingIndex
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(ERC1155ContractAddress_, "ERC1155 Contract Address")
    {
        _removeListingIndexFromERC1155TokenIDListingIndexes(
            ERC1155ContractAddress_,
            ERC1155TokenID_,
            toRemoveListingIndex
        );
    }

    // add listing Index to _ERC1155TokenIDListingIndexesByOwner
    function addListingIndexToERC1155TokenIDListingIndexesByOwner(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_,
        address ERC1155TokenOwnerAddress_,
        uint256 toAddListingIndex
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(ERC1155ContractAddress_, "ERC1155 Contract Address")
        notNullAddress(ERC1155TokenOwnerAddress_, "ERC1155 Owner Address")
    {
        _addListingIndexToERC1155TokenIDListingIndexesByOwne(
            ERC1155ContractAddress_,
            ERC1155TokenID_,
            ERC1155TokenOwnerAddress_,
            toAddListingIndex
        );
    }

    // remove listing index from _ERC1155TokenIDListingIndexesByOwner
    function removeListingIndexFromERC1155TokenIDListingIndexesByOwner(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_,
        address ERC1155TokenOwnerAddress_,
        uint256 toRemoveListingIndex
    )
        public
        onlySegMintExchangeDBAdmin
        notNullAddress(ERC1155ContractAddress_, "ERC1155 Contract Address")
        notNullAddress(ERC1155TokenOwnerAddress_, "ERC1155 Owner Address")
    {
        _removeListingIndexFromERC1155TokenIDListingIndexesByOwner(
            ERC1155ContractAddress_,
            ERC1155TokenID_,
            ERC1155TokenOwnerAddress_,
            toRemoveListingIndex
        );
    }

    function addLockAndFractionalizationIndex(
        address NFTContractAddress_,
        uint256 NFTTokenID_
    ) public onlySegMintExchangeDBAdmin {
        _NFTLockingAndFractionalizationIndex[NFTContractAddress_][
            NFTTokenID_
        ] = _lockAndFractionalizationIndex;
    }

    // increment lock and fractionalization index
    function incrementLockAndFractionalizationIndex()
        public
        onlySegMintExchangeDBAdmin
    {
        _lockAndFractionalizationIndex++;
    }

    // increment listingindex
    function incrementListingIndex() public onlySegMintExchangeDBAdmin {
        _listingIndex++;
    }

    // update isFractionalized
    function updateIsFractionalizedInLockingAndFractionalizationNFTInfo(
        uint256 lockAndFractionalizationIndex_,
        bool status_
    ) public onlySegMintExchangeDBAdmin {
        _lockingAndFractionalizingNFTInfo[lockAndFractionalizationIndex_]
            .isFractionalized = status_;
    }

    // update ERC1155TokenID
    function updateERC1155TokenIDInLockingAndFractionalizationNFTInfo(
        uint256 lockAndFractionalizationIndex_,
        uint256 FractionalTokenId
    ) public onlySegMintExchangeDBAdmin {
        _lockingAndFractionalizingNFTInfo[lockAndFractionalizationIndex_]
            .ERC1155TokenID = FractionalTokenId;
    }

    // update totalFractions
    function updateTotalFractionsInLockingAndFractionalizationNFTInfo(
        uint256 lockAndFractionalizationIndex_,
        uint256 totalFractions_
    ) public onlySegMintExchangeDBAdmin {
        _lockingAndFractionalizingNFTInfo[lockAndFractionalizationIndex_]
            .totalFractions = totalFractions_;
    }

    // update fractionalizationTimestamp
    function updateFractionalizationTimestampInLockingAndFractionalizationNFTInfo(
        uint256 lockAndFractionalizationIndex_
    ) public onlySegMintExchangeDBAdmin {
        _lockingAndFractionalizingNFTInfo[lockAndFractionalizationIndex_]
            .fractionalizationTimestamp = block.timestamp;
    }

    // update fractionalizationOption
    function updateFractionalizationOptionInLockingAndFractionalizationNFTInfo(
        uint256 lockAndFractionalizationIndex_,
        string memory fractionalizationOption_
    ) public onlySegMintExchangeDBAdmin {
        _lockingAndFractionalizingNFTInfo[lockAndFractionalizationIndex_]
            .fractionalizationOption = fractionalizationOption_;
    }

    // update buyoutPricePerFraction
    function updateBuyoutPricePerFractionInLockingAndFractionalizationNFTInfo(
        uint256 lockAndFractionalizationIndex_,
        uint256 buyoutPricePerFraction_
    ) public onlySegMintExchangeDBAdmin {
        _lockingAndFractionalizingNFTInfo[lockAndFractionalizationIndex_]
            .buyoutPricePerFraction = buyoutPricePerFraction_;
    }

    // update reservePricePerFraction
    function updateReservePricePerFractionInLockingAndFractionalizationNFTInfo(
        uint256 lockAndFractionalizationIndex_,
        uint256 reservePricePerFraction_
    ) public onlySegMintExchangeDBAdmin {
        _lockingAndFractionalizingNFTInfo[lockAndFractionalizationIndex_]
            .reservePricePerFraction = reservePricePerFraction_;
    }

    // update isListed
    function updateIsListedInLockingAndFractionalizationNFTInfo(
        uint256 lockAndFractionalizationIndex_,
        bool status_
    ) public onlySegMintExchangeDBAdmin {
        _lockingAndFractionalizingNFTInfo[lockAndFractionalizationIndex_]
            .isListed = status_;
    }

    // update price per fraction
    function updatePricePerFractionInListingsInfo(
        uint256 listingIndex_,
        uint256 pricePerFraction_
    ) public onlySegMintExchangeDBAdmin {
        _listingsInfo[listingIndex_].pricePerFraction = pricePerFraction_;
    }

    // update the lastUpdateTimestamp
    function updateLastUpdateTimestampInListingsInfo(uint256 listingIndex_)
        public
        onlySegMintExchangeDBAdmin
    {
        _listingsInfo[listingIndex_].lastUpdateTimestamp = block.timestamp;
    }

    // update listed amount in listing info
    function updateAmountInListingsInfo(uint256 listingIndex_, uint256 amount)
        public
        onlySegMintExchangeDBAdmin
    {
        _listingsInfo[listingIndex_].amount = amount;
    }

    // updates the delist timestamp in listing info
    function updateDelistingTimestampInListingsInfo(uint256 listingIndex_)
        public
        onlySegMintExchangeDBAdmin
    {
        _listingsInfo[listingIndex_].delistingTimestamp = block.timestamp;
    }

    /* Getters */

    // get SegMint Exchange DB Admin
    function getSegMintExchangeDBAdmin() public view returns (address) {
        return _SegMintExchangeDBAdmin;
    }

     // get SegMint Key Generator
    function getSegmintKeyGenerator() public view returns (address) {
        return _SegmintKeyGenerator;
    }

    // get SegMintERC1155 address
    function getSegMintERC1155Address() public view returns (address) {
        return _SegMintERC1155ContractAddress;
    }

    // get SegMintERC1155DB address
    function getSegMintERC1155DBAddress() public view returns (address) {
        return _SegMintERC1155DBContractAddress;
    }

    // get contract version
    function getContractVersion() public view returns (uint256) {
        // return version
        return _contractVersion;
    }

    // get SegMint KYC
    function getSegMintKYCAddress() public view returns (address) {
        // return address
        return _SegMintKYCContractAddress;
    }

    /* Locking and Fractionalizing NFT Info */

    // get locking and fractionalizing NFT info
    function getLockingAndFractionalizingNFTInfo(
        uint256 lockAndFractionalizationIndex_
    ) public view returns (lockingAndFractionalizingNFTInfo memory) {
        return
            _lockingAndFractionalizingNFTInfo[lockAndFractionalizationIndex_];
    }

    // get lock and fractioalizing index from NFT contract address and NFT Token ID
    function getLockingAndFractionalizingIndex(
        address NFTContractAddress_,
        uint256 NFTTokenID_
    ) public view returns (uint256) {
        return
            _NFTLockingAndFractionalizationIndex[NFTContractAddress_][
                NFTTokenID_
            ];
    }

    // get all NFT Contract Addresses locked
    function getLockedNFTContracts() public view returns (address[] memory) {
        return _lockedNFTContracts;
    }

    // get all NFT Token IDs locked for a specific NFT Contract Address
    function getLockedNFTTokenIDs(address NFTContractAddress_)
        public
        view
        returns (uint256[] memory)
    {
        return _lockedNFTTokenIDs[NFTContractAddress_];
    }

    // get all NFT Contract Addresses locked by NFT Owner address
    function getLockedNFTContractsOFOwner(address NFTOwnerAddress_)
        public
        view
        returns (address[] memory)
    {
        return _lockedNFTContractsOfOwner[NFTOwnerAddress_];
    }

    // get all NFT Token IDs of an NFT Contract by Owner
    function getLockedNFTContractTokenIDsOfOwner(
        address NFTOwnerAddress_,
        address NFTContractAddress_
    ) public view returns (uint256[] memory) {
        return
            _lockedNFTContractTokenIDsOfOwner[NFTOwnerAddress_][
                NFTContractAddress_
            ];
    }

    // get SegMintation option
    function getFractionalizationOption(uint256 lockAndFractionalizationIndex_)
        public
        view
        returns (string memory)
    {
        return
            _lockingAndFractionalizingNFTInfo[lockAndFractionalizationIndex_]
                .fractionalizationOption;
    }

    // get _lockAndFractionalizationIndex
    function getLatestLockAndFractionalizationIndex()
        public
        view
        returns (uint256)
    {
        return _lockAndFractionalizationIndex;
    }

    /* Listing Fractions Info */

    // get listing index
    function getListingIndex() public view returns (uint256) {
        return _listingIndex;
    }

    // get lister address
    function getLister(uint256 listingIndex_) public view returns (address) {
        return _listingsInfo[listingIndex_].ERC1155TokenOwnerAddress;
    }

    // get listed ERC1155 contract addresses
    function getListedContractAddresses()
        public
        view
        returns (address[] memory)
    {
        // return addresses
        return _listedERC1155Contracts;
    }

    // get listed Token IDs of a specific ERC1155 Contract
    function getListedTokenIDs(address ERC1155ContractAddress_)
        public
        view
        returns (uint256[] memory)
    {
        // return token IDs
        return _listedERC1155TokenIDs[ERC1155ContractAddress_];
    }

    // get all listers of an ERC1155 Contract for a specific token ID
    function getListers(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_
    ) public view returns (address[] memory) {
        // return listers addresses
        return
            _listersOfERC11555TokenID[ERC1155ContractAddress_][ERC1155TokenID_];
    }

    // get ListingInfo
    function getListingInfoByListingIndex(uint256 listingIndex)
        public
        view
        returns (ListingInfo memory)
    {
        // return listing info
        return _listingsInfo[listingIndex];
    }

    // get all listings info
    function getAllListingsInfo(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_,
        address lister_
    ) public view returns (ListingInfo[] memory) {
        // get array of listing ids of ERC1155ContractAddress_=>ERC1155TokenID_=>lister_
        uint256[] memory listingIds = _ERC1155TokenIDListingIndexesByOwner[
            ERC1155ContractAddress_
        ][ERC1155TokenID_][lister_];

        // length of the array
        uint256 length = listingIds.length;

        // initializing empty array
        ListingInfo[] memory listings = new ListingInfo[](length);

        // fetching info of each listing
        for (uint256 i = 0; i < length; i++) {
            listings[i] = getListingInfoByListingIndex(listingIds[i]);
        }

        // return the array of listing
        return listings;
    }

    // returns whether wallet has been added in the _listersOfERC11555TokenID for ERC1155 Contract and ERC1155 Token Id
    function isLister(
        address wallet,
        address ERC1155Contract_,
        uint256 ERC1155TokenID_
    ) public view returns (bool) {
        address[] memory listers = _listersOfERC11555TokenID[ERC1155Contract_][
            ERC1155TokenID_
        ];
        for (uint256 i = 0; i < listers.length; i++) {
            if (listers[i] == wallet) {
                return true;
            }
        }
        return false;
    }

    // returns whether ERC1155 contract has been listed or not
    function isERC1155Listed(address ERC1155Contract_)
        public
        view
        returns (bool)
    {
        return _listedERC1155ContractsStatus[ERC1155Contract_];
    }

    // get ERC1155 Token IDs listing indexed by owner
    function getERC1155TokenIDListingIndexesByOwner(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_,
        address lister_
    ) public view returns (uint256[] memory) {
        return
            _ERC1155TokenIDListingIndexesByOwner[ERC1155ContractAddress_][
                ERC1155TokenID_
            ][lister_];
    }

    // get _ERC1155TokenIDListingIndexes
    function getERC1155TokenIDListingIndexes(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_
    ) public view returns (uint256[] memory) {
        return
            _ERC1155TokenIDListingIndexes[ERC1155ContractAddress_][
                ERC1155TokenID_
            ];
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    /* Locking and Fractionalization */

    // add NFT Contract address to _lockedNFTContracts if already not in the array
    function _addAddressToLockedNFTContracts(address newNFTContractAddress_)
        internal
    {
        if (!_lockedNFTContractsStatus[newNFTContractAddress_]) {
            _lockedNFTContracts.push(newNFTContractAddress_);
            _lockedNFTContractsStatus[newNFTContractAddress_] = true;
        }
    }

    // remove NFT contract address from _lockedNFTContracts if alreay in the array
    function _removeAddressFromLockedNFTContracts(
        address NFTContractAddressToRemove_
    ) internal {
        if (_lockedNFTContractsStatus[NFTContractAddressToRemove_]) {
            for (uint256 i = 0; i < _lockedNFTContracts.length; i++) {
                if (_lockedNFTContracts[i] == NFTContractAddressToRemove_) {
                    _lockedNFTContracts[i] = _lockedNFTContracts[
                        _lockedNFTContracts.length - 1
                    ];
                    _lockedNFTContracts.pop();
                    _lockedNFTContractsStatus[
                        NFTContractAddressToRemove_
                    ] = false;
                    break;
                }
            }
        }
    }

    // add NFT Token ID to _lockedNFTTokenIDs if already not in the array
    function _addNFTTokenIDToLockedNFTTokenIDs(
        address NFTContractAddress_,
        uint256 NFTTokenID_
    ) internal {
        if (!_lockedNFTTokenIDsStatus[NFTContractAddress_][NFTTokenID_]) {
            _lockedNFTTokenIDs[NFTContractAddress_].push(NFTTokenID_);
            _lockedNFTTokenIDsStatus[NFTContractAddress_][NFTTokenID_] = true;
        }
    }

    // remove NFT Token ID from _lockedNFTTokenIDs if already in the array
    function _removeNFTTokenIDFromLockedNFTTokenIDs(
        address NFTContractAddress_,
        uint256 NFTTokenID_
    ) internal {
        if (_lockedNFTTokenIDsStatus[NFTContractAddress_][NFTTokenID_]) {
            for (
                uint256 i = 0;
                i < _lockedNFTTokenIDs[NFTContractAddress_].length;
                i++
            ) {
                if (_lockedNFTTokenIDs[NFTContractAddress_][i] == NFTTokenID_) {
                    _lockedNFTTokenIDs[NFTContractAddress_][
                        i
                    ] = _lockedNFTTokenIDs[NFTContractAddress_][
                        _lockedNFTTokenIDs[NFTContractAddress_].length - 1
                    ];
                    _lockedNFTTokenIDs[NFTContractAddress_].pop();
                    // update status
                    _lockedNFTTokenIDsStatus[NFTContractAddress_][
                        NFTTokenID_
                    ] = false;
                    break;
                }
            }
        }
    }

    // add NFT Contract Address to _lockedNFTContractsOfOwner if already not in the array
    function _addAddressToLockedNFTContractsOfOwner(
        address NFTOwnerAddress_,
        address newNFTContracAddress_
    ) internal {
        if (
            !_lockedNFTContractsOfOwnerStatus[NFTOwnerAddress_][
                newNFTContracAddress_
            ]
        ) {
            _lockedNFTContractsOfOwner[NFTOwnerAddress_].push(
                newNFTContracAddress_
            );
            _lockedNFTContractsOfOwnerStatus[NFTOwnerAddress_][
                newNFTContracAddress_
            ] = true;
        }
    }

    // remove NFT contract address from _lockedNFTContractsOfOwner if alreay in the array
    function _removeAddressFromLockedNFTContractsOfOwner(
        address NFTOwnerAddress_,
        address NFTContractAddressToRemove_
    ) internal {
        if (
            _lockedNFTContractsOfOwnerStatus[NFTOwnerAddress_][
                NFTContractAddressToRemove_
            ]
        ) {
            for (
                uint256 i = 0;
                i < _lockedNFTContractsOfOwner[NFTOwnerAddress_].length;
                i++
            ) {
                if (
                    _lockedNFTContractsOfOwner[NFTOwnerAddress_][i] ==
                    NFTContractAddressToRemove_
                ) {
                    _lockedNFTContractsOfOwner[NFTOwnerAddress_][
                        i
                    ] = _lockedNFTContractsOfOwner[NFTOwnerAddress_][
                        _lockedNFTContractsOfOwner[NFTOwnerAddress_].length - 1
                    ];
                    _lockedNFTContractsOfOwner[NFTOwnerAddress_].pop();
                    _lockedNFTContractsOfOwnerStatus[NFTOwnerAddress_][
                        NFTContractAddressToRemove_
                    ] = false;
                    break;
                }
            }
        }
    }

    // add NFT Token ID to _lockedNFTContractTokenIDsOfOwner if already not in the array
    function _addNFTTokenIDToLockedNFTContractTokenIDsOfOwner(
        address NFTOwnerAddress_,
        address NFTContractAddress_,
        uint256 NFTTokenID_
    ) internal {
        if (
            !_lockedNFTContractTokenIDsOfOwnerStatus[NFTOwnerAddress_][
                NFTContractAddress_
            ][NFTTokenID_]
        ) {
            _lockedNFTContractTokenIDsOfOwner[NFTOwnerAddress_][
                NFTContractAddress_
            ].push(NFTTokenID_);
            _lockedNFTContractTokenIDsOfOwnerStatus[NFTOwnerAddress_][
                NFTContractAddress_
            ][NFTTokenID_] = true;
        }
    }

    // remove NFT Token ID to _lockedNFTContractTokenIDsOfOwner if already in the array
    function _removeNFTFromkenIDToLockedNFTContractTokenIDsOfOwner(
        address NFTOwnerAddress_,
        address NFTContractAddress_,
        uint256 NFTTokenID_
    ) internal {
        if (
            _lockedNFTContractTokenIDsOfOwnerStatus[NFTOwnerAddress_][
                NFTContractAddress_
            ][NFTTokenID_]
        ) {
            for (
                uint256 i = 0;
                i <
                _lockedNFTContractTokenIDsOfOwner[NFTOwnerAddress_][
                    NFTContractAddress_
                ].length;
                i++
            ) {
                if (
                    _lockedNFTContractTokenIDsOfOwner[NFTOwnerAddress_][
                        NFTContractAddress_
                    ][i] == NFTTokenID_
                ) {
                    _lockedNFTContractTokenIDsOfOwner[NFTOwnerAddress_][
                        NFTContractAddress_
                    ][i] = _lockedNFTContractTokenIDsOfOwner[NFTOwnerAddress_][
                        NFTContractAddress_
                    ][
                        _lockedNFTContractTokenIDsOfOwner[NFTOwnerAddress_][
                            NFTContractAddress_
                        ].length - 1
                    ];
                    _lockedNFTContractTokenIDsOfOwner[NFTOwnerAddress_][
                        NFTContractAddress_
                    ].pop();
                    _lockedNFTContractTokenIDsOfOwnerStatus[NFTOwnerAddress_][
                        NFTContractAddress_
                    ][NFTTokenID_] = false;
                    break;
                }
            }
        }
    }

    // update locking and fractionalization info after reclaiming NFt
    function _updateLockingAndFractionalizationByReclaiming(
        uint256 lockAndFractionalizationIndex_
    ) internal {
        // NFT Contract address
        address NFTContractAddress = _lockingAndFractionalizingNFTInfo[
            lockAndFractionalizationIndex_
        ].NFTContractAddress;

        // NFT Token ID
        uint256 NFTTokenID = _lockingAndFractionalizingNFTInfo[
            lockAndFractionalizationIndex_
        ].NFTTokenID;

        // NFT Owner Address
        address NFTOwnerAddress = _lockingAndFractionalizingNFTInfo[
            lockAndFractionalizationIndex_
        ].NFTOwnerAddress;

        // update _lockedNFTContracts and _lockedNFTContractsStatus
        _removeAddressFromLockedNFTContracts(NFTContractAddress);

        // update _lockedNFTTokenIDsStatus
        _removeNFTTokenIDFromLockedNFTTokenIDs(NFTContractAddress, NFTTokenID);

        // update _lockedNFTContractsOfOwner
        // update _lockedNFTContractsOfOwnerStatus
        _removeAddressFromLockedNFTContractsOfOwner(
            NFTOwnerAddress,
            NFTContractAddress
        );

        // update _lockedNFTContractTokenIDsOfOwner and _lockedNFTContractTokenIDsOfOwnerStatus
        _removeNFTFromkenIDToLockedNFTContractTokenIDsOfOwner(
            NFTOwnerAddress,
            NFTContractAddress,
            NFTTokenID
        );

        // update _lockingAndFractionalizingNFTInfo
        _lockingAndFractionalizingNFTInfo[lockAndFractionalizationIndex_]
            .isLocked = false;
        _lockingAndFractionalizingNFTInfo[lockAndFractionalizationIndex_]
            .unlockTimestamp = block.timestamp;
        _lockingAndFractionalizingNFTInfo[lockAndFractionalizationIndex_]
            .isListed = false;
    }

    /* Listing and Unlisting */

    // delist all listings of a ERC1155 Token ID
    function _delistAllListingERC1155TokenID(
        address NFTContractAddress_,
        uint256 NFTTokenID_
    ) internal {
        // get lock and fractionalization index
        uint256 lockAndFractionalizationIndex = _NFTLockingAndFractionalizationIndex[
                NFTContractAddress_
            ][NFTTokenID_];

        // get ERC1155 Token ID
        uint256 ERC1155TokenID = _lockingAndFractionalizingNFTInfo[
            lockAndFractionalizationIndex
        ].ERC1155TokenID;

        // remove ERC1155 Token ID from _listedERC1155TokenIDs and update _listedERC1155TokenIDsStatus
        _removeFromListedERC1155TokenIDs(
            _SegMintERC1155ContractAddress,
            ERC1155TokenID
        );

        // update _listersOfERC11555TokenID
        address[] memory listers = _listersOfERC11555TokenID[
            _SegMintERC1155ContractAddress
        ][ERC1155TokenID];

        // update _listingsInfo, _ERC1155TokenIDListingIndexes, _ERC1155TokenIDListingIndexesByOwner, _ERC1155TokenIDListingIndexes and _listersOfERC11555TokenIDStatus
        if (listers.length > 0) {
            for (uint256 i = 0; i < listers.length; i++) {
                // all listing indexes of a lister
                uint256[]
                    memory listingIndexesOfOwner = _ERC1155TokenIDListingIndexesByOwner[
                        _SegMintERC1155ContractAddress
                    ][ERC1155TokenID][listers[i]];

                // update _listingsInfo, _ERC1155TokenIDListingIndexes and _ERC1155TokenIDListingIndexesByOwner
                if (listingIndexesOfOwner.length > 0) {
                    // update _listingsInfo and _ERC1155TokenIDListingIndexes
                    for (uint256 j = 0; j < listingIndexesOfOwner.length; j++) {
                        // some amount is left on the market.
                        _listingsInfo[listingIndexesOfOwner[j]].amount = 0;
                        _listingsInfo[listingIndexesOfOwner[j]]
                            .lastUpdateTimestamp = block.timestamp;
                        _listingsInfo[listingIndexesOfOwner[j]]
                            .lastUpdateTimestamp = block.timestamp;

                        // remove listing index from _ERC1155TokenIDListingIndexes and _listersOfERC11555TokenIDStatus
                        _removeListingIndexFromERC1155TokenIDListingIndexes(
                            _SegMintERC1155ContractAddress,
                            ERC1155TokenID,
                            listingIndexesOfOwner[j]
                        );
                    }

                    // remove listing indexes from _ERC1155TokenIDListingIndexesByOwner
                    delete _ERC1155TokenIDListingIndexesByOwner[
                        _SegMintERC1155ContractAddress
                    ][ERC1155TokenID][listers[i]];
                }

                // update _listersOfERC11555TokenIDStatus
                _listersOfERC11555TokenIDStatus[_SegMintERC1155ContractAddress][
                    ERC1155TokenID
                ][listers[i]] = false;
            }
        }

        // delete all listers from _listersOfERC11555TokenID
        delete _listersOfERC11555TokenID[_SegMintERC1155ContractAddress][
            ERC1155TokenID
        ];
    }

    // add ERC1155 Contract address to _listedERC1155Contracts if already not in the array
    function _addAddressToListedERC1155Contracts(
        address newERC1155ContractAddress_
    ) internal {
        if (!_listedERC1155ContractsStatus[newERC1155ContractAddress_]) {
            _listedERC1155Contracts.push(newERC1155ContractAddress_);
            _listedERC1155ContractsStatus[newERC1155ContractAddress_] = true;
        }
    }

    // add ERC1155 Token ID to _listedERC1155TokenIDs if already not in the array
    function _addToListedERC1155TokenIDs(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_
    ) internal {
        if (
            !_listedERC1155TokenIDsStatus[ERC1155ContractAddress_][
                ERC1155TokenID_
            ]
        ) {
            _listedERC1155TokenIDs[ERC1155ContractAddress_].push(
                ERC1155TokenID_
            );
            _listedERC1155TokenIDsStatus[ERC1155ContractAddress_][
                ERC1155TokenID_
            ] = true;
        }
    }

    // remove ERC1155 Token ID from _listedERC1155TokenIDs if already in the array
    function _removeFromListedERC1155TokenIDs(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_
    ) internal {
        if (
            _listedERC1155TokenIDsStatus[ERC1155ContractAddress_][
                ERC1155TokenID_
            ]
        ) {
            for (
                uint256 i = 0;
                i < _listedERC1155TokenIDs[ERC1155ContractAddress_].length;
                i++
            ) {
                if (
                    _listedERC1155TokenIDs[ERC1155ContractAddress_][i] ==
                    ERC1155TokenID_
                ) {
                    _listedERC1155TokenIDs[ERC1155ContractAddress_][
                        i
                    ] = _listedERC1155TokenIDs[ERC1155ContractAddress_][
                        _listedERC1155TokenIDs[ERC1155ContractAddress_].length -
                            1
                    ];
                    _listedERC1155TokenIDs[ERC1155ContractAddress_].pop();
                    // update status
                    _listedERC1155TokenIDsStatus[ERC1155ContractAddress_][
                        ERC1155TokenID_
                    ] = false;
                    break;
                }
            }
        }
    }

    // add ERC1155TokenOwnerAddress to _listersOfERC11555TokenID
    function _addListerToListersOfERC155TokenID(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_,
        address lister_
    ) internal {
        if (
            !_listersOfERC11555TokenIDStatus[ERC1155ContractAddress_][
                ERC1155TokenID_
            ][lister_]
        ) {
            _listersOfERC11555TokenID[ERC1155ContractAddress_][ERC1155TokenID_]
                .push(lister_);
            _listersOfERC11555TokenIDStatus[ERC1155ContractAddress_][
                ERC1155TokenID_
            ][lister_] = true;
        }
    }

    // remove ERC1155TokenOwnerAddress from _listersOfERC11555TokenID
    function _removeListerFromListersOfERC155TokenID(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_,
        address lister_
    ) internal {
        if (
            _listersOfERC11555TokenIDStatus[ERC1155ContractAddress_][
                ERC1155TokenID_
            ][lister_]
        ) {
            for (
                uint256 i = 0;
                i <
                _listersOfERC11555TokenID[ERC1155ContractAddress_][
                    ERC1155TokenID_
                ].length;
                i++
            ) {
                if (
                    _listersOfERC11555TokenID[ERC1155ContractAddress_][
                        ERC1155TokenID_
                    ][i] == lister_
                ) {
                    _listersOfERC11555TokenID[ERC1155ContractAddress_][
                        ERC1155TokenID_
                    ][i] = _listersOfERC11555TokenID[ERC1155ContractAddress_][
                        ERC1155TokenID_
                    ][
                        _listersOfERC11555TokenID[ERC1155ContractAddress_][
                            ERC1155TokenID_
                        ].length - 1
                    ];
                    _listersOfERC11555TokenID[ERC1155ContractAddress_][
                        ERC1155TokenID_
                    ].pop();
                    // update status
                    _listersOfERC11555TokenIDStatus[ERC1155ContractAddress_][
                        ERC1155TokenID_
                    ][lister_] = false;
                    break;
                }
            }
        }
    }

    // add listing index to _ERC1155TokenIDListingIndexes
    function _addListingIndexToERC1155TokenIDListingIndexes(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_,
        uint256 toAddListingIndex
    ) internal {
        if (
            !_ERC1155TokenIDListingIndexesStatus[ERC1155ContractAddress_][
                ERC1155TokenID_
            ][toAddListingIndex]
        ) {
            _ERC1155TokenIDListingIndexes[ERC1155ContractAddress_][
                ERC1155TokenID_
            ].push(toAddListingIndex);
            _ERC1155TokenIDListingIndexesStatus[ERC1155ContractAddress_][
                ERC1155TokenID_
            ][toAddListingIndex] = true;
        }
    }

    // remove listing index from _ERC1155TokenIDListingIndexes
    function _removeListingIndexFromERC1155TokenIDListingIndexes(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_,
        uint256 toRemoveListingIndex
    ) internal {
        if (
            _ERC1155TokenIDListingIndexesStatus[ERC1155ContractAddress_][
                ERC1155TokenID_
            ][toRemoveListingIndex]
        ) {
            for (
                uint256 i = 0;
                i <
                _ERC1155TokenIDListingIndexes[ERC1155ContractAddress_][
                    ERC1155TokenID_
                ].length;
                i++
            ) {
                if (
                    _ERC1155TokenIDListingIndexes[ERC1155ContractAddress_][
                        ERC1155TokenID_
                    ][i] == toRemoveListingIndex
                ) {
                    _ERC1155TokenIDListingIndexes[ERC1155ContractAddress_][
                        ERC1155TokenID_
                    ][i] = _ERC1155TokenIDListingIndexes[
                        ERC1155ContractAddress_
                    ][ERC1155TokenID_][
                        _ERC1155TokenIDListingIndexes[ERC1155ContractAddress_][
                            ERC1155TokenID_
                        ].length - 1
                    ];
                    _ERC1155TokenIDListingIndexes[ERC1155ContractAddress_][
                        ERC1155TokenID_
                    ].pop();
                    break;
                }
            }
        }
    }

    // add listing Index to _ERC1155TokenIDListingIndexesByOwner
    function _addListingIndexToERC1155TokenIDListingIndexesByOwne(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_,
        address ERC1155TokenOwnerAddress_,
        uint256 toAddListingIndex
    ) internal {
        if (
            !_ERC1155TokenIDListingIndexesByOwnerStatus[
                ERC1155ContractAddress_
            ][ERC1155TokenID_][ERC1155TokenOwnerAddress_][toAddListingIndex]
        ) {
            _ERC1155TokenIDListingIndexesByOwner[ERC1155ContractAddress_][
                ERC1155TokenID_
            ][ERC1155TokenOwnerAddress_].push(toAddListingIndex);
            _ERC1155TokenIDListingIndexesByOwnerStatus[ERC1155ContractAddress_][
                ERC1155TokenID_
            ][ERC1155TokenOwnerAddress_][toAddListingIndex] = true;
        }
    }

    // remove listing index from _ERC1155TokenIDListingIndexesByOwner
    function _removeListingIndexFromERC1155TokenIDListingIndexesByOwner(
        address ERC1155ContractAddress_,
        uint256 ERC1155TokenID_,
        address ERC1155TokenOwnerAddress_,
        uint256 toRemoveListingIndex
    ) internal {
        if (
            _ERC1155TokenIDListingIndexesByOwnerStatus[ERC1155ContractAddress_][
                ERC1155TokenID_
            ][ERC1155TokenOwnerAddress_][toRemoveListingIndex]
        ) {
            for (
                uint256 i = 0;
                i <
                _ERC1155TokenIDListingIndexesByOwner[ERC1155ContractAddress_][
                    ERC1155TokenID_
                ][ERC1155TokenOwnerAddress_].length;
                i++
            ) {
                if (
                    _ERC1155TokenIDListingIndexesByOwner[
                        ERC1155ContractAddress_
                    ][ERC1155TokenID_][ERC1155TokenOwnerAddress_][i] ==
                    toRemoveListingIndex
                ) {
                    _ERC1155TokenIDListingIndexesByOwner[
                        ERC1155ContractAddress_
                    ][ERC1155TokenID_][ERC1155TokenOwnerAddress_][
                        i
                    ] = _ERC1155TokenIDListingIndexesByOwner[
                        ERC1155ContractAddress_
                    ][ERC1155TokenID_][ERC1155TokenOwnerAddress_][
                        _ERC1155TokenIDListingIndexesByOwner[
                            ERC1155ContractAddress_
                        ][ERC1155TokenID_][ERC1155TokenOwnerAddress_].length - 1
                    ];
                    _ERC1155TokenIDListingIndexesByOwner[
                        ERC1155ContractAddress_
                    ][ERC1155TokenID_][ERC1155TokenOwnerAddress_].pop();
                    break;
                }
            }
        }
    }

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////
}

// SegMint Key Generator
contract SegMintKeyGenerator is SegMintExchangeStructs {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // SegMint Exchange Contract Version
    uint256 private _contractVersion = 1;

    // owner address
    address private _owner;

    // SegMint Exchange DB
    address private _SegMintExchangeDBContractAddress;

    // SegMint Exchange DB interface
    SegMintExchangeDB private _SegMintExchangeDB;

    // SegMint ERC1155 Contract Address
    address private _SegMintERC1155ContractAddress;

    // SegMint ERC1155 Contract Interface
    SegMintERC1155Interface private _SegMintERC1155;

    // SegMint ERC1155 DB Contract Address
    address private _SegMintERC1155DBContractAddress;

    // SegMint ERC1155 DB Contract Interface
    SegMintERC1155DBInterface private _SegMintERC1155DB;

    // SegMint KYC Contract Address
    address private _SegMintKYCContractAddress;

    // SegMint KYC Interface
    SegMintKYCContractInterface private _SegMintKYC;

    ///////////////////////////
    ////    constructor    ////
    ///////////////////////////

    constructor(address SegMintExchangeDBAddress_) {
        _owner = msg.sender;
        _SegMintExchangeDB = SegMintExchangeDB(SegMintExchangeDBAddress_);
        _SegMintExchangeDBContractAddress = SegMintExchangeDBAddress_;
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // update owner address
    event setOwnerAddressEvent(
        address indexed OwnerAddress,
        address previousOwnerAddress,
        address indexed newOwnerAddress,
        uint256 indexed timestamp
    );

    // update SegMint Exchange DB event
    event setSegMingExchangeDBContractAddressEvent(
        address indexed OwnerAddress,
        address indexed previousExchangeDBAddress,
        address newSegMintExchangeDBAddress,
        uint256 indexed timestamp
    );

    // set SegMint ERC1155 Contract Address
    event setSegMintERC1155ContractAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintERC1155ContractAddress,
        address indexed newSegMintERC1155ContractAddress,
        uint256 indexed timestamp
    );

    // set SegMint ERC1155 DB Contract Address
    event setSegMintERC1155DBContractAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintERC1155ContractAddress,
        address indexed newSegMintERC1155ContractAddress,
        uint256 indexed timestamp
    );

    // set SegMint KYC Contract Address
    event setSegMintKYCContractAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintKYCContractAddress,
        address indexed newSegMintKYCContractAddress,
        uint256 indexed timestamp
    );

    // NFT Locked
    event lockNFTEvent(
        address indexed Sender, // NFTOwnerAddress
        address NFTCreatorAddress,
        address NFTContractAddress,
        uint256 NFTTokenID_,
        bool isSegMintNFT,
        address lockingContractAddress,
        uint256 indexed timestamp
    );

    // NFT Fractionalized
    event fractionalizeNFTEvent(
        address indexed Sender, // NFTOwnerAddress
        address indexed NFTContractAddress,
        uint256 NFTTokenID,
        uint256 totalFractions,
        uint256 FractionalTokenId,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only Owner
    modifier onlyOwner() {
        // require sender be the owner address
        require(
            msg.sender == _owner,
            "SegMint Exchange: Sender is not the Owner address!"
        );
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_, string memory accountName_) {
        // require account not be the zero address
        require(
            account_ != address(0),
            string.concat(
                "SegMint Exchange: ",
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
            _SegMintKYC.isAuthorizedAddress(msg.sender),
            "SegMint Exchange: Sender is not an authorized account!"
        );
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // set Owner Address
    function setOwnerAddress(address owner_)
        public
        onlyOwner
        notNullAddress(owner_, "Owner Address")
    {
        // previous owner address
        address previousOwnerAddress = _owner;

        // update owner address
        _owner = owner_;

        // emit event
        emit setOwnerAddressEvent(
            msg.sender,
            previousOwnerAddress,
            owner_,
            block.timestamp
        );
    }

    // get owner
    function getOwnerAddress() public view returns (address) {
        return _owner;
    }

    // set SegMint Exchange DB
    function setSegMingExchangeDBContractAddress(
        address SegMintExchangeDBAddress_
    )
        public
        onlyOwner
        notNullAddress(SegMintExchangeDBAddress_, "SegMint Exchange DB")
    {
        // old exchange db address
        address previousExchangeDBAddress = _SegMintExchangeDBContractAddress;

        // update Exchange DB contract address
        _SegMintExchangeDBContractAddress = SegMintExchangeDBAddress_;

        // update interface
        _SegMintExchangeDB = SegMintExchangeDB(SegMintExchangeDBAddress_);

        // emit event
        emit setSegMingExchangeDBContractAddressEvent(
            msg.sender,
            previousExchangeDBAddress,
            SegMintExchangeDBAddress_,
            block.timestamp
        );
    }

    // get SegMint Exchange DB Address
    function getSegMintExchangeDBContractAddress()
        public
        view
        returns (address)
    {
        return _SegMintExchangeDBContractAddress;
    }

    // set _SegMintERC1155ContractAddress
    function setSegMintERC1155ContractAddress(
        address SegMintERC1155ContractAddress_
    )
        public
        onlyOwner
        notNullAddress(
            SegMintERC1155ContractAddress_,
            "SegMint ERC1155 Contract Address"
        )
    {
        // previous address
        address previousSegMintERC1155ContractAddress = _SegMintERC1155ContractAddress;

        // update
        _SegMintERC1155ContractAddress = SegMintERC1155ContractAddress_;

        // update interface
        _SegMintERC1155 = SegMintERC1155Interface(
            SegMintERC1155ContractAddress_
        );

        // emit address
        emit setSegMintERC1155ContractAddressEvent(
            msg.sender,
            previousSegMintERC1155ContractAddress,
            SegMintERC1155ContractAddress_,
            block.timestamp
        );
    }

    // get SegMintERC1155 address
    function getSegMintERC1155ContractAddress() public view returns (address) {
        return _SegMintERC1155ContractAddress;
    }

    // set _SegMintERC1155DBContractAddress
    function setSegMintERC1155DBContractAddress(
        address SegMintERC1155DBContractAddress_
    )
        public
        onlyOwner
        notNullAddress(
            SegMintERC1155DBContractAddress_,
            "SegMint ERC1155 DB Contract"
        )
    {
        // previous address
        address previousSegMintERC1155ContractAddress = _SegMintERC1155DBContractAddress;

        // update
        _SegMintERC1155DBContractAddress = SegMintERC1155DBContractAddress_;

        // update interface
        _SegMintERC1155DB = SegMintERC1155DBInterface(SegMintERC1155DBContractAddress_);

        // emit event
        emit setSegMintERC1155DBContractAddressEvent(
            msg.sender,
            previousSegMintERC1155ContractAddress,
            SegMintERC1155DBContractAddress_,
            block.timestamp
        );
    }

    // get SegMintERC1155DB contract address
    function getSegMintERC1155DBContractAddress()
        public
        view
        returns (address)
    {
        return _SegMintERC1155DBContractAddress;
    }

    // set SegMint KYC Contract Address
    function setSegMintKYCContractAddress(address SegMintKYCContractAddress_)
        public
        onlyOwner
        notNullAddress(
            SegMintKYCContractAddress_,
            "SegMint KYC Contract Address"
        )
    {
        // previous address
        address previousSegMintKYCContractAddress = _SegMintKYCContractAddress;

        // update contract address
        _SegMintKYCContractAddress = SegMintKYCContractAddress_;

        // udpate interface
        _SegMintKYC = SegMintKYCContractInterface(SegMintKYCContractAddress_);

        // emit event
        emit setSegMintKYCContractAddressEvent(
            msg.sender,
            previousSegMintKYCContractAddress,
            SegMintKYCContractAddress_,
            block.timestamp
        );
    }

    // get SegMint KYC Contract Address
    function getSegMintKYCContractAddress() public view returns (address) {
        return _SegMintKYCContractAddress;
    }

    /**********************************/
    /* SegMint Key Generation Process */
    /**********************************/

    // lock ERC721 NFT : NFT owner pays the fees and SegMint Exchange locks the NFT
    function lockNFT(
        address NFTCreatorAddress_,
        address NFTContractAddress_,
        uint256 NFTTokenID_,
        bool isSegMintNFT_,
        address lockingContractAddress_
    )
        public
        notNullAddress(NFTCreatorAddress_, "NFT Creator Address")
        notNullAddress(msg.sender, "NFT Owner Address")
        notNullAddress(NFTContractAddress_, "NFT Contract Address")
        onlyKYCAuthorized
    {
        // Locking the NFT: SegMint NFT or Standard NFT
        if (!isSegMintNFT_) {
            // NFT is standard ERc721 and it should be in locking contract.

            // Standard NFT => there should be a non-zero address for SegMint Locking Contract
            require(
                lockingContractAddress_ != address(0),
                "SegMint Exchange: Locking contract address should not be zero address!"
            );

            // require msg.sender be the NFT owner
            require(
                msg.sender ==
                    address(
                        SegMintNFTLockingContractInterface(
                            lockingContractAddress_
                        ).getOwnerWalletAddress()
                    ),
                "SegMint Exchange: Sender is not the NFT owner!"
            );

            // Locking the NFT
            bool lockingStatus = SegMintNFTLockingContractInterface(
                lockingContractAddress_
            ).fractionerLock(NFTContractAddress_, NFTTokenID_);

            // require locking was successful
            require(
                lockingStatus,
                "SegMint Exchange: Failed to lock NFT in Locking Contract!"
            );
        } else {
            // NFT is a SegMint ERC721
            // require msg.sender be the NFT owner
            require(
                msg.sender ==
                    SegMintERC721ContractInterface(NFTContractAddress_).ownerOf(
                        NFTTokenID_
                    ),
                "SegMint Exchange: Sender is not the NFT owner!"
            );

            // Locking the NFT
            bool lockingStatus = SegMintERC721ContractInterface(
                NFTContractAddress_
            ).fractionerLock(NFTTokenID_);

            // require successful locking status
            require(lockingStatus, "SegMint Exchange: Failed to lock SegMint NFT!");
        }

        // add lock and fractionalization index
        _SegMintExchangeDB.addLockAndFractionalizationIndex(
            NFTContractAddress_,
            NFTTokenID_
        );

        // add locking NFT info to _lockingAndFractionalizingNFTInfo
        _SegMintExchangeDB.createLockingAndFractionalizationInfo(
            lockingAndFractionalizingNFTInfo({
                lockAndFractionalizationIndex: _SegMintExchangeDB
                    .getLockingAndFractionalizingIndex(
                        NFTContractAddress_,
                        NFTTokenID_
                    ),
                NFTCreatorAddress: NFTCreatorAddress_,
                NFTOwnerAddress: msg.sender,
                NFTContractAddress: NFTContractAddress_,
                NFTTokenID: NFTTokenID_,
                isSegMintNFT: isSegMintNFT_,
                lockingContractAddress: lockingContractAddress_,
                lockerAddress: address(this),
                isLocked: true,
                lockingTimestamp: block.timestamp,
                unlockTimestamp: 0,
                isFractionalized: false,
                ERC1155TokenID: 0,
                fractionalizationOption: "",
                totalFractions: 0,
                buyoutPricePerFraction: 0,
                reservePricePerFraction: 0,
                fractionalizationTimestamp: 0,
                isListed: false
            })
        );

        // add NFT contract address to locked NFT Contract addresses (_lockedNFTContracts)
        _SegMintExchangeDB.addAddressToLockedNFTContracts(NFTContractAddress_);

        // update _lockedNFTTokenIDs
        _SegMintExchangeDB.addNFTTokenIDToLockedNFTTokenIDs(
            NFTContractAddress_,
            NFTTokenID_
        );

        // add NFT Contract Address to _lockedNFTContractsOfOwner
        _SegMintExchangeDB.addAddressToLockedNFTContractsOfOwner(
            msg.sender,
            NFTContractAddress_
        );

        // add NFT Token ID to _lockedNFTContractTokenIDsOfOwner
        _SegMintExchangeDB.addNFTTokenIDToLockedNFTContractTokenIDsOfOwner(
            msg.sender,
            NFTContractAddress_,
            NFTTokenID_
        );

        // increment lock and fractionalization index
        _SegMintExchangeDB.incrementLockAndFractionalizationIndex();

        // emit locking event
        emit lockNFTEvent(
            msg.sender,
            NFTCreatorAddress_,
            NFTContractAddress_,
            NFTTokenID_,
            isSegMintNFT_,
            lockingContractAddress_,
            block.timestamp
        );
    }

    // fractionalize a locked NFT
    function fractionalizeNFT(
        address NFTContractAddress_,
        uint256 NFTTokenID_,
        uint256 totalFractions_,
        string memory KeyName_,
        string memory KeySymbol_,
        string memory KeyDescription_
    )
        public
        payable
        notNullAddress(msg.sender, "NFT Owner Address")
        notNullAddress(NFTContractAddress_, "NFT Contract Address")
        onlyKYCAuthorized
    {
        // get locking and fractionalization index
        uint256 lockAndFractionalizationIndex = _SegMintExchangeDB
            .getLockingAndFractionalizingIndex(
                NFTContractAddress_,
                NFTTokenID_
            );

        // require sender be the NFT owner
        require(
            msg.sender ==
                address(
                    _SegMintExchangeDB
                        .getLockingAndFractionalizingNFTInfo(
                            lockAndFractionalizationIndex
                        )
                        .NFTOwnerAddress
                ),
            "SegMint Exchange: Sender is not the NFT owner!"
        );

        // require the NFT be locked
        require(
            _SegMintExchangeDB
                .getLockingAndFractionalizingNFTInfo(
                    lockAndFractionalizationIndex
                )
                .isLocked,
            "SegMint Exchange: NFT is not locked by SegMint!"
        );

        // require locker be the SegMint Exchange contract
        require(
            _SegMintExchangeDB
                .getLockingAndFractionalizingNFTInfo(
                    lockAndFractionalizationIndex
                )
                .lockerAddress == address(this),
            "SegMint Exchange: SegMint is not the locker address!"
        );

        // require the NFT not be fractionalized
        require(
            !_SegMintExchangeDB
                .getLockingAndFractionalizingNFTInfo(
                    lockAndFractionalizationIndex
                )
                .isFractionalized,
            "SegMint Exchange: NFT is already fractionalized!"
        );

        // get the token id
        uint256 FractionalTokenId = _SegMintERC1155.getTokenIDCounter();

        // mint (to the NFT owner wallet address) a new token id with supply of total fractions and
        bool mintStatus = _SegMintERC1155.mint{value: msg.value}(
            msg.sender,
            totalFractions_,
            "",
            KeyName_,
            KeySymbol_,
            KeyDescription_
        );

        // require successful minting
        require(mintStatus, "SegMint Exchange: Failed to mint!");

        /* update fractionalization info in _lockingAndFractionalizingNFTInfo */

        // update isFractionalized
        _SegMintExchangeDB
            .updateIsFractionalizedInLockingAndFractionalizationNFTInfo(
                lockAndFractionalizationIndex,
                true
            );

        // update ERC1155TokenID
        _SegMintExchangeDB
            .updateERC1155TokenIDInLockingAndFractionalizationNFTInfo(
                lockAndFractionalizationIndex,
                FractionalTokenId
            );

        // update totalFractions
        _SegMintExchangeDB
            .updateTotalFractionsInLockingAndFractionalizationNFTInfo(
                lockAndFractionalizationIndex,
                totalFractions_
            );

        // update fractionalizationTimestamp
        _SegMintExchangeDB
            .updateFractionalizationTimestampInLockingAndFractionalizationNFTInfo(
                lockAndFractionalizationIndex
            );

        // emit event
        emit fractionalizeNFTEvent(
            msg.sender,
            NFTContractAddress_,
            NFTTokenID_,
            totalFractions_,
            FractionalTokenId,
            block.timestamp
        );
    }

    /* GETTERS */

    // get contract version
    function getContractVersion() public view returns (uint256) {
        // return version
        return _contractVersion;
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////
}

// SegMint Exchange Trades
contract SegMintExchange is SegMintExchangeStructs {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // SegMint Exchange Contract Version
    uint256 private _contractVersion = 1;

    // owner address
    address private _owner;

    // SegMint Exchange DB
    address private _SegMintExchangeDBContractAddress;

    // SegMint Exchange DB interface
    SegMintExchangeDB private _SegMintExchangeDB;

    // SegMint ERC1155 Contract Address
    address private _SegMintERC1155ContractAddress;

    // SegMint ERC1155 Contract Interface
    SegMintERC1155Interface private _SegMintERC1155;

    // SegMint ERC1155 DB Contract Address
    address private _SegMintERC1155DBContractAddress;

    // SegMint ERC1155 DB Contract Interface
    SegMintERC1155DBInterface private _SegMintERC1155DB;

    // SegMint KYC Contract Address
    address private _SegMintKYCContractAddress;

    // SegMint KYC Interface
    SegMintKYCContractInterface private _SegMintKYC;

    // SegMint ERC1155 Platform Management Contract Address
    address private _SegMintERC1155PlatformManagementContractAddress;

    // SegMing ERC1155 Platform Management Contract Interface
    SegMintERC1155PlatformManagementInterface private _SegMintPlatformManagement;

    ///////////////////////////
    ////    constructor    ////
    ///////////////////////////

    constructor() {
        _owner = msg.sender;
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // update owner address
    event setOwnerAddressEvent(
        address indexed OwnerAddress,
        address previousOwnerAddress,
        address indexed newOwnerAddress,
        uint256 indexed timestamp
    );

    // set SegMint ERC1155 Contract Address
    event setSegMintERC1155ContractAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintERC1155ContractAddress,
        address indexed newSegMintERC1155ContractAddress,
        uint256 indexed timestamp
    );

    // update SegMint Exchange DB event
    event setSegMingExchangeDBContractAddressEvent(
        address indexed OwnerAddress,
        address indexed previousExchangeDBAddress,
        address newSegMintExchangeDBAddress,
        uint256 indexed timestamp
    );

    // set SegMint KYC Contract Address
    event setSegMintKYCContractAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintKYCContractAddress,
        address indexed newSegMintKYCContractAddress,
        uint256 indexed timestamp
    );

    // set SegMint Platform Management Contract Address
    event setSegMintERC1155PlatformManagementContractAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintERC1155PlatformManagementContractAddress,
        address indexed newSegMintERC1155PlatformManagementContractAddress,
        uint256 indexed timestamp
    );

    // listing event
    event listEvent(
        address indexed Sender,
        address NFTContractAddress,
        uint256 NFTTokenID,
        uint256 indexed listingIndex,
        // uint256 lockAndFractionalizationIndex_,
        uint256 ERC1155TokenID,
        uint256 amount,
        uint256 pricePerFraction,
        string fractionalizationOption_,
        uint256 buyoutPricePerFraction_,
        uint256 reservePricePerFraction_,
        uint256 indexed timestamp
    );

    // update price per fraction
    event updateListingPricePerFractionEvent(
        address indexed Sender,
        uint256 indexed listingIndex,
        uint256 previousPricePerFraction,
        uint256 newPricePerFraction,
        uint256 indexed timestamp
    );

    // update buyout price per fraction
    event updateBuyoutPricePerFractionEvent(
        address indexed Sender,
        uint256 lockAndFractionalizationIndex,
        uint256 previousBuyoutPricePerFraction,
        uint256 newBuyoutPricePerFraction,
        uint256 indexed timestamp
    );

    // update reserve price per fraction
    event updateReservePricePerFractionEvent(
        address indexed Sender,
        uint256 lockAndFractionalizationIndex,
        uint256 previousReservePricePerFraction,
        uint256 newReservePricePerFraction,
        uint256 indexed timestamp
    );

    // set fractionalization option to free market
    event setFractionalizationOptionToFreeMarketEvent(
        address indexed Sender,
        uint256 lockAndFractionalizationIndex,
        uint256 previousBuyoutPricePerFraction,
        uint256 previousReservePricePerFraction,
        uint256 indexed timestamp
    );

    // set fractionaliztion option to buyout market
    event setFractionalizationOptionToBuyoutMarketEvent(
        address indexed Sender,
        uint256 lockAndFractionalizationIndex_,
        uint256 previousBuyoutPricePerFraction,
        uint256 buyoutPricePerFraction_,
        uint256 previousReservePricePerFraction,
        uint256 reservePricePerFraction_,
        uint256 indexed timestamp
    );

    // delist event
    event delistEvent(
        address indexed Sender,
        uint256 indexed listingIndex_,
        uint256 listedAmount,
        uint256 delistAmount,
        uint256 indexed timestamp
    );

    // purchase fractions event
    event purchaseFractionsEvent(
        address indexed BuyerAddress,
        uint256 indexed listingIndex,
        address ERC1155ContractAddress,
        uint256 ERC1155TokenID,
        uint256 listedAmount,
        uint256 purchasedAmount,
        uint256 pricePerFraction,
        uint256 paymentAmount,
        address paymentReceiver,
        uint256 indexed timestamp
    );

    // buy all fractions
    event buyAllFractionsEvent(
        address indexed BuyerAddress,
        address NFTContractAddress,
        uint256 NFTTokenID,
        address indexed ERC1155ContractAddress,
        uint256 ERC1155TokenID,
        // uint256 totalPayment,
        // address[] holders,
        // uint256[] balances,
        uint256 indexed timestamp
    );

    // reclaim NFT
    event reclaimNFTEvent(
        address Sender,
        address NFTOwnerAddress,
        address indexed NFTContractAddress,
        uint256 NFTTokenID,
        uint256 indexed lockAndFractionalizationIndex,
        uint256 indexed timestamp
    );
    
    // set SegMint ERC1155 DB Contract Address
    event setSegMintERC1155DBContractAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintERC1155ContractAddress,
        address indexed newSegMintERC1155ContractAddress,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only Owner
    modifier onlyOwner() {
        // require sender be the owner address
        require(
            msg.sender == _owner,
            "SegMint Exchange: Sender is not the Owner address!"
        );
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_, string memory accountName_) {
        // require account not be the zero address
        require(
            account_ != address(0),
            string.concat(
                "SegMint Exchange: ",
                accountName_,
                " cannot be the zero address!"
            )
        );
        _;
    }

    // only Lister
    modifier onlyLister(uint256 listingIndex_) {
        require(
            msg.sender == address(_SegMintExchangeDB.getLister(listingIndex_)),
            "SegMint Exchange: Sender is not the lister!"
        );
        _;
    }

    // only existing listing index
    modifier onlyExistingListingIndex(uint256 listingIndex_) {
        // checking valid listingIndex_
        require(
            listingIndex_ < _SegMintExchangeDB.getListingIndex(),
            "SegMint Exchange: Listing Index is not valid!"
        );
        _;
    }

    // only the owner of all fractions of the ERC1155 token ID
    modifier onlyAllKeysOwner(uint256 ERC1155TokenID_) {
        // holders of the ERC1155 Token ID
        address[] memory holders = SegMintERC1155DBInterface(
            _SegMintExchangeDB.getSegMintERC1155DBAddress()
        ).getTokenIDHolders(ERC1155TokenID_);

        // require the list of holders be only one address and it should be the sender
        require(
            holders.length == 1,
            "SegMint Exchange: There are multi-holders!"
        );
        require(
            msg.sender == address(holders[0]),
            "SegMint Exchnage: Sender is not the holder address!"
        );
        _;
    }

    // only for buyout fractionalization option
    modifier onlyBUYOUTOption(uint256 lockAndFractionalizationIndex_) {
        // require fractionalization option be buyout
        require(
            keccak256(
                bytes(
                    _SegMintExchangeDB.getFractionalizationOption(
                        lockAndFractionalizationIndex_
                    )
                )
            ) == keccak256(bytes("BUYOUT")),
            "SegMint Exchage: Fractionalization Option is not BUYOUT!"
        );
        _;
    }

    // only KYC Authorized Accounts
    modifier onlyKYCAuthorized() {
        // require sender be authorized
        require(
            _SegMintKYC.isAuthorizedAddress(msg.sender),
            "SegMint Exchange: Sender is not an authorized account!"
        );
        _;
    }


    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // set Owner Address
    function setOwnerAddress(address owner_)
        public
        onlyOwner
        notNullAddress(owner_, "Owner Address")
    {
        // previous owner address
        address previousOwnerAddress = _owner;

        // update owner address
        _owner = owner_;

        // emit event
        emit setOwnerAddressEvent(
            msg.sender,
            previousOwnerAddress,
            owner_,
            block.timestamp
        );
    }

    // get owner
    function getOwnerAddress() public view returns (address) {
        return _owner;
    }

    // set SegMint Exchange DB
    function setSegMingExchangeDBContractAddress(
        address SegMintExchangeDBAddress_
    )
        public
        onlyOwner
        notNullAddress(SegMintExchangeDBAddress_, "SegMint Exchange DB")
    {
        // old exchange db address
        address previousExchangeDBAddress = _SegMintExchangeDBContractAddress;

        // update Exchange DB contract address
        _SegMintExchangeDBContractAddress = SegMintExchangeDBAddress_;

        // update interface
        _SegMintExchangeDB = SegMintExchangeDB(SegMintExchangeDBAddress_);

        // emit event
        emit setSegMingExchangeDBContractAddressEvent(
            msg.sender,
            previousExchangeDBAddress,
            SegMintExchangeDBAddress_,
            block.timestamp
        );
    }

    // get SegMint Exchange DB Address
    function getSegMintExchangeDBContractAddress()
        public
        view
        returns (address)
    {
        return _SegMintExchangeDBContractAddress;
    }

    // set _SegMintERC1155ContractAddress
    function setSegMintERC1155ContractAddress(
        address SegMintERC1155ContractAddress_
    )
        public
        onlyOwner
        notNullAddress(
            SegMintERC1155ContractAddress_,
            "SegMint ERC1155 Contract Address"
        )
    {
        // previous address
        address previousSegMintERC1155ContractAddress = _SegMintERC1155ContractAddress;

        // update address
        _SegMintERC1155ContractAddress = SegMintERC1155ContractAddress_;

        // update SegMint ERC1155 Interface
        _SegMintERC1155 = SegMintERC1155Interface(
            SegMintERC1155ContractAddress_
        );

        // emit event
        emit setSegMintERC1155ContractAddressEvent(
            msg.sender,
            previousSegMintERC1155ContractAddress,
            SegMintERC1155ContractAddress_,
            block.timestamp
        );
    }

    // get SegMintERC1155 address
    function getSegMintERC1155Address() public view returns (address) {
        return _SegMintERC1155ContractAddress;
    }
    // set _SegMintERC1155DBContractAddress
    function setSegMintERC1155DBContractAddress(
        address SegMintERC1155DBContractAddress_
    )
        public
        onlyOwner
        notNullAddress(
            SegMintERC1155DBContractAddress_,
            "SegMint ERC1155 DB Contract"
        )
    {
        // previous address
        address previousSegMintERC1155ContractAddress = _SegMintERC1155DBContractAddress;

        // update
        _SegMintERC1155DBContractAddress = SegMintERC1155DBContractAddress_;

        // update interface
        _SegMintERC1155DB = SegMintERC1155DBInterface(SegMintERC1155DBContractAddress_);

        // emit event
        emit setSegMintERC1155DBContractAddressEvent(
            msg.sender,
            previousSegMintERC1155ContractAddress,
            SegMintERC1155DBContractAddress_,
            block.timestamp
        );
    }

    // get SegMintERC1155DB contract address
    function getSegMintERC1155DBContractAddress()
        public
        view
        returns (address)
    {
        return _SegMintERC1155DBContractAddress;
    }

    // set SegMint KYC Contract Address
    function setSegMintKYCContractAddress(address SegMintKYCContractAddress_)
        public
        onlyOwner
        notNullAddress(
            SegMintKYCContractAddress_,
            "SegMint KYC Contract Address"
        )
    {
        // previous address
        address previousSegMintKYCContractAddress = _SegMintKYCContractAddress;

        // update contract address
        _SegMintKYCContractAddress = SegMintKYCContractAddress_;

        // udpate interface
        _SegMintKYC = SegMintKYCContractInterface(SegMintKYCContractAddress_);

        // emit event
        emit setSegMintKYCContractAddressEvent(
            msg.sender,
            previousSegMintKYCContractAddress,
            SegMintKYCContractAddress_,
            block.timestamp
        );
    }

    // get SegMint KYC Contract Address
    function getSegMintKYCContractAddress() public view returns (address) {
        return _SegMintKYCContractAddress;
    }

    // set SegMint ERC1155 Platform Management Contract Address
    function setSegMintERC1155PlatformManagementContractAddress(
        address SegMintERC1155PlatformManagementContractAddress_
    )
        public
        onlyOwner
        notNullAddress(SegMintERC1155PlatformManagementContractAddress_, "SegMint Platform Management Address")
    {
        // previous address
        address previousSegMintERC1155PlatformManagementContractAddress = _SegMintERC1155PlatformManagementContractAddress;

        // update address
        _SegMintERC1155PlatformManagementContractAddress = SegMintERC1155PlatformManagementContractAddress_;

        // update interface
        _SegMintPlatformManagement = SegMintERC1155PlatformManagementInterface(SegMintERC1155PlatformManagementContractAddress_);

        // emit event
        emit setSegMintERC1155PlatformManagementContractAddressEvent(
            msg.sender,
            previousSegMintERC1155PlatformManagementContractAddress,
            SegMintERC1155PlatformManagementContractAddress_,
            block.timestamp
        );
    }

    // get SegMint ERC1155 Platform Management Contract Address
    function getSegMintERC1155PlatformManagementContractAddress() public view returns(address){
        return _SegMintERC1155PlatformManagementContractAddress;
    }

    /*******************/
    /* Trading Process */
    /*******************/

    // list an ERC1155 Token ID (equivalent to an locked NFT) on the market
    function list(
        address NFTContractAddress_,
        uint256 NFTTokenID_,
        uint256 amount_,
        uint256 pricePerFraction_,
        string memory fractionalizationOption_,
        uint256 buyoutPricePerFraction_,
        uint256 reservePricePerFraction_
    )
        public
        onlyKYCAuthorized
        returns (uint256)
    {
        // get locking and fractionalization index
        uint256 lockAndFractionalizationIndex = _SegMintExchangeDB
            .getLockingAndFractionalizingIndex(
                NFTContractAddress_,
                NFTTokenID_
            );

        // require lock and fractionalization index to exist (and not zero)
        require(
            lockAndFractionalizationIndex != 0 &&
            lockAndFractionalizationIndex <
                _SegMintExchangeDB.getLatestLockAndFractionalizationIndex(),
            "SegMint Exchange: Lock and Fractionalization Index does not exist!"
        );

        // Locking and SegMinting Info
        lockingAndFractionalizingNFTInfo memory INFO = _SegMintExchangeDB
            .getLockingAndFractionalizingNFTInfo(lockAndFractionalizationIndex);

        // require sender owns enough available (total balance - locked balance) balance of the token id
        require(
            _SegMintERC1155DB.getAvailableBalance(INFO.ERC1155TokenID, msg.sender) >= amount_,
            "SegMint Exchange: Sender does not have enough available balance!"
        );

        // make sure the prices are greater than zero
        _requireGreaterThanZero(pricePerFraction_, "SegMint Exchange: Price per fraction should be greater than zero!");

        // check if this is the first time listing for that NFT ==> if yes: set fractionaliztion option and buyout and reserve.
        // check if sender owns all keys
        if (
            _SegMintERC1155DB.getAvailableBalance(INFO.ERC1155TokenID, msg.sender) ==
            INFO.totalFractions && !INFO.isListed
        ) {
            // first time listing ==> set fractionalization info
            // require buyout price be > 0
            _requireGreaterThanZero(buyoutPricePerFraction_, "SegMint Exchange: Buyout price per SegMint Key should be greater than zero!");

            // require reserve price per SegMint Key > 0
            _requireGreaterThanZero(reservePricePerFraction_, "SegMint Exchange: Reserve price per SegMint Key should be greater than zero!");

            // update fractionalizationOption
            _SegMintExchangeDB
                .updateFractionalizationOptionInLockingAndFractionalizationNFTInfo(
                    lockAndFractionalizationIndex,
                    fractionalizationOption_
                );

            // update buyoutPricePerFraction
            _SegMintExchangeDB
                .updateBuyoutPricePerFractionInLockingAndFractionalizationNFTInfo(
                    lockAndFractionalizationIndex,
                    buyoutPricePerFraction_
                );

            // update reservePricePerFraction
            _SegMintExchangeDB
                .updateReservePricePerFractionInLockingAndFractionalizationNFTInfo(
                    lockAndFractionalizationIndex,
                    reservePricePerFraction_
                );

            // update isListed
            _SegMintExchangeDB
                .updateIsListedInLockingAndFractionalizationNFTInfo(
                    lockAndFractionalizationIndex,
                    true
                );
        }

        /* Update Listing Info */

        // update _listingsInfo
        _SegMintExchangeDB.createListingInfo(
            ListingInfo({
                _listingIndex: _SegMintExchangeDB.getListingIndex(),
                lockAndFractionalizationIndex: lockAndFractionalizationIndex,
                ERC1155TokenOwnerAddress: msg.sender,
                ERC1155ContractAddress: _SegMintERC1155ContractAddress,
                ERC1155TokenID: INFO.ERC1155TokenID,
                pricePerFraction: pricePerFraction_,
                amount: amount_,
                listingTimestamp: block.timestamp,
                lastUpdateTimestamp: block.timestamp,
                delistingTimestamp: 0,
                listingEndDateTimestamp: 0
            })
        );

        // add ERC1155ContractAddress to_listedERC1155Contracts
        _SegMintExchangeDB.addAddressToListedERC1155Contracts(
            _SegMintERC1155ContractAddress
        );

        // add ERC1155TokenID to _listedERC1155TokenIDs
        _SegMintExchangeDB.addToListedERC1155TokenIDs(
            _SegMintERC1155ContractAddress,
            INFO.ERC1155TokenID
        );

        // add ERC1155TokenOwnerAddress to _listersOfERC11555TokenID
        _SegMintExchangeDB.addListerToListersOfERC155TokenID(
            _SegMintERC1155ContractAddress,
            INFO.ERC1155TokenID,
            msg.sender
        );

        // add listing Index to _ERC1155TokenIDListingIndexes
        _SegMintExchangeDB.addListingIndexToERC1155TokenIDListingIndexes(
            _SegMintERC1155ContractAddress,
            INFO.ERC1155TokenID,
            _SegMintExchangeDB.getListingIndex()
        );

        // add listing Index to _ERC1155TokenIDListingIndexesByOwner
        _SegMintExchangeDB.addListingIndexToERC1155TokenIDListingIndexesByOwner(
                _SegMintERC1155ContractAddress,
                INFO.ERC1155TokenID,
                msg.sender,
                _SegMintExchangeDB.getListingIndex()
            );

        // increment listing index
        _SegMintExchangeDB.incrementListingIndex();

        // lock/freeze the ERC1155 tokens in sender wallet
        bool freezeStatus = _SegMintPlatformManagement.lockToken(
            INFO.ERC1155TokenID,
            msg.sender,
            amount_
        );

        // require freeze status be successful
        require(
            freezeStatus,
            "SegMint Exchange: Failed to freeze SegMint Keys!"
        );

        // emit event
        emit listEvent(
            msg.sender,
            NFTContractAddress_,
            NFTTokenID_,
            _SegMintExchangeDB.getListingIndex() - 1, // -1 due to incremented.
            // lockAndFractionalizationIndex,
            INFO.ERC1155TokenID,
            amount_,
            pricePerFraction_,
            fractionalizationOption_,
            buyoutPricePerFraction_,
            reservePricePerFraction_,
            block.timestamp
        );

        // return listing index
        return _SegMintExchangeDB.getListingIndex() - 1;
    }

    // update listing price per fraction
    function updateListingPricePerFraction(
        uint256 pricePerFraction_,
        uint256 listingIndex_
    ) 
        public 
        onlyLister(listingIndex_) 
        onlyExistingListingIndex(listingIndex_) 
    {
        // price should be more than zero
        _requireGreaterThanZero(pricePerFraction_, "SegMint Exchange: Price cannot be set to zero!");

        // new
        ListingInfo memory INFO = _SegMintExchangeDB
            .getListingInfoByListingIndex(listingIndex_);

        // previous price per fraction
        uint256 previousPricePerFraction = INFO.pricePerFraction;

        // update the price per fraction
        _SegMintExchangeDB.updatePricePerFractionInListingsInfo(
            listingIndex_,
            pricePerFraction_
        );

        // update the lastUpdateTimestamp
        _SegMintExchangeDB.updateLastUpdateTimestampInListingsInfo(
            listingIndex_
        );

        // emit event
        emit updateListingPricePerFractionEvent(
            msg.sender,
            listingIndex_,
            previousPricePerFraction,
            pricePerFraction_,
            block.timestamp
        );
    }

    // update fractionalization option to FREE market
    function setFractionalizationOptionToFreeMarket(
        uint256 lockAndFractionalizationIndex_
    ) 
        public 
        onlyAllKeysOwner(lockAndFractionalizationIndex_) 
    {
        // new: locking and fractionalization info
        lockingAndFractionalizingNFTInfo memory INFO = _SegMintExchangeDB
            .getLockingAndFractionalizingNFTInfo(
                lockAndFractionalizationIndex_
            );

        // previous buyout price per fraction
        uint256 previousBuyoutPricePerFraction = INFO.buyoutPricePerFraction;

        // update the buy out price
        _SegMintExchangeDB
            .updateBuyoutPricePerFractionInLockingAndFractionalizationNFTInfo(
                lockAndFractionalizationIndex_,
                0
            );

        // previous reserve Price Per Fraction
        uint256 previousReservePricePerFraction = INFO.reservePricePerFraction;

        // update the reserve price
        _SegMintExchangeDB
            .updateReservePricePerFractionInLockingAndFractionalizationNFTInfo(
                lockAndFractionalizationIndex_,
                0
            );

        // update fractionalization option (in case)
        _SegMintExchangeDB
            .updateFractionalizationOptionInLockingAndFractionalizationNFTInfo(
                lockAndFractionalizationIndex_,
                "FREE"
            );

        // emit event
        emit setFractionalizationOptionToFreeMarketEvent(
            msg.sender,
            lockAndFractionalizationIndex_,
            previousBuyoutPricePerFraction,
            previousReservePricePerFraction,
            block.timestamp
        );
    }

    // update fractionalization option to BUYOUT market
    function setFractionalizationOptionToBuyoutMarket(
        uint256 lockAndFractionalizationIndex_,
        uint256 buyoutPricePerFraction_,
        uint256 reservePricePerFraction_
    ) 
        public 
        onlyAllKeysOwner(lockAndFractionalizationIndex_) 
    {
        // require buyout price per fraction be > 0
        _requireGreaterThanZero(buyoutPricePerFraction_, "SegMint Exchange: Buyout price per key should be greater than zero!");

        // require reserve price per fraction > 0
        _requireGreaterThanZero(reservePricePerFraction_, "SegMint Exchange: Reserver price per key should be greater than zero!");
        
        // new: locking and fractionalization info
        lockingAndFractionalizingNFTInfo memory INFO = _SegMintExchangeDB
            .getLockingAndFractionalizingNFTInfo(
                lockAndFractionalizationIndex_
            );

        // previous buyout price per fraction
        uint256 previousBuyoutPricePerFraction = INFO.buyoutPricePerFraction;

        // update the buy out price
        _SegMintExchangeDB
            .updateBuyoutPricePerFractionInLockingAndFractionalizationNFTInfo(
                lockAndFractionalizationIndex_,
                buyoutPricePerFraction_
            );

        // previous reserve Price Per Fraction
        uint256 previousReservePricePerFraction = INFO.reservePricePerFraction;

        // update the reserve price
        _SegMintExchangeDB
            .updateReservePricePerFractionInLockingAndFractionalizationNFTInfo(
                lockAndFractionalizationIndex_,
                reservePricePerFraction_
            );

        // update fractionalization option (in case)
        _SegMintExchangeDB
            .updateFractionalizationOptionInLockingAndFractionalizationNFTInfo(
                lockAndFractionalizationIndex_,
                "BUYOUT"
            );

        // emit event
        emit setFractionalizationOptionToBuyoutMarketEvent(
            msg.sender,
            lockAndFractionalizationIndex_,
            previousBuyoutPricePerFraction,
            buyoutPricePerFraction_,
            previousReservePricePerFraction,
            reservePricePerFraction_,
            block.timestamp
        );
    }

    // update buyout price per fraction
    function updateBuyoutPricePerFraction(
        uint256 buyoutPricePerFraction_,
        uint256 lockAndFractionalizationIndex_
    )
        public
        onlyAllKeysOwner(lockAndFractionalizationIndex_)
        onlyBUYOUTOption(lockAndFractionalizationIndex_)
    {
        // price should be more than zero
        _requireGreaterThanZero(buyoutPricePerFraction_, "SegMint Exchange: BuyOut price cannot be set to zero!");

        // new: locking and fractionalization info
        lockingAndFractionalizingNFTInfo memory INFO = _SegMintExchangeDB
            .getLockingAndFractionalizingNFTInfo(
                lockAndFractionalizationIndex_
            );

        // previous buyout price per fraction
        uint256 previousBuyoutPricePerFraction = INFO.buyoutPricePerFraction;

        // update the buy out price
        _SegMintExchangeDB
            .updateBuyoutPricePerFractionInLockingAndFractionalizationNFTInfo(
                lockAndFractionalizationIndex_,
                buyoutPricePerFraction_
            );

        // emit event
        emit updateBuyoutPricePerFractionEvent(
            msg.sender,
            lockAndFractionalizationIndex_,
            previousBuyoutPricePerFraction,
            buyoutPricePerFraction_,
            block.timestamp
        );
    }

    // update reserve price per fraction
    function updateReservePricePerFraction(
        uint256 reservePricePerFraction_,
        uint256 lockAndFractionalizationIndex_
    )
        public
        onlyAllKeysOwner(lockAndFractionalizationIndex_)
        onlyBUYOUTOption(lockAndFractionalizationIndex_)
    {
        // price should be more than zero
        _requireGreaterThanZero(reservePricePerFraction_, "SegMint Exchange: Reserve price cannot be set to zero!");

        // new: locking and fractionalization info
        lockingAndFractionalizingNFTInfo memory INFO = _SegMintExchangeDB
            .getLockingAndFractionalizingNFTInfo(
                lockAndFractionalizationIndex_
            );

        // previous reserve Price Per Fraction
        uint256 previousReservePricePerFraction = INFO.reservePricePerFraction;

        // update the reserve price
        _SegMintExchangeDB
            .updateReservePricePerFractionInLockingAndFractionalizationNFTInfo(
                lockAndFractionalizationIndex_,
                reservePricePerFraction_
            );

        // emit event
        emit updateReservePricePerFractionEvent(
            msg.sender,
            lockAndFractionalizationIndex_,
            previousReservePricePerFraction,
            reservePricePerFraction_,
            block.timestamp
        );
    }

    // delist all or some fractions
    function delist(uint256 amount_, uint256 listingIndex_)
        public
        onlyLister(listingIndex_)
        onlyExistingListingIndex(listingIndex_)
    {
        // fetched the listing from the ledger
        ListingInfo memory ListingINFO = _SegMintExchangeDB
            .getListingInfoByListingIndex(listingIndex_);

        // require amount > 0
        _requireGreaterThanZero(amount_, "Delisting amount");

        // validate the input amount with the listing amount
        require(
            amount_ <= ListingINFO.amount,
            "SegMint Exchange: Not enough tokens listed!"
        );

        // listed amount
        uint256 listedAmount = ListingINFO.amount;

        // subtract the input amount from the listing amount
        _SegMintExchangeDB.updateAmountInListingsInfo(
            listingIndex_,
            listedAmount - amount_
        );

        // updates the last update timestamp
        _SegMintExchangeDB.updateLastUpdateTimestampInListingsInfo(
            listingIndex_
        );

        // checks if the input amount is the total amount listed and update info accordingly
        if (amount_ == ListingINFO.amount) {

            // update delisting timestamp
            _SegMintExchangeDB.updateDelistingTimestampInListingsInfo(
                listingIndex_
            );

            // remove listing index from _ERC1155TokenIDListingIndexes
            _SegMintExchangeDB.removeListingIndexFromERC1155TokenIDListingIndexes(
                _SegMintERC1155ContractAddress,
                ListingINFO.ERC1155TokenID,
                listingIndex_
            );

            // remove listing index from _ERC1155TokenIDListingIndexesByOwner
            _SegMintExchangeDB
                .removeListingIndexFromERC1155TokenIDListingIndexesByOwner(
                    _SegMintERC1155ContractAddress,
                    ListingINFO.ERC1155TokenID,
                    ListingINFO.ERC1155TokenOwnerAddress,
                    listingIndex_
                );

            // if no other listing of the lister for that specific token id then remove lister from _listersOfERC11555TokenID
            if (
                _SegMintExchangeDB
                    .getERC1155TokenIDListingIndexesByOwner(
                        _SegMintERC1155ContractAddress,
                        ListingINFO.ERC1155TokenID,
                        ListingINFO.ERC1155TokenOwnerAddress
                    )
                    .length == 0
            ) {
                _SegMintExchangeDB.removeListerFromListersOfERC155TokenID(
                    _SegMintERC1155ContractAddress,
                    ListingINFO.ERC1155TokenID,
                    ListingINFO.ERC1155TokenOwnerAddress
                );
            }

            // if the is no listing for the ERC1155TokenID the remove ERC1155TokenID from _listedERC1155TokenIDs
            if (
                _SegMintExchangeDB
                    .getERC1155TokenIDListingIndexes(
                        _SegMintERC1155ContractAddress,
                        ListingINFO.ERC1155TokenID
                    )
                    .length == 0
            ) {
                _SegMintExchangeDB.removeFromListedERC1155TokenIDs(
                    _SegMintERC1155ContractAddress,
                    ListingINFO.ERC1155TokenID
                );
            }
        }

        //unfreeze the keys;
        bool unfreezeStatus = _SegMintPlatformManagement.unlockToken(ListingINFO.ERC1155TokenID, msg.sender, amount_);

        // require successful unfreezing of keys
        require(unfreezeStatus, "SegMint Exchange: Failed to unfreeze keys!");

        // emit event
        emit delistEvent(
            msg.sender,
            listingIndex_,
            listedAmount,
            amount_,
            block.timestamp
        );
    }

    // user purchase fractions
    function purchaseFractions(uint256 amount_, uint256 listingIndex_)
        public
        payable
        onlyKYCAuthorized
        onlyExistingListingIndex(listingIndex_)
    {
        // purchase amount should be greater than zero
        _requireGreaterThanZero(amount_, "SegMint Exchange: Purchase amount should be more than zero!");

        // fetch the listing from the _listingsInfo
        ListingInfo memory ListingINFO = _SegMintExchangeDB
            .getListingInfoByListingIndex(listingIndex_);

        // purchase amount should be less or equal to the listed amount
        require(
            amount_ <= ListingINFO.amount,
            "SegMint Exchange: Purchase amount exceeds listed amount!"
        );

        require(
            msg.value == ListingINFO.pricePerFraction * amount_,
            "SegMint Exchange: Please send proper msg value according to the purchase amount!"
        );

        // transfer payment to nft owner
        payable(ListingINFO.ERC1155TokenOwnerAddress).transfer(msg.value);

        // unfreeze tokens and transfer to purchaser
        bool unfreezeAndTransferStatus = _SegMintPlatformManagement.unLockAndTransferToken(
            ListingINFO.ERC1155TokenID,
            ListingINFO.ERC1155TokenOwnerAddress,
            msg.sender,
            amount_
        );

        // require unfreeze and transfer be successful
        require(
            unfreezeAndTransferStatus,
            "SegMint Exchange: Failed to unfreeze and transfer!"
        );

        // update available lising amount (No delisting is needed! delisting is only when all key holder want to delist).
        // if (amount_ == ListingINFO.amount) {
        //     // all amount is being sold, then remove ListingINFO.

        //     // udpate delisting timestamp
        //     _SegMintExchangeDB.updateDelistingTimestampInListingsInfo(
        //         listingIndex_
        //     );

        //     // remove listing index from _ERC1155TokenIDListingIndexes
        //     _SegMintExchangeDB
        //         .removeListingIndexFromERC1155TokenIDListingIndexes(
        //             _SegMintERC1155ContractAddress,
        //             ListingINFO.ERC1155TokenID,
        //             listingIndex_
        //         );

        //     // remove listing index from _ERC1155TokenIDListingIndexesByOwner
        //     _SegMintExchangeDB
        //         .removeListingIndexFromERC1155TokenIDListingIndexesByOwner(
        //             _SegMintERC1155ContractAddress,
        //             ListingINFO.ERC1155TokenID,
        //             ListingINFO.ERC1155TokenOwnerAddress,
        //             listingIndex_
        //         );

        //     // remove lister from _listersOfERC11555TokenID
        //     if (
        //         _SegMintExchangeDB
        //             .getERC1155TokenIDListingIndexesByOwner(
        //                 _SegMintERC1155ContractAddress,
        //                 ListingINFO.ERC1155TokenID,
        //                 ListingINFO.ERC1155TokenOwnerAddress
        //             )
        //             .length == 0
        //     ) {
        //         _SegMintExchangeDB.removeListerFromListersOfERC155TokenID(
        //             _SegMintERC1155ContractAddress,
        //             ListingINFO.ERC1155TokenID,
        //             ListingINFO.ERC1155TokenOwnerAddress
        //         );
        //     }

        //     // remove ERC1155TokenID from _listedERC1155TokenIDs
        //     if (
        //         _SegMintExchangeDB
        //             .getERC1155TokenIDListingIndexes(
        //                 _SegMintERC1155ContractAddress,
        //                 ListingINFO.ERC1155TokenID
        //             )
        //             .length == 0
        //     ) {
        //         _SegMintExchangeDB.removeFromListedERC1155TokenIDs(
        //             _SegMintERC1155ContractAddress,
        //             ListingINFO.ERC1155TokenID
        //         );
        //     }
        // }

        // udpate amount listed
        _SegMintExchangeDB.updateAmountInListingsInfo(
            listingIndex_,
            ListingINFO.amount - amount_
        );

        // update last update timestamp
        _SegMintExchangeDB.updateLastUpdateTimestampInListingsInfo(
            listingIndex_
        );

        // emit event
        emit purchaseFractionsEvent(
            msg.sender,
            listingIndex_,
            ListingINFO.ERC1155ContractAddress,
            ListingINFO.ERC1155TokenID,
            ListingINFO.amount,
            amount_,
            ListingINFO.pricePerFraction,
            ListingINFO.pricePerFraction * amount_,
            ListingINFO.ERC1155TokenOwnerAddress,
            block.timestamp
        );
    }

    // buyout / reserve all fractions
    function buyAllFractions(address NFTContractAddress_, uint256 NFTTokenID_)
        public
        payable
        onlyKYCAuthorized
    {

        // get lock and fractionalization index
        uint256 lockAndFractionalizationIndex = _SegMintExchangeDB
            .getLockingAndFractionalizingIndex(
                NFTContractAddress_,
                NFTTokenID_
            );

        // new lock and fractionalization info
        lockingAndFractionalizingNFTInfo memory LockINFO = _SegMintExchangeDB
            .getLockingAndFractionalizingNFTInfo(lockAndFractionalizationIndex);

        // require fractionalization option be buyout
        require(
            keccak256(
                bytes(
                    LockINFO.fractionalizationOption
                )
            ) == keccak256(bytes("BUYOUT")),
            "SegMint Exchage: SegMintation Option is not BUYOUT!"
        );

        // buyout
        bool buyoutStatus = _SegMintPlatformManagement.BuyoutFromAllHolders{value: msg.value}(
            msg.sender,
            LockINFO.NFTOwnerAddress,
            LockINFO.ERC1155TokenID,
            LockINFO.buyoutPricePerFraction,
            LockINFO.reservePricePerFraction
        );

        // require a successful buyout
        require(buyoutStatus, "SegMint Exchange: Failed to buyout!");

        // delisting all lising indexes for the the ERC1155 Token ID
        _SegMintExchangeDB.delistAllListingERC1155TokenID(
            NFTContractAddress_,
            NFTTokenID_
        );

        // emit event
        emit buyAllFractionsEvent(
            msg.sender,
            NFTContractAddress_,
            NFTTokenID_,
            _SegMintERC1155ContractAddress,
            // _lockingAndFractionalizingNFTInfo[lockAndFractionalizationIndex]
            LockINFO.ERC1155TokenID,
            // totalPayment,
            // holders,
            // balances,
            block.timestamp
        );
    }

    // buy keys from specific holders
    function buyFromSpecificHolders(
        address NFTContractAddress_, 
        uint256 NFTTokenID_,
        address[] memory holders
        )
        public
        payable
        onlyKYCAuthorized
    {
        // to be implemented
    }

    // reclaim ERC721 NFT
    function reclaimNFT(address NFTContractAddress_, uint256 NFTTokenID_)
        public
        payable
        onlyKYCAuthorized
    {
        // get lock and fractionalization index
        uint256 lockAndFractionalizationIndex = _SegMintExchangeDB
            .getLockingAndFractionalizingIndex(
                NFTContractAddress_,
                NFTTokenID_
            );

        // get locking and fractionalization info
        lockingAndFractionalizingNFTInfo memory Info = _SegMintExchangeDB
            .getLockingAndFractionalizingNFTInfo(lockAndFractionalizationIndex);

        // require NFT be locked
        require(Info.isLocked, "SegMint Exchange: NFT is not locked!");

        // if fractionalized => anyone can be the holder of all fractions
        // if not fractionalized => only NFT owner should be able to run reclaim
        // if fractionalized => burn all fractions
        if (Info.isFractionalized) {
            // NFT is fractionalized => only the holder of all fractions can reclaim NFT

            // get sender's balance
            uint256 senderBalance = _SegMintERC1155DB.getBalanceOf(Info.ERC1155TokenID, msg.sender);

            // sender should own all fractions
            // require(_senderOwnsAllFractions(Info.ERC1155TokenID), "SegMint Exchange: Sender does not hold all fractions!");
            require(
                senderBalance == Info.totalFractions,
                "SegMint Exchange: Sender does not hold all fractions!"
            );

            // burn all fractions
            bool burnStatus = _SegMintERC1155.burn{value: msg.value}(
                msg.sender,
                Info.ERC1155TokenID,
                senderBalance
            );

            // require successful burn status
            require(
                burnStatus,
                "SegMint Exchange: Failed to burn SegMint Keys!"
            );

            // Sender : either NFT owner or a different address
            if (msg.sender == address(Info.NFTOwnerAddress)) {
                // unlock (or unlock and transfer) the NFT (depending on NFT being Standard or SegMint NFT)
                if (Info.isSegMintNFT) {
                    // NFT is SegMint NFT

                    // unlock NFT
                    bool unlockStatus = SegMintERC721ContractInterface(
                        NFTContractAddress_
                    ).fractionerUnlock(NFTTokenID_);

                    // require successfull unlocking
                    require(
                        unlockStatus,
                        "SegMint Exchange: Failed to successfully unlock NFT!"
                    );
                } else {
                    // NFT is standard NFT => it is locked in the locking contract.
                    // unlock NFT in Locking contract and transfer to Owner Wallet address
                    bool unlockAndTransferStatus = SegMintNFTLockingContractInterface(
                            Info.lockingContractAddress
                        ).fractionerUnlockAndTransfer(
                                NFTContractAddress_,
                                NFTTokenID_,
                                Info.NFTOwnerAddress
                            );

                    // require successful unlock and transfer
                    require(
                        unlockAndTransferStatus,
                        "SegMint Exchange: Failed to successfully unlock NFT!"
                    );
                }
            } else {
                // sender is not NFT owner
                // unlock and transfer the NFT (depending on NFT being Standard or SegMint NFT)
                if (Info.isSegMintNFT) {
                    // NFT is SegMint NFT

                    // unlock and transfer NFT to sender
                    bool unlockAndTransferStatus = SegMintERC721ContractInterface(
                            NFTContractAddress_
                        ).fractionerUnlockAndTransfer(NFTTokenID_, msg.sender);

                    // require sucessful unlock and transfer NFT
                    require(
                        unlockAndTransferStatus,
                        "SegMint Exchange: Failed to successfully unlock NFT!"
                    );
                } else {
                    // NFT is standard NFT => it is locked in the locking contract.
                    // unlock NFT in Locking contract and transfer to sender Wallet address
                    bool unlockAndTransferStatus = SegMintNFTLockingContractInterface(
                            Info.lockingContractAddress
                        ).fractionerUnlockAndTransfer(
                                NFTContractAddress_,
                                NFTTokenID_,
                                msg.sender
                            );

                    // require sucessful unlock and transfer NFT
                    require(
                        unlockAndTransferStatus,
                        "SegMint Exchange: Failed to successfully unlock NFT!"
                    );
                }
            }
        } else {
            // require sender be the NFT owner address (NFT is locked but not fractionalized)
            require(
                msg.sender == address(Info.NFTOwnerAddress),
                "SegMint Exchange: Sender is not the NFT owner!"
            );

            // unlock (or unlock and transfer) the NFT (depending on NFT being Standard or SegMint NFT)
            if (Info.isSegMintNFT) {
                // NFT is SegMint NFT

                // unlock NFT
                bool unlockStatus = SegMintERC721ContractInterface(
                    NFTContractAddress_
                ).fractionerUnlock(NFTTokenID_);

                // require sucessful unlock and transfer NFT
                require(
                    unlockStatus,
                    "SegMint Exchange: Failed to successfully unlock NFT!"
                );
            } else {
                // NFT is standard NFT => it is locked in the locking contract.
                // unlock NFT in Locking contract and transfer to Owner Wallet address
                bool unlockAndTransferStatus = SegMintNFTLockingContractInterface(
                        Info.lockingContractAddress
                    ).fractionerUnlockAndTransfer(
                            NFTContractAddress_,
                            NFTTokenID_,
                            Info.NFTOwnerAddress
                        );

                // require sucessful unlock and transfer NFT
                require(
                    unlockAndTransferStatus,
                    "SegMint Exchange: Failed to successfully unlock NFT!"
                );
            }
        }

        // Update Locking and Fractionalization Info
        _SegMintExchangeDB.updateLockingAndFractionalizationByReclaiming(
            lockAndFractionalizationIndex
        );

        // emit event
        emit reclaimNFTEvent(
            msg.sender,
            Info.NFTOwnerAddress,
            NFTContractAddress_,
            NFTTokenID_,
            lockAndFractionalizationIndex,
            block.timestamp
        );
    }
    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    // require value be greater than zero
    function _requireGreaterThanZero(uint256 value_, string memory message) internal pure {
        require(value_ > 0, message);
    }

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////
}