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
pragma solidity ^0.8.0;

interface IOnChainMetadata {
  /// @notice Lyrics updated for this edition
  event SongUpdated(
    address target,
    address sender,
    SongMetadata songMetadata,
    ProjectMetadata projectMetadata,
    string[] tags,
    Credit[] credits
  );

  /// @notice AudioQuantitativeUpdated updated for this edition
  /// @dev admin function indexer feedback
  event AudioQuantitativeUpdated(
    address indexed target,
    address sender,
    string key,
    uint256 bpm,
    uint256 duration,
    string audioMimeType,
    uint256 trackNumber
  );

  /// @notice AudioQualitative updated for this edition
  /// @dev admin function indexer feedback
  event AudioQualitativeUpdated(
    address indexed target,
    address sender,
    string license,
    string externalUrl,
    string isrc,
    string genre
  );

  /// @notice Lyrics updated for this edition
  event LyricsUpdated(
    address target,
    address sender,
    string lyrics,
    string lyricsNft
  );

  /// @notice Artwork updated for this edition
  /// @dev admin function indexer feedback
  event ArtworkUpdated(
    address indexed target,
    address sender,
    string artworkUri,
    string artworkMimeType,
    string artworkNft
  );

  /// @notice Visualizer updated for this edition
  /// @dev admin function indexer feedback
  event VisualizerUpdated(
    address indexed target,
    address sender,
    string artworkUri,
    string artworkMimeType,
    string artworkNft
  );

  /// @notice ProjectMetadata updated for this edition
  /// @dev admin function indexer feedback
  event ProjectArtworkUpdated(
    address indexed target,
    address sender,
    string artworkUri,
    string artworkMimeType,
    string artworkNft
  );

  /// @notice Tags updated for this edition
  /// @dev admin function indexer feedback
  event TagsUpdated(address indexed target, address sender, string[] tags);

  /// @notice Credit updated for this edition
  /// @dev admin function indexer feedback
  event CreditsUpdated(
    address indexed target,
    address sender,
    Credit[] credits
  );

  /// @notice ProjectMetadata updated for this edition
  /// @dev admin function indexer feedback
  event ProjectPublishingDataUpdated(
    address indexed target,
    address sender,
    string title,
    string description,
    string recordLabel,
    string publisher,
    string locationCreated,
    string releaseDate,
    string projectType,
    string upc
  );

  /// @notice PublishingData updated for this edition
  /// @dev admin function indexer feedback
  event PublishingDataUpdated(
    address indexed target,
    address sender,
    string title,
    string description,
    string recordLabel,
    string publisher,
    string locationCreated,
    string releaseDate
  );

  /// @notice losslessAudio updated for this edition
  /// @dev admin function indexer feedback
  event LosslessAudioUpdated(
    address indexed target,
    address sender,
    string losslessAudio
  );

  /// @notice Description updated for this edition
  /// @dev admin function indexer feedback
  event DescriptionUpdated(
    address indexed target,
    address sender,
    string newDescription
  );

  /// @notice Artist updated for this edition
  /// @dev admin function indexer feedback
  event ArtistUpdated(address indexed target, address sender, string newArtist);

  /// @notice Event for updated Media URIs
  event MediaURIsUpdated(
    address indexed target,
    address sender,
    string imageURI,
    string animationURI
  );

  /// @notice Event for a new edition initialized
  /// @dev admin function indexer feedback
  event EditionInitialized(
    address indexed target,
    string description,
    string imageURI,
    string animationURI
  );

  /// @notice Storage for SongMetadata
  struct SongMetadata {
    SongContent song;
    PublishingData songPublishingData;
  }

  /// @notice Storage for SongContent
  struct SongContent {
    Audio audio;
    Artwork artwork;
    Artwork visualizer;
  }

  /// @notice Storage for SongDetails
  struct SongDetails {
    string artistName;
    AudioQuantitative audioQuantitative;
    AudioQualitative audioQualitative;
  }

  /// @notice Storage for Audio
  struct Audio {
    string losslessAudio; // ipfs://{cid} or arweave
    SongDetails songDetails;
    Lyrics lyrics;
  }

  /// @notice Storage for AudioQuantitative
  struct AudioQuantitative {
    string key; // C / A# / etc
    uint256 bpm; // 120 / 60 / 100
    uint256 duration; // 240 / 60 / 120
    string audioMimeType; // audio/wav
    uint256 trackNumber; // 1
  }

  /// @notice Storage for AudioQualitative
  struct AudioQualitative {
    string license; // CC0
    string externalUrl; // Link to your project website
    string isrc; // CC-XXX-YY-NNNNN
    string genre; // Rock / Pop / Metal / Hip-Hop / Electronic / Classical / Jazz / Folk / Reggae / Other
  }

  /// @notice Storage for Artwork
  struct Artwork {
    string artworkUri; // The uri of the artwork (ipfs://<CID>)
    string artworkMimeType; // The mime type of the artwork
    string artworkNft; // The NFT of the artwork (caip19)
  }

  /// @notice Storage for Lyrics
  struct Lyrics {
    string lyrics;
    string lyricsNft;
  }

  /// @notice Storage for PublishingData
  struct PublishingData {
    string title;
    string description;
    string recordLabel; // Sony / Universal / etc
    string publisher; // Sony / Universal / etc
    string locationCreated;
    string releaseDate; // 2020-01-01
  }

  /// @notice Storage for ProjectMetadata
  struct ProjectMetadata {
    PublishingData publishingData;
    Artwork artwork;
    string projectType; // Single / EP / Album
    string upc; // 03600029145
  }

  /// @notice Storage for Credit
  struct Credit {
    string name;
    string collaboratorType;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
███████╗██████╗  ██████╗ ███████╗████████╗██╗   ██╗                 
██╔════╝██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝╚██╗ ██╔╝                 
█████╗  ██████╔╝██║   ██║███████╗   ██║    ╚████╔╝                  
██╔══╝  ██╔══██╗██║   ██║╚════██║   ██║     ╚██╔╝                   
██║     ██║  ██║╚██████╔╝███████║   ██║      ██║                    
╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝      ╚═╝                    
                                                                    
███╗   ███╗ ██████╗ ██████╗ ██╗   ██╗██╗      █████╗ ██████╗        
████╗ ████║██╔═══██╗██╔══██╗██║   ██║██║     ██╔══██╗██╔══██╗       
██╔████╔██║██║   ██║██║  ██║██║   ██║██║     ███████║██████╔╝       
██║╚██╔╝██║██║   ██║██║  ██║██║   ██║██║     ██╔══██║██╔══██╗       
██║ ╚═╝ ██║╚██████╔╝██████╔╝╚██████╔╝███████╗██║  ██║██║  ██║       
╚═╝     ╚═╝ ╚═════╝ ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       
                                                                    
██████╗ ██████╗  ██████╗ ████████╗ ██████╗  ██████╗ ██████╗ ██╗     
██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔═══██╗██╔════╝██╔═══██╗██║     
██████╔╝██████╔╝██║   ██║   ██║   ██║   ██║██║     ██║   ██║██║     
██╔═══╝ ██╔══██╗██║   ██║   ██║   ██║   ██║██║     ██║   ██║██║     
██║     ██║  ██║╚██████╔╝   ██║   ╚██████╔╝╚██████╗╚██████╔╝███████╗
╚═╝     ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝  ╚═════╝ ╚═════╝ ╚══════╝

*/

/// ============ Imports ============
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import "../interfaces/IOnChainMetadata.sol";

/// Shared NFT logic for rendering metadata associated with editions
/// @dev Can safely be used for generic base64Encode and numberToString functions
contract SharedNFTLogic is IOnChainMetadata {
  /// @param unencoded bytes to base64-encode
  function base64Encode(bytes memory unencoded)
    public
    pure
    returns (string memory)
  {
    return Base64.encode(unencoded);
  }

  /// Proxy to openzeppelin's toString function
  /// @param value number to return as a string
  function numberToString(uint256 value) public pure returns (string memory) {
    return Strings.toString(value);
  }

  /// Generate edition metadata from storage information as base64-json blob
  /// Combines the media data and metadata
  /// @param name the token name
  /// @param tokenOfEdition Token ID for specific token
  /// @param songMetadata song metadata
  /// @param projectMetadata project metadata
  /// @param credits The credits of the track
  /// @param tags The tags of the track
  function createMetadataEdition(
    string memory name,
    uint256 tokenOfEdition,
    SongMetadata memory songMetadata,
    ProjectMetadata memory projectMetadata,
    Credit[] memory credits,
    string[] memory tags
  ) external pure returns (string memory) {
    bytes memory json = createMetadataJSON(
      name,
      tokenOfEdition,
      songMetadata,
      projectMetadata,
      credits,
      tags
    );
    return encodeMetadataJSON(json);
  }

  /// Function to create the metadata json string for the nft edition
  /// @param name Name of NFT in metadata
  /// @param tokenOfEdition Token ID for specific token
  /// @param songMetadata metadata of the song
  /// @param projectMetadata metadata of the project
  /// @param credits The credits of the track
  /// @param tags The tags of the track
  function createMetadataJSON(
    string memory name,
    uint256 tokenOfEdition,
    SongMetadata memory songMetadata,
    ProjectMetadata memory projectMetadata,
    Credit[] memory credits,
    string[] memory tags
  ) public pure returns (bytes memory) {
    bool isMusicNft = bytes(
      songMetadata.song.audio.songDetails.audioQuantitative.audioMimeType
    ).length > 0;
    if (isMusicNft) {
      return
        createMusicMetadataJSON(
          songMetadata.songPublishingData.title,
          tokenOfEdition,
          songMetadata,
          projectMetadata,
          credits,
          tags
        );
    }
    return
      createBaseMetadataEdition(
        name,
        songMetadata.songPublishingData.description,
        songMetadata.song.artwork.artworkUri,
        songMetadata.song.audio.losslessAudio,
        tokenOfEdition
      );
  }

  /// Function to create the metadata json string for the nft edition
  /// @param name Name of NFT in metadata
  /// @param tokenOfEdition Token ID for specific token
  /// @param songMetadata metadata of the song
  /// @param projectMetadata metadata of the project
  /// @param credits The credits of the track
  /// @param tags The tags of the track
  function createMusicMetadataJSON(
    string memory name,
    uint256 tokenOfEdition,
    SongMetadata memory songMetadata,
    ProjectMetadata memory projectMetadata,
    Credit[] memory credits,
    string[] memory tags
  ) public pure returns (bytes memory) {
    bytes memory songMetadataFormatted = _formatSongMetadata(songMetadata);
    return
      abi.encodePacked(
        '{"version": "0.1", "name": "',
        name,
        " ",
        numberToString(tokenOfEdition),
        '",',
        songMetadataFormatted,
        ", ",
        _formatProjectMetadata(projectMetadata),
        ", ",
        _formatExtras(
          tokenOfEdition,
          songMetadata,
          projectMetadata,
          tags,
          credits
        ),
        "}"
      );
  }

  /// Generate edition metadata from storage information as base64-json blob
  /// Combines the media data and metadata
  /// @param name Name of NFT in metadata
  /// @param description Description of NFT in metadata
  /// @param imageUrl URL of image to render for edition
  /// @param animationUrl URL of animation to render for edition
  /// @param tokenOfEdition Token ID for specific token
  function createBaseMetadataEdition(
    string memory name,
    string memory description,
    string memory imageUrl,
    string memory animationUrl,
    uint256 tokenOfEdition
  ) public pure returns (bytes memory) {
    return
      abi.encodePacked(
        '{"name": "',
        name,
        " ",
        numberToString(tokenOfEdition),
        '", "',
        'description": "',
        description,
        '", "',
        tokenMediaData(imageUrl, animationUrl, tokenOfEdition),
        'properties": {"number": ',
        numberToString(tokenOfEdition),
        ', "name": "',
        name,
        '"}}'
      );
  }

  /// Generates edition metadata from storage information as base64-json blob
  /// Combines the media data and metadata
  /// @param imageUrl URL of image to render for edition
  /// @param animationUrl URL of animation to render for edition
  function tokenMediaData(
    string memory imageUrl,
    string memory animationUrl,
    uint256 tokenOfEdition
  ) public pure returns (string memory) {
    bool hasImage = bytes(imageUrl).length > 0;
    bool hasAnimation = bytes(animationUrl).length > 0;
    if (hasImage && hasAnimation) {
      return
        string(
          abi.encodePacked(
            'image": "',
            imageUrl,
            "?id=",
            numberToString(tokenOfEdition),
            '", "animation_url": "',
            animationUrl,
            "?id=",
            numberToString(tokenOfEdition),
            '", "'
          )
        );
    }
    if (hasImage) {
      return
        string(
          abi.encodePacked(
            'image": "',
            imageUrl,
            "?id=",
            numberToString(tokenOfEdition),
            '", "'
          )
        );
    }
    if (hasAnimation) {
      return
        string(
          abi.encodePacked(
            'animation_url": "',
            animationUrl,
            "?id=",
            numberToString(tokenOfEdition),
            '", "'
          )
        );
    }

    return "";
  }

  /// Encodes the argument json bytes into base64-data uri format
  /// @param json Raw json to base64 and turn into a data-uri
  function encodeMetadataJSON(bytes memory json)
    public
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked("data:application/json;base64,", base64Encode(json))
      );
  }

  function _formatSongMetadata(SongMetadata memory songMetadata)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        _formatAudio(songMetadata.song.audio),
        ",",
        _formatPublishingData(songMetadata.songPublishingData),
        ",",
        _formatArtwork("artwork", songMetadata.song.artwork),
        ",",
        _formatArtwork("visualizer", songMetadata.song.visualizer),
        ",",
        _formatLyrics(songMetadata.song.audio.lyrics),
        ',"image":"',
        songMetadata.song.artwork.artworkUri,
        '"'
      );
  }

  function _formatProjectMetadata(ProjectMetadata memory _metadata)
    internal
    pure
    returns (bytes memory output)
  {
    output = abi.encodePacked(
      '"project": {',
      '"title": "',
      _metadata.publishingData.title,
      '", "description": "',
      _metadata.publishingData.description,
      '", "type": "',
      _metadata.projectType,
      '", "originalReleaseDate": "',
      _metadata.publishingData.releaseDate
    );

    return bytes.concat(output, abi.encodePacked(
      '", "recordLabel": "',
      _metadata.publishingData.recordLabel,
      '", "publisher": "',
      _metadata.publishingData.publisher,
      '", "upc": "',
      _metadata.upc,
      '",',
      _formatArtwork("artwork", _metadata.artwork),
      "}"
    ));
  }

  function _formatAudio(Audio memory audio)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        '"losslessAudio": "',
        audio.losslessAudio,
        '","animation_url": "',
        audio.losslessAudio,
        '",',
        _formatSongDetails(audio.songDetails)
      );
  }

  function _formatSongDetails(SongDetails memory songDetails)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        '"artist": "',
        songDetails.artistName,
        '",',
        _formatAudioQuantitative(songDetails.audioQuantitative),
        ",",
        _formatAudioQualitative(songDetails.audioQualitative)
      );
  }

  function _formatAudioQuantitative(
    AudioQuantitative memory audioQuantitativeInfo
  ) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        '"key": "',
        audioQuantitativeInfo.key,
        '", "bpm": ',
        numberToString(audioQuantitativeInfo.bpm),
        ', "duration": ',
        numberToString(audioQuantitativeInfo.duration),
        ', "mimeType": "',
        audioQuantitativeInfo.audioMimeType,
        '", "trackNumber": ',
        numberToString(audioQuantitativeInfo.trackNumber)
      );
  }

  function _formatAudioQualitative(AudioQualitative memory audioQualitative)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        '"license": "',
        audioQualitative.license,
        '", "external_url": "',
        audioQualitative.externalUrl,
        '", "isrc": "',
        audioQualitative.isrc,
        '", "genre": "',
        audioQualitative.genre,
        '"'
      );
  }

  function _formatPublishingData(PublishingData memory _data)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        '"title": "',
        _data.title,
        '", "description": "',
        _data.description,
        '", "recordLabel": "',
        _data.recordLabel,
        '", "publisher": "',
        _data.publisher,
        '", "locationCreated": "',
        _data.locationCreated,
        '", "originalReleaseDate": "',
        _data.releaseDate,
        '", "name": "',
        _data.title,
        '"'
      );
  }

  function _formatArtwork(string memory _artworkLabel, Artwork memory _data)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        '"',
        _artworkLabel,
        '": {',
        '"uri": "',
        _data.artworkUri,
        '", "mimeType": "',
        _data.artworkMimeType,
        '", "nft": "',
        _data.artworkNft,
        '"}'
      );
  }

  function _formatExtras(
    uint256 tokenOfEdition,
    SongMetadata memory songMetadata,
    ProjectMetadata memory projectMetadata,
    string[] memory tags,
    Credit[] memory credits
  ) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        _formatAttributes(
          "attributes",
          tokenOfEdition,
          songMetadata.song.audio.songDetails,
          projectMetadata,
          songMetadata.songPublishingData
        ),
        ", ",
        _formatAttributes(
          "properties",
          tokenOfEdition,
          songMetadata.song.audio.songDetails,
          projectMetadata,
          songMetadata.songPublishingData
        ),
        ',"tags":',
        _getArrayString(tags),
        ', "credits": ',
        _getCollaboratorString(credits)
      );
  }

  function _formatLyrics(Lyrics memory _data)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        '"lyrics": {',
        '"text": "',
        _data.lyrics,
        '", "nft": "',
        _data.lyricsNft,
        '"}'
      );
  }

  function _formatAttributes(
    string memory _label,
    uint256 _tokenOfEdition,
    SongDetails memory _songDetails,
    ProjectMetadata memory _projectMetadata,
    PublishingData memory _publishingData
  )
    internal
    pure
    returns (bytes memory output)
  {
    AudioQuantitative memory _audioQuantitative = _songDetails
      .audioQuantitative;
    AudioQualitative memory _audioQualitative = _songDetails.audioQualitative;

    output = abi.encodePacked(
      '"',
      _label,
      '": {"number": ',
      numberToString(_tokenOfEdition),
      ', "bpm": ',
      numberToString(_audioQuantitative.bpm),
      ', "key": "',
      _audioQuantitative.key,
      '", "genre": "',
      _audioQualitative.genre
    );

    return bytes.concat(output, abi.encodePacked(
      '", "project": "',
      _projectMetadata.publishingData.title,
      '", "artist": "',
      _songDetails.artistName,
      '", "recordLabel": "',
      _publishingData.recordLabel,
      '", "license": "',
      _audioQualitative.license,
      '"}'
    ));
  }

  function _getArrayString(string[] memory _array)
    internal
    pure
    returns (string memory)
  {
    string memory _string = "[";
    for (uint256 i = 0; i < _array.length; i++) {
      _string = string(abi.encodePacked(_string, _getString(_array[i])));
      if (i < _array.length - 1) {
        _string = string(abi.encodePacked(_string, ","));
      }
    }
    _string = string(abi.encodePacked(_string, "]"));
    return _string;
  }

  function _getString(string memory _string)
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked('"', _string, '"'));
  }

  function _getCollaboratorString(Credit[] memory credits)
    internal
    pure
    returns (string memory)
  {
    string memory _string = "[";
    for (uint256 i = 0; i < credits.length; i++) {
      _string = string(abi.encodePacked(_string, '{"name":'));
      _string = string(abi.encodePacked(_string, _getString(credits[i].name)));
      _string = string(abi.encodePacked(_string, ',"collaboratorType":'));
      _string = string(
        abi.encodePacked(_string, _getString(credits[i].collaboratorType), "}")
      );
      if (i < credits.length - 1) {
        _string = string(abi.encodePacked(_string, ","));
      }
    }
    _string = string(abi.encodePacked(_string, "]"));
    return _string;
  }
}