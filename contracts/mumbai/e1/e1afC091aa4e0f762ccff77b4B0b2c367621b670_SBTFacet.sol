// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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
pragma solidity ^0.8.17;

import {IERC1155MetadataURI} from "../interfaces/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibERC2771Context.sol";
import "../libraries/LibProjects.sol";

error OpusNoSetApprovalForAll(address _operator, bool _approved);
error OpusNoIsApprovedForAll(address _account, address _operator);
error OpusNoSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes _data);
error OpusNoSafeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _amounts, bytes _data);

contract SBTFacet is IERC1155MetadataURI, Modifiers {
    LibAppStorage s;

    function name() external view returns (string memory) {
        return s.tokenName;
    }

    function symbol() external view returns (string memory) {
        return s.tokenSymbol;
    }

    function mintBatch(address[] calldata _tos, uint256 tokenId_) external onlyTrustedForwarder {
        require(_tos.length != 0, "SBTFacet: _tos must be longer than 1");

        uint256 projectId = s.tokenMetadata[tokenId_].projectId;

        require(
            LibProjects.getAdminByProjectId(projectId, LibERC2771Context.msgSender()) == 1,
            "SBTFacet: Not authorized"
        );

        uint256 count = _tos.length;
        for (uint256 i; i < count; ) {
            address to = _tos[i];
            require(to != address(0), "SBTFacet: Mint to the zero address");

            require(s.mintDetails[to][tokenId_].isMinted != 1, "SBTFacet: Already minted to this user");

            if (s.mintDetails[to][tokenId_].index == 0) {
                s.userCardsIds[to].push(tokenId_);
                s.mintDetails[to][tokenId_] = MintDetailStruct({
                    isMinted: 1,
                    index: s.userCardsIds[to].length,
                    mintedAt: block.timestamp,
                    mintedBy: LibERC2771Context.msgSender()
                });
                s.cardUsers[tokenId_].push(to);
            } else {
                s.userCardsIds[to][s.mintDetails[to][tokenId_].index - 1] = tokenId_;
                s.mintDetails[to][tokenId_].isMinted = 1;
                s.mintDetails[to][tokenId_].mintedAt = block.timestamp;
                s.mintDetails[to][tokenId_].mintedBy = LibERC2771Context.msgSender();
            }

            address operator = LibERC2771Context.msgSender();
            emit TransferSingle(operator, address(0), to, tokenId_, 1);
            unchecked {
                ++i;
            }
        }

        LibProjects.addUsersToProject(projectId, _tos);
    }

    function burn(address _from, uint256 tokenId_) external onlyTrustedForwarder {
        require(_from != address(0), "SBTFacet: Burn from the zero address");

        require(
            _from == LibERC2771Context.msgSender() ||
                s.tokenMetadata[tokenId_].createdBy == LibERC2771Context.msgSender(),
            "SBTFacet: Not authorized"
        );

        require(s.mintDetails[_from][tokenId_].isMinted == 1, "SBTFacet: Not minted to this user");

        delete s.userCardsIds[_from][s.mintDetails[_from][tokenId_].index - 1];
        s.mintDetails[_from][tokenId_].isMinted = 2;

        uint256 projectId = s.tokenMetadata[tokenId_].projectId;
        uint256[] memory cardIds = s.projectCardIds[projectId];

        if (s.tokenMetadata[tokenId_].createdBy != _from) {
            bool ownership;
            uint256 count = cardIds.length;
            for (uint256 i; i < count; ) {
                if (s.mintDetails[_from][cardIds[i]].isMinted == 1) {
                    ownership = true;
                }
                unchecked {
                    ++i;
                }
            }

            if (!ownership) {
                delete s.userProjects[_from][s.userProjectExists[_from][projectId].index - 1];
                s.userProjectExists[_from][projectId].isExisted = 2;

                delete s.projectUsers[projectId][s.projectUserExists[projectId][_from].index - 1];
                s.projectUserExists[projectId][_from].isExisted = 2;
                s.operatorAdmins[projectId][_from] = 2;
            }
        }

        address operator = LibERC2771Context.msgSender();
        emit TransferSingle(operator, _from, address(0), tokenId_, 1);
    }

    //  ==========  IERC1155 logic    ==========
    function balanceOf(address _account, uint256 _id) public view returns (uint256 balance) {
        require(_account != address(0), "SBTFacet: balance query for the zero address");
        if (s.mintDetails[_account][_id].isMinted == 1) {
            return 1;
        }
        return 0;
    }

    function balanceOfBatch(
        address[] calldata _accounts,
        uint256[] calldata _ids
    ) external view returns (uint256[] memory) {
        uint256 count = _accounts.length;

        require(count == _ids.length, "SBTFacet: _accounts and _ids must have the same length");

        uint256[] memory batchBalances = new uint256[](count);
        for (uint256 i; i < count; ) {
            batchBalances[i] = balanceOf(_accounts[i], _ids[i]);
            unchecked {
                ++i;
            }
        }
        return batchBalances;
    }

    function setApprovalForAll(address _operator, bool _approved) external pure {
        revert OpusNoSetApprovalForAll(_operator, _approved);
    }

    function isApprovedForAll(address _account, address _operator) external pure returns (bool) {
        revert OpusNoIsApprovedForAll(_account, _operator);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external pure {
        revert OpusNoSafeTransferFrom(_from, _to, _id, _amount, _data);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external pure {
        revert OpusNoSafeBatchTransferFrom(_from, _to, _ids, _amounts, _data);
    }

    //  ==========  IERC1155MetadataURI logic    ==========
    function uri(uint256 _id) external view returns (string memory) {
        require(bytes(s.tokenMetadata[_id].name).length != 0, "SBTFacet: URI query for nonexistent token");

        MetadataStruct memory tokenMetadata = s.tokenMetadata[_id];
        uint256 projectId = tokenMetadata.projectId;
        string memory projectName = LibProjects.getProjectById(projectId).name;

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        "{",
                        '"name": "',
                        tokenMetadata.name,
                        '",'
                        '"description": "',
                        tokenMetadata.description,
                        '",',
                        '"image": "',
                        s.baseImageUri,
                        "://",
                        tokenMetadata.imageCID,
                        '",',
                        '"animation_url": "',
                        s.baseImageUri,
                        "://",
                        tokenMetadata.animationCID,
                        '",',
                        '"attributes": [',
                        "{",
                        '"trait_type": "tokenId",',
                        '"value": "',
                        Strings.toString(_id),
                        '"',
                        "},",
                        "{",
                        '"trait_type": "category",',
                        '"value": "',
                        tokenMetadata.category,
                        '"',
                        "},",
                        "{",
                        '"trait_type": "role",',
                        '"value": "',
                        tokenMetadata.role,
                        '"',
                        "},",
                        "{",
                        '"trait_type": "project",',
                        '"value": "',
                        projectName,
                        '"',
                        "},",
                        "{",
                        '"trait_type": "createdBy",',
                        '"value": "',
                        Strings.toHexString(tokenMetadata.createdBy),
                        '"',
                        "}",
                        "]",
                        "}"
                    )
                )
            )
        );
        string memory output = string(abi.encodePacked("data:application/json;base64,", json));
        return output;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.17;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

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
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

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
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function isApprovedForAll(address account, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.17;

import "./IERC1155.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./LibERC2771Context.sol";

struct LibAppStorage {
    string tokenName;
    string tokenSymbol;
    string baseImageUri;
    // Mapping from token id to card info
    mapping(uint256 => MetadataStruct) tokenMetadata;
    // Mapping from token id to user address
    mapping(uint256 => address[]) cardUsers;
    // Mapping from project id to token ids
    mapping(uint256 => uint256[]) projectCardIds;
    // Mapping from wallet address to last created token id
    mapping(address => uint256) userLatestTokenId;
    // Mapping from user address to token ids
    mapping(address => uint256[]) userCardsIds;
    mapping(address => mapping(uint256 => MintDetailStruct)) mintDetails;
    // Mapping from project id to project info
    mapping(uint256 => ProjectStruct) projects;
    // Mapping from project name to project id
    mapping(string => uint256) projectMapping;
    // Mapping from user address to project ids
    mapping(address => uint256[]) userProjects;
    mapping(address => mapping(uint256 => ExistStruct)) userProjectExists;
    // Mapping from project id to user address
    mapping(uint256 => address[]) projectUsers;
    mapping(uint256 => mapping(address => ExistStruct)) projectUserExists;
    // Mapping from project id to user admin
    mapping(uint256 => mapping(address => uint256)) operatorAdmins;
}

struct MetadataStruct {
    uint256 tokenId;
    uint256 projectId;
    uint256 createdAt;
    string name;
    string imageCID;
    string animationCID;
    string description;
    string role;
    string category;
    string twitter;
    string opensea;
    string discord;
    address createdBy;
}

struct ProjectStruct {
    uint256 id;
    string name;
    string imageUrl;
    string description;
    address createdBy;
}

struct ProjectUserStruct {
    address walletAddress;
    bool isAdmin;
}

struct MintDetailStruct {
    uint256 isMinted;
    uint256 index; // NOTE: Start at one.
    uint256 mintedAt;
    address mintedBy;
}

struct ExistStruct {
    uint256 isExisted;
    uint256 index; // NOTE: Start at one.
}

contract Modifiers {
    modifier onlyTrustedForwarder() {
        require(LibERC2771Context.isTrustedForwarder(msg.sender), "ERC2771Context: caller is not a trusted forwarder");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";

library LibCards {
    using Counters for Counters.Counter;

    bytes32 constant CARDS_STORAGE_POSITION = keccak256("diamond.standard.cards.storage");

    struct CardsStorage {
        Counters.Counter tokenIds;
        Counters.Counter mintedCount;
        uint256 cardLimit;
    }

    function cardsStorage() internal pure returns (CardsStorage storage cs) {
        bytes32 position = CARDS_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

    function incrementTokenId() internal {
        CardsStorage storage cs = cardsStorage();
        cs.tokenIds.increment();
    }

    function currentTokenId() internal view returns (uint256) {
        return cardsStorage().tokenIds.current();
    }

    function setCardLimit(uint256 _limit) internal {
        CardsStorage storage cs = cardsStorage();
        cs.cardLimit = _limit;
    }

    function cardLimit() internal view returns (uint256) {
        return cardsStorage().cardLimit;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LibContext {
    function msgSender() internal view returns (address) {
        return msg.sender;
    }

    function msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LibContext.sol";

library LibERC2771Context {
    bytes32 constant CONTEXT_STORAGE_POSITION = keccak256("diamond.standard.context.storage");

    struct ContextStorage {
        address trustedForwarder;
    }

    function contextStorage() internal pure returns (ContextStorage storage cs) {
        bytes32 position = CONTEXT_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

    function setTrustedForwarder(address _trustedForwarder) internal {
        ContextStorage storage cs = contextStorage();
        cs.trustedForwarder = _trustedForwarder;
    }

    function isTrustedForwarder(address _forwarder) internal view returns (bool) {
        return _forwarder == contextStorage().trustedForwarder;
    }

    function msgSender() internal view returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return LibContext.msgSender();
        }
    }

    function msgData() internal view returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return LibContext.msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./LibAppStorage.sol";
import "./LibCards.sol";
import "./LibERC2771Context.sol";

struct ReturnProjectStruct {
    uint256 id;
    string name;
    string imageUrl;
    string description;
    address createdBy;
    bool canCreateCard;
}

library LibProjects {
    using Counters for Counters.Counter;

    bytes32 constant PROJECTS_STORAGE_POSITION = keccak256("diamond.standard.projects.storage");

    struct ProjectsStorage {
        Counters.Counter projectId;
    }

    function projectsStorage() internal pure returns (ProjectsStorage storage ds) {
        bytes32 position = PROJECTS_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function appStorage() internal pure returns (LibAppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }

    function incrementProjectId() internal {
        ProjectsStorage storage ps = projectsStorage();
        ps.projectId.increment();
    }

    function currentProjectId() internal view returns (uint256) {
        return projectsStorage().projectId.current();
    }

    function getProjectById(uint256 _projectId) internal view returns (ReturnProjectStruct memory) {
        ProjectStruct memory project = appStorage().projects[_projectId];
        return
            ReturnProjectStruct({
                id: project.id,
                name: project.name,
                imageUrl: project.imageUrl,
                description: project.description,
                createdBy: project.createdBy,
                canCreateCard: appStorage().projectCardIds[_projectId].length < LibCards.cardLimit()
            });
    }

    function getAdminByProjectId(uint256 _projectId, address _walletAddress) internal view returns (uint256) {
        return appStorage().operatorAdmins[_projectId][_walletAddress];
    }

    function addUsersToProject(uint256 _projectId, address[] calldata _addressList) internal {
        LibAppStorage storage s = appStorage();

        require(s.operatorAdmins[_projectId][LibERC2771Context.msgSender()] == 1, "LibProjects: Not authorized");

        uint256 count = _addressList.length;
        for (uint256 i; i < count; ) {
            address walletAddress = _addressList[i];

            if (s.projectUserExists[_projectId][walletAddress].isExisted != 1) {
                if (s.projectUserExists[_projectId][walletAddress].index == 0) {
                    s.projectUsers[_projectId].push(walletAddress);
                    s.projectUserExists[_projectId][walletAddress] = ExistStruct({
                        isExisted: 1,
                        index: s.projectUsers[_projectId].length
                    });
                } else {
                    s.projectUsers[_projectId][
                        s.projectUserExists[_projectId][walletAddress].index - 1
                    ] = walletAddress;
                    s.projectUserExists[_projectId][walletAddress].isExisted = 1;
                }

                s.operatorAdmins[_projectId][walletAddress] = 2;
            }

            if (s.userProjectExists[walletAddress][_projectId].isExisted != 1) {
                if (s.userProjectExists[walletAddress][_projectId].index == 0) {
                    s.userProjects[walletAddress].push(_projectId);
                    s.userProjectExists[walletAddress][_projectId] = ExistStruct({
                        isExisted: 1,
                        index: s.userProjects[walletAddress].length
                    });
                } else {
                    s.userProjects[walletAddress][
                        s.userProjectExists[walletAddress][_projectId].index - 1
                    ] = _projectId;
                    s.userProjectExists[walletAddress][_projectId].isExisted = 1;
                }
            }
            unchecked {
                ++i;
            }
        }
    }
}