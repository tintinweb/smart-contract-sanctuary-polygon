/**
 *Submitted for verification at polygonscan.com on 2023-04-16
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SignedMath.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol


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

// File: contracts/EIP5345.sol



// EIP-5345: Silent Signing Extension for JSON-RPC

pragma solidity ^0.8.11;

contract SilentSigner {

    struct PendingTransaction {
        address to;
        uint256 value;
        bytes data;
    }

    mapping(address => mapping(uint256 => PendingTransaction)) private _pendingTransactions;
    uint256 private _transactionCount;

    event LogTransactionSubmitted(address indexed user, uint256 indexed transactionId);

    //allows users to submit transactions by calling the submitTransaction function, 
    //which stores the transaction in a struct. The struct is stored in a mapping with the 
    //user's address and a transaction ID as the key
    function submitTransaction(address _to, uint256 _value, bytes memory _data) public {
        _pendingTransactions[msg.sender][_transactionCount] = PendingTransaction(_to, _value, _data);
        emit LogTransactionSubmitted(msg.sender, _transactionCount);
        _transactionCount++;
    }

    //off-chain signing service can then read the pending transaction from the 
    //smart contract using the getPendingTransaction function, sign it, and broadcast it to the blockchain
    function getPendingTransaction(address _user, uint256 _transactionId) public view returns (address to, uint256 value, bytes memory data) {
        PendingTransaction storage pendingTransaction = _pendingTransactions[_user][_transactionId];
        return (pendingTransaction.to, pendingTransaction.value, pendingTransaction.data);
    }
}
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol


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

// File: contracts/EIP5289.sol



pragma solidity ^0.8.11;

// import "https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5289.md";


contract ERC5289Library is IERC165 {
    event DocumentSigned(address indexed signer, uint16 indexed documentId);
    
    mapping (address => mapping (uint16 => uint64)) private signedTimestamps;
    mapping (uint16 => string) private documents;


    function legalDocument(uint16 documentId) external view returns (string memory) {
        return documents[documentId];
    }
    
    function documentSigned(address user, uint16 documentId) external view returns (bool signed) {
        return signedTimestamps[user][documentId] != 0;
    }

    function documentSignedAt(address user, uint16 documentId) external view returns (uint64 timestamp) {
        return signedTimestamps[user][documentId];
    }

    function signDocument(address signer, uint16 documentId) external {
        string memory empty = "";
        require(keccak256(bytes(documents[documentId])) != keccak256(bytes(empty)), "Document does not exist");
        require(signedTimestamps[signer][documentId] == 0, "Document already signed");
        signedTimestamps[signer][documentId] = uint64(block.timestamp);
        emit DocumentSigned(signer, documentId);
    }
    
    function addDocument(string memory document, uint16 documentId) external {
        string memory empty = "";
        require(keccak256(bytes(documents[documentId])) == keccak256(bytes(empty)), "Document already exists");
        documents[documentId] = document;
    }
    
    function removeDocument(uint16 documentId) external {
        string memory empty = "";
        require(keccak256(bytes(documents[documentId])) != keccak256(bytes(empty)), "Document does not exist");
        documents[documentId] = "";
    }
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        // return interfaceId == IERC165.interfaceId;
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }
}



contract DocumentSignerImpl is ERC5289Library {
    mapping (bytes32 => bytes) public documents;
    mapping (address => mapping (bytes32 => bool)) public signatures;
    mapping (address => mapping (bytes32 => uint64)) private signedTimestamps;

    event DocumentSignedHash(address indexed signer, bytes32 indexed hash);


    function offChainSignature(bytes memory _signedData) public {
        bytes32 documentHash = keccak256(abi.encodePacked(_signedData));
        require(!signatures[msg.sender][documentHash]);
        documents[documentHash] = _signedData;
        signatures[msg.sender][documentHash] = true;
        signedTimestamps[msg.sender][documentHash] = uint64(block.timestamp);
        emit DocumentSignedHash(msg.sender, documentHash);
    }

    function legalDocumentOffChain(bytes32 documentHash) external view returns (string memory) {
        return string(documents[documentHash]);
    }

    function documentSignedOffChain(address user, bytes32 documentHash) external view returns (bool signed) {
        return signatures[user][documentHash];
    }

    function documentSignedAtOffChain(address user, bytes32 documentHash) external view returns (uint64 timestamp) {
        return signedTimestamps[user][documentHash];
    }

    
}
// File: contracts/ERC5554.sol



pragma solidity ^0.8.11;

// import " https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5554.md";
// import "https://github.com/ethereum/EIPs/blob/master/assets/eip-5218/contracts/src/IERC5218.sol";

interface IERC5554  {
    event CommercialExploitation(uint256 _tokenId, uint256 _licenseId, string _externalUri);
    event ReproductionCreated(uint256 _tokenId, uint256 _licenseId, uint256 _reproductionId, address _reproduction, uint256 _reproductionTokenId);
    event DerivativeCreated(uint256 _tokenId, uint256 _licenseId, uint256 _derivativeId, address _derivative, uint256 _derivativeTokenId);
    event LicenseSet(uint indexed _tokenId, uint indexed _licenseId);

    function getCopyrightOwner(uint256 tokenId) external returns (address);
    function logReproduction(uint256 tokenId, address reproduction, uint256 reproductionTokenId) external  returns (uint256);
    function logDerivative(uint256 tokenId, address derivative, uint256 derivativeTokenId) external  returns (uint256);
    function logCommercialExploitation(uint256 tokenId, string calldata uri) external;
    function getReproduction(uint256 _reproductionId) external view returns (uint256, uint256, address);
    function getDerivative(uint256 _derivativeId) external view returns (uint256, uint256, address);
    function getLicense(uint256 _tokenId) external view returns (uint256);
    function setLicense(uint256 _tokenId, uint256 _licenseId) external;

}

contract EIP5554 {
    function isValidAddress(address _address) public pure returns (bool) {
        bytes memory addressBytes = abi.encodePacked(_address);
        // Check if the address is 20 bytes
        require(addressBytes.length == 20);
        // Check the address against the EIP-5554 check sum
        bytes32 checkSum = bytes32(keccak256(abi.encodePacked(addressBytes)));
        for (uint i = 0; i < addressBytes.length; i++) {
            if (i >= 2 && i <= 19) {
                // Check if the 4th byte of the check sum is uppercase
                if (uint8(checkSum[i >> 1]) > 87) {
                    if (uint(uint8(addressBytes[i])) < 97 || uint(uint8(addressBytes[i])) > 122) {
                        return false;
                    }
                } else {
                    if (uint(uint8(addressBytes[i])) < 65 || uint(uint8(addressBytes[i])) > 90) {
                        return false;
                    }
                }
            } else {
                // Check if the first 2 bytes and last byte are lowercase
                if (uint(uint8(addressBytes[i])) < 97 || uint(uint8(addressBytes[i])) > 122) {
                    return false;
                }
            }
        }
        return true;
    }
}

contract ERC5554 is IERC5554 {
    // Mapping of tokenId to copyright owner address
    mapping(uint256 => address) private tokenOwners;
    // Mapping of tokenId to licenseId
    mapping(uint256 => uint256) private tokenLicenses;
    // Mapping of licenseId to the number of reproductions generated
    mapping(uint256 => uint256) private licenseReproductionCount;
    // Mapping of licenseId to the number of derivatives generated
    mapping(uint256 => uint256) private licenseDerivativeCount;
    // Mapping of reproductionId to the tokenId used to generate the reproduction
    mapping(uint256 => uint256) private reproductionTokenIds;
    // Mapping of reproductionId to the licenseId used to generate the reproduction
    mapping(uint256 => uint256) private reproductionLicenseIds;
    // Mapping of reproductionId to the address of the reproduction collection
    mapping(uint256 => address) private reproductionCollections;
    // Mapping of derivativeId to the tokenId used to generate the derivative
    mapping(uint256 => uint256) private derivativeTokenIds;
    // Mapping of derivativeId to the licenseId used to generate the derivative
    mapping(uint256 => uint256) private derivativeLicenseIds;
    mapping (uint256 => address) public derivativeCollections;
    uint256 public nextReproductionId = 0;
    uint256 public nextDerivativeId = 0;


    function getCopyrightOwner(uint256 tokenId) external virtual returns (address) {
        return tokenOwners[tokenId];
    }

    function logReproduction(uint256 tokenId, address reproduction, uint256 reproductionTokenId) external virtual returns (uint256) {
        require(tokenOwners[tokenId] != address(0), "Token does not exist");
        reproductionTokenIds[nextReproductionId] = reproductionTokenId;
        reproductionLicenseIds[nextReproductionId] = tokenId;
        reproductionCollections[nextReproductionId] = reproduction;
        emit ReproductionCreated(tokenId, tokenId, nextReproductionId, reproduction, reproductionTokenId);
        return nextReproductionId++;
    }

    function logDerivative(uint256 _tokenId, address _derivative, uint256 _derivativeTokenId) external returns (uint256) {
        require(tokenOwners[_tokenId] == msg.sender, "Only the owner of the original token can log a derivative");
        uint256 derivativeId = licenseDerivativeCount[tokenLicenses[_tokenId]]++;
        derivativeTokenIds[derivativeId] = _tokenId;
        derivativeLicenseIds[derivativeId] = tokenLicenses[_tokenId];
        derivativeCollections[derivativeId] = _derivative;
        emit DerivativeCreated(_tokenId, tokenLicenses[_tokenId], derivativeId, _derivative, _derivativeTokenId);
        return derivativeId;
    }
    function logCommercialExploitation(uint256 _tokenId, string calldata _uri) external {
        require(tokenOwners[_tokenId] == msg.sender, "Only the owner of the original token can log commercial exploitation");
        emit CommercialExploitation(_tokenId, tokenLicenses[_tokenId], _uri);
    }

    function getReproduction(uint256 _reproductionId) external view returns (uint256, uint256, address) {
        return (reproductionTokenIds[_reproductionId], reproductionLicenseIds[_reproductionId], reproductionCollections[_reproductionId]);
    }

    function getDerivative(uint256 _derivativeId) external view returns (uint256, uint256, address) {
        return (derivativeTokenIds[_derivativeId], derivativeLicenseIds[_derivativeId], derivativeCollections[_derivativeId]);
    }

    function getLicense(uint256 _tokenId) external view returns (uint256) {
        return tokenLicenses[_tokenId];
    }

    function setLicense(uint256 _tokenId, uint256 _licenseId) external {
        require(tokenOwners[_tokenId] == msg.sender, "Only the owner of the original token can set the license");
        tokenLicenses[_tokenId] = _licenseId;
        emit LicenseSet(_tokenId, _licenseId);
    }
}
// File: contracts/EIP5453.sol



// EIP 5453 - Endorsment 
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5453.md

pragma solidity ^0.8.11;

// import "https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5453.md";

contract EIP5453 {
    struct ValidityBound {
        bytes32 functionParamStructHash;
        uint256 validSince;
        uint256 validBy;
        uint256 nonce;
    }

    struct SingleEndorsementData {
        address endorserAddress;
        bytes sig;
    }

    struct GeneralExtensionDataStruct {
        bytes32 erc5453MagicWord;
        uint256 erc5453Type;
        uint256 nonce;
        uint256 validSince;
        uint256 validBy;
        bytes endorsementPayload;
    }

    address public owner;

    constructor()  {
        owner = msg.sender;
    }

    function eip5453Nonce(address endorser) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(endorser, msg.sender)));
    }
    // Validates the Endroser
    function isEligibleEndorser(address endorser) public view returns (bool) {
        return endorser == owner;
    }

    // Validation Information 
    function computeValidityDigest(
        bytes32 _functionParamStructHash,
        uint256 _validSince,
        uint256 _validBy,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_functionParamStructHash, _validSince, _validBy, _nonce));
    }

    function computeFunctionParamHash(
        string memory _functionName,
        bytes memory _functionParamPacked
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_functionName, _functionParamPacked));
    }

    function computeExtensionDataTypeA(
        uint256 nonce,
        uint256 validSince,
        uint256 validBy,
        address endorserAddress,
        bytes calldata sig
    ) public pure returns (bytes memory) {
        return abi.encode(
            bytes32(uint256(0x3f3f3f3f)),
            uint256(1),
            nonce,
            validSince,
            validBy,
            abi.encodePacked(endorserAddress, sig)
        );
    }

    function computeExtensionDataTypeB(
        uint256 nonce,
        uint256 validSince,
        uint256 validBy,
        address[] calldata endorserAddress,
        bytes[] calldata sigs
    ) public pure returns (bytes memory) {

        bytes memory encoded;
        uint len = sigs.length;
        for (uint i = 0; i < len; i++) {
            encoded = bytes.concat(
                encoded,
                abi.encodePacked(endorserAddress[i],sigs[i])
            );
        }

        return abi.encode(
            bytes32(uint256(0x3f3f3f3f)),
            uint256(2),
            nonce,
            validSince,
            validBy,
            encoded
        );

           
    }
}
// File: contracts/IPNFT.sol



pragma solidity ^0.8.11;




// import "https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5554.md";
// import "https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5289.md";
// import "https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5453.md";




interface IERC5289Library is IERC165 {
    event DocumentSigned(address indexed signer, uint16 indexed documentId);
    function legalDocument(uint16 documentId) external view returns (string memory);
    function documentSigned(address user, uint16 documentId) external view returns (bool signed);
    function documentSignedAt(address user, uint16 documentId) external view returns (uint64 timestamp);
    function signDocument(address signer, uint16 documentId) external;
}

interface EndorsedDocs {

    function offChainSignature(bytes memory _signedData) external;
    function transferFrom(address _from, address _to, bytes32 _documentHash) external;
    function approve(address _to, bytes32 _documentHash) external;
    function signDocument(address _to, bytes32 _documentHash) external;
    function mint(address _to, bytes32 _documentHash, string memory _name, string memory _imageLink, string memory _uri, string memory _description) external;
    function addSigner(address _signer) external;
    function removeSigner(address _signer) external;
}

contract IntellectualPropertyNFT is EndorsedDocs, SilentSigner, ERC5554, EIP5453, ERC5289Library{
    mapping(address => mapping(bytes32 => bool)) private _documentSignature;
    mapping (address => mapping (bytes32 => bool)) public signatures;
    mapping(address => mapping(uint => bool)) private _signatureRequirement;
    mapping(address => mapping(bytes32 => bool)) private _balanceOf;
    mapping(bytes32 => address) private _ownerOf;
    mapping(uint => address) public tokenOwner;
    mapping (bytes32 => bytes) public documents;
    mapping(uint => string) public _license;
    
    mapping(address => mapping(address => mapping(bytes32 => bool))) private _approvals;
    address[] private _signers;
    mapping(uint => mapping(string => address[])) public licenses;
    uint public tokenId;

    struct Metadata {
    string name;
    string imageLink;
    string uri;
    string description;
}
    mapping(uint256=>Metadata) public ipMetadata;
    event Transfer(address indexed _to, address indexed _zero, bytes32 indexed _documentHash);
    event Approval(address indexed _sender, address indexed _to, bytes32 indexed _documentHash);

    function signDocument(address _to, bytes32 _documentHash) public {
        require(_signers.length > 0);
        // require(_signers[msg.sender]);
        _documentSignature[_to][_documentHash] = true;
    }

    function mint(address _to, bytes32 _documentHash, string memory _name, string memory _imageLink, string memory _uri, string memory _description) public {
        // require(_documentSignature[_to][_documentHash]);
        _documentSignature[_to][_documentHash] = true;
        _balanceOf[_to][_documentHash] = true;
        _ownerOf[_documentHash] = _to;
        Metadata memory _metadata = Metadata(_name, _imageLink, _uri, _description);
        ipMetadata[tokenId] = _metadata;
        tokenOwner[tokenId] = _to;
        tokenId = tokenId + 1;
        emit Transfer(_to, address(0), _documentHash);
    }

    modifier tokenExists(uint _id) {
        require(tokenOwner[_id] != address(0), "IP Nft does not exists");
        _;
    }
    function requestLicense(uint _tokenId) tokenExists(_tokenId) external {
        _license[_tokenId] = "Requested";
        licenses[_tokenId]["Requested"].push(msg.sender);
    }

    function rejectLicense(uint _tokenId)  tokenExists(_tokenId) external {
        _license[_tokenId] = "Rejected";
        licenses[_tokenId]["Rejected"].push(msg.sender);
    }

    function editLicense(uint _tokenId) tokenExists(_tokenId) external {
        _license[_tokenId] = "Edited";
        licenses[_tokenId]["Edited"].push(msg.sender);
    }

    function acceptLicense(uint _tokenId) tokenExists(_tokenId) external {
        _license[_tokenId] = "Accepted";
        licenses[_tokenId]["Accepted"].push(msg.sender);
    }


    function licenseLoop(uint _id, string memory _name) internal view returns(string memory) {
        string memory _addr = "";
        if (licenses[_id][_name].length > 0) {
            _addr = "[";
            for (uint i = 0; i < licenses[_id][_name].length; i++) {
                _addr = string.concat(_addr, Strings.toHexString(uint256(uint160(licenses[_id][_name][i])), 20));
                _addr = string.concat(_addr, ",");
            }
            _addr = string.concat(_addr, "]");
        }

        return _addr;
    }

    function licensesStatus(uint _id) public  view returns(string memory) {
      

        string memory _acceptedAddr = licenseLoop(_id, "Accepted");
        string memory _rejectedAddr = licenseLoop(_id, "Rejected");
        string memory _requestedAddr = licenseLoop(_id, "Requested");
        string memory _editedAddr = licenseLoop(_id, "Edited");
        

        string memory detail = string(
            abi.encodePacked(
                '{"Accepted":"',
                _acceptedAddr,
                '","Rejected":"',
                _rejectedAddr,
                '","Requested":"',
                _requestedAddr,
                '","Edited":"',
                _editedAddr,
                '"}'
            )
        );

        return detail;
    }

    // Approving ERC-5554 NFTs
    function approve(address _to, bytes32 _documentHash) external {
        require(_balanceOf[msg.sender][_documentHash]);
        _approvals[msg.sender][_to][_documentHash] = true;
        emit Approval(msg.sender, _to, _documentHash);
    }

    // Transferring ERC-5554 NFTs
    function transferFrom(address _from, address _to, bytes32 _documentHash) public {
        require(_balanceOf[_from][_documentHash]);
        require(_approvals[_from][msg.sender][_documentHash]);
        _balanceOf[_from][_documentHash] = false;
        _balanceOf[_to][_documentHash] = true;
        _ownerOf[_documentHash] = _to;
        emit Transfer(_from, _to, _documentHash);
    }

    function tokenURI(uint256 _id) public view returns (string memory) {
        require(tokenOwner[_id] != address(0), "IP Nft does not exists");
        Metadata memory metadata = ipMetadata[_id];
        string memory detail = string(
            abi.encodePacked(
                '{"name":"',
                metadata.name,
                '","imageLink":"',
                metadata.imageLink,
                '","uri":"',
                metadata.uri,
                '","description":"',
                metadata.description,
                '","license":"',
                _license[_id],
                '"}'
            )
        );
        return detail;
    }

    // Adding signers for ERC-5554 NFTs
    function addSigner(address _signer) public {
        require(msg.sender == owner);
        _signers.push(_signer);
    }

    // Removing signers for ERC-5554 NFTs
    function removeSigner(address _signer) public {
        require(msg.sender == owner);
        for (uint256 i = 0; i < _signers.length; i++) {
            if (_signers[i] == _signer) {
                delete _signers[i];
                break;
            }
        }
    }


    // Requiring signature for ERC-5554 NFTs
    function requireSignature(address _signer, uint256 _nftId) public {
        require(msg.sender == owner);
        _signatureRequirement[_signer][_nftId] = true;
    }

    function offChainSignature(bytes memory _signedData) public {
        bytes32 documentHash = keccak256(abi.encodePacked(_signedData));
        require(!signatures[msg.sender][documentHash]);
        documents[documentHash] = _signedData;
        signatures[msg.sender][documentHash] = true;
        emit DocumentSigned(msg.sender, uint16(uint(documentHash)));
    }

     
}