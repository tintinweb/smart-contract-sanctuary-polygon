/**
 *Submitted for verification at polygonscan.com on 2023-07-01
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-16
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-08
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface MultiSigStruct {
    // Batch Import Strcut
    struct BatchNFTsStruct {
        uint256[] tokenIds;
        address contractAddress;
    }
}

interface SegMintNFTVault is MultiSigStruct {
    function isLocked(address contractAddress, uint256 tokenId)
        external
        view
        returns (bool);

    function batchLockNFTs(BatchNFTsStruct[] memory lockData) external;

    function batchUnlockNFTs(BatchNFTsStruct[] memory lockData) external;
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

// SegMint Multi-Sig Interface
interface MultiSigInterface is MultiSigStruct {
    // Signer Proposal Struct
    struct SignerProposal {
        uint256 ID;
        address PROPOSER;
        address MODIFIEDSIGNER;
        SignerProposalType UPDATETYPE; // ADD or REMOVE
        uint256 EXPIRATION; // expiration timestamp
        uint256 APPROVEDCOUNT;
        bool ISEXECUTED;
        bool ISREVOKED;
    }

    // Signatory Proposal Type
    enum SignerProposalType {
        ADD_SIGNER,
        REMOVE_SIGNER
    }

    // Min Signature Proposal to manage minimum signers
    struct MinSignatureProposal {
        uint256 ID;
        address PROPOSER;
        uint256 MINSIGNATURE;
        uint256 APPROVEDCOUNT;
        bool ISEXECUTED;
        bool ISREVOKED;
        uint256 EXPIRATION;
    }

    // Lock / Unlock Proposal Type
    enum LockOrUnlockProposalType {
        LOCK,
        UNLOCK
    }

    // Lock or Unlock Proposal Struct
    struct LockOrUnlockProposal {
        uint256 ID;
        address PROPOSER;
        address SegMintVault;
        LockOrUnlockProposalType PROPOSALTYPE; // LOCK OR UNLOCK
        uint256 APPROVEDCOUNT;
        bool ISEXECUTED;
        bool ISREVOKED;
        uint256 EXPIRATION;
    }

    // add a new signer to signatories
    function addSigner(address newSigner_, uint256 expiration_) external;

    // remove a signer from signatories
    function removeSigner(address signer_, uint256 expiration_) external;

    // approve signer proposal
    function approveSignerProposal(uint256 signerProposalID_) external;

    // revoke signer proposal
    function revokeSignerProposal(uint256 signerProposalID_) external;

    // Create a proposal to change the minimum signer requirement
    function minSignatureProposal(uint256 newMinSignature_, uint256 expiration_)
        external;

    // approve signer proposal
    function approveMinSignatureProposal(uint256 minSignatureProposalID_)
        external;

    // dissapprove signer proposal
    function revokeMinSignatureProposal(uint256 minSignatureProposalID_)
        external;

    // create lock proposal
    function createLockProposal(
        BatchNFTsStruct[] memory lockData_,
        address SegMintVault_,
        uint256 expiration_
    ) external;

    // create unlock proposal
    function createUnlockProposal(
        BatchNFTsStruct[] memory lockData_,
        address SegMintVault_,
        uint256 expiration_
    ) external;

    // approve lock or unlock proposal
    function approveLockorUnlockProposal(uint256 lockorUnlockProposalID_)
        external;

    // revoke lock or unlock proposal
    function revokeLockorUnlockProposal(uint256 lockorUnlockProposalID_)
        external;

    // get contract version
    function getContractVersion() external view returns (uint256);

    // get signatories
    function getSignatories() external view returns (address[] memory);

    // is signer
    function IsSigner(address account_) external view returns (bool);

    // get min signature
    function getMinSignature() external view returns (uint256);

    // get signer proposal counts
    function getSignerProposalCount() external view returns (uint256);

    // get min signature proposal counts
    function getMinSignatureProposalCount() external view returns (uint256);

    // get signer proposal detail
    function getSignerProposalDetail(uint256 signerProposalID_)
        external
        view
        returns (SignerProposal memory);

    // is signer proposal approver
    function isSignerProposalApprover(
        uint256 signerProposalID_,
        address account_
    ) external view returns (bool);

    // get MinSignature proposal detail
    function getMinSignatureProposalDetail(uint256 MinSignatureProposalID_)
        external
        view
        returns (MinSignatureProposal memory);

    // is Min Signature proposal approver
    function isMinSignatureProposalApprover(
        uint256 MinSignatureProposalID_,
        address account_
    ) external view returns (bool);

    // get lock or unlock proposal counts
    function getLockOrUnlockProposalCount() external view returns (uint256);

    // get lock or unlock proposal detail
    function getLockOrUnlockProposalDetail(uint256 lockOrUnlockProposalID_)
        external
        view
        returns (LockOrUnlockProposal memory);

    // is lock or unlock proposal approver
    function isLockOrUnlockProposalApprover(
        uint256 lockOrUnlockProposalID_,
        address account_
    ) external view returns (bool);

    // get batch lock info
    function getBatchLockInfo(uint256 lockOrUnlockProposalID_)
        external
        view
        returns (BatchNFTsStruct[] memory);

    // get batch unlock info
    function getBatchUnlockInfo(uint256 lockOrUnlockProposalID_)
        external
        view
        returns (BatchNFTsStruct[] memory);

    // get list of NFT Contract Addresses locked
    function getLockedNFTContractAddresses() external view returns (address[] memory);

    // get list of Token IDs locked for a NFT
    function getLockedTokenIDs(address NFTContractAddress_) external view returns (uint256[] memory);
}

// SegMint Multi-Sig Contract
contract MultiSig is MultiSigInterface {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // contract version
    uint256 private _contractVersion = 1;

    /////    Multi-Sig signer    ////

    // list of signatories
    address[] private _signatories;

    // check if an address is a signer: address => status(true/false)
    mapping(address => bool) private _isSigner;

    // minimum signatures required for a proposal
    uint256 private _minSignatures;

    // signer proposal counter
    uint256 private _signerProposalCount;

    // min signature proposal counter
    uint256 private _minSignatureProposalCount;

    ////    Signer Proposals    ////

    // list of proposals info: proposal ID => proposal detail
    mapping(uint256 => SignerProposal) private _signerProposals;

    // signer proposal approvers
    mapping(uint256 => mapping(address => bool))
        private _signerProposalApprovers;

    ////    Min Signature Proposals    ////

    // min signature proposal detail
    mapping(uint256 => MinSignatureProposal) private _minSignatureProposals;

    // signer min signature proposal approvers
    mapping(uint256 => mapping(address => bool))
        private _minSignatureProposalApprovers;

    ////    Multi-Sig Locking and Unlocking    ////

    // lock or unlock proposal counter
    uint256 private _lockOrUnlockProposalCount;

    // list of lock proposals info: locked proposal ID => lock proposal detail
    mapping(uint256 => LockOrUnlockProposal) private _lockOrUnlockProposals;

    // list of unlock proposal approvers: unlock proposal ID => address => status(true/false)
    mapping(uint256 => mapping(address => bool))
        private _lockOrUnlockProposalApprovers;

    // locked assets info by lock ID: lock ID => Batch NFTs Struct
    mapping(uint256 => BatchNFTsStruct[]) private _batchLockInfo;

    // unlocked assets info by unlock ID: unlock ID => Batch NFTs Struct
    mapping(uint256 => BatchNFTsStruct[]) private _batchUnlockInfo;

    // list of NFT contract addresses locked
    address[] private _NFTContractAddressesLocked;

    // is NFT Contract Address Locked
    mapping(address => bool) private _isNFTLocked;

    // list of Token IDs of an NFT locked
    mapping(address => uint256[]) private _TokenIDsLocked;

    // is Token ID of an NFT locked
    mapping(address => mapping(uint256 => bool)) private _isTokenIDLocked;

    ///////////////////////
    //    constructor    //
    ///////////////////////

    // constructor
    constructor(
        address deployer,
        uint256 minSignatures_,
        address[] memory signatories_
    ) {
        // require valid initialization
        require(
            minSignatures_ > 0 && minSignatures_ <= signatories_.length,
            "Multi-Sig: Invalid min signatures!"
        );

        // set min singatures
        _minSignatures = minSignatures_;

        // add signers
        for (uint256 i = 0; i < signatories_.length; i++) {
            // signer address
            address signer = signatories_[i];
            // require non zero address
            require(signer != address(0), "Multi-Sig: Invalid signer address!");
            // require not duplicated signer
            require(!_isSigner[signer], "Multi-Sig: Duplicate signer address!");
            // add signer
            _signatories.push(signer);
            // update is signer status
            _isSigner[signer] = true;
            // emit execute add signer proposal
            emit AddSignerProposalExecuted(
                deployer,
                signer,
                0,
                block.timestamp
            );
        }
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // create add signer proposal
    event AddSignerProposalCreated(
        address indexed proposer,
        uint256 signerProposalCount,
        address indexed newSigner,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute add signer proposal
    event AddSignerProposalExecuted(
        address indexed executor,
        address indexed newSigner,
        uint256 signerProposalCount,
        uint256 indexed timestamp
    );

    // create remove signer proposal
    event RemoveSignerProposalCreated(
        address indexed proposer,
        uint256 signerProposalCount,
        address indexed signer,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute remove signer proposal
    event RemoveSignerProposalExecuted(
        address indexed executor,
        address indexed signer,
        uint256 signerProposalCount,
        uint256 indexed timestamp
    );

    // approve signer proposal (add or remove)
    event SignerProposalApproved(
        address indexed approver,
        uint256 indexed signerProposalID,
        uint256 indexed timestamp
    );

    // revoke signer proposal by proposer
    event SignerProposalRevoked(
        address indexed proposer,
        uint256 indexed signerProposalID,
        uint256 indexed timestamp
    );

    // create Min Signer proposal
    event MinSignatureProposalCreated(
        address indexed proposer,
        uint256 indexed proposalID,
        uint256 minSignatures,
        uint256 expireation,
        uint256 indexed timestamp
    );

    // execute min signature proposal
    event MinSignatureProposalExecuted(
        address indexed Sender,
        uint256 indexed proposalID,
        uint256 OldMinSignatures,
        uint256 newMinSignatures,
        uint256 indexed timestamp
    );

    // approved proposal
    event MinSignatureProposalApproved(
        address indexed approver,
        uint256 indexed proposalID,
        uint256 indexed timestamp
    );

    // revoke min signature proposal by proposer
    event MinSignatureProposalRevoked(
        address indexed proposer,
        uint256 indexed proposalID,
        uint256 indexed timestamp
    );

    // create lock proposal
    event LockProposalCreated(
        address indexed proposer,
        uint256 indexed proposalID,
        BatchNFTsStruct[] data,
        uint256 expiration_,
        uint256 indexed timestamp
    );

    // execute lock proposal
    event LockProposalExecuted(
        address indexed executor,
        uint256 indexed proposalID,
        uint256 indexed timestamp
    );

    // create unlock proposal
    event UnlockProposalCreated(
        address indexed proposer,
        uint256 indexed proposalID,
        BatchNFTsStruct[] data,
        uint256 indexed timestamp
    );

    // execute unlock proposal
    event UnlockProposalExecuted(
        address indexed executor,
        uint256 indexed proposalID,
        uint256 indexed timestamp
    );

    // approve lock or unlock  proposal
    event LockOrUnlockProposalApproved(
        address indexed approver,
        uint256 indexed proposalID,
        uint256 indexed timestamp
    );

    // revoked lock or unlock proposal
    event LockOrUnlockProposalRevoked(
        address indexed proposer,
        uint256 indexed proposalID,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only signatories
    modifier onlySignatories() {
        // require msg.sender be a signer
        require(
            _isSigner[msg.sender],
            "Multi-Sig: Sender is not an authorized signer!"
        );
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        require(
            account_ != address(0),
            "Multi-Sig: Address should not be zero address!"
        );
        _;
    }

    // only valid signer proposal id
    modifier onlyValidSignerProposalID(uint256 signerProposalID_) {
        // require a valid proposal ID
        require(
            signerProposalID_ != 0 && signerProposalID_ <= _signerProposalCount,
            "Multi-Sig: Invalid signer proposal ID!"
        );
        _;
    }

    // only signer proposal Proposer
    modifier onlyProposer(uint256 signerProposalID_) {
        // require sender be the proposer
        require(
            msg.sender == _signerProposals[signerProposalID_].PROPOSER,
            "Multi-Sig: Sender is not proposer!"
        );
        _;
    }

    // only valid min signature proposal id
    modifier onlyValidMinSignatureProposalID(uint256 minSignatureProposalID_) {
        // require alid proposal ID
        require(
            minSignatureProposalID_ != 0 &&
                minSignatureProposalID_ <= _minSignatureProposalCount,
            "Multi-Sig: Invalid min signature proposal ID!"
        );
        _;
    }

    // only min signature proposal proposer
    modifier onlyMinSignatureProposer(uint256 minSignatureProposalID_) {
        // require sender be proposer
        require(
            msg.sender ==
                _minSignatureProposals[minSignatureProposalID_].PROPOSER,
            "Multi-Sig: Sender is not proposer!"
        );
        _;
    }

    // only valid lock or unlock proposal ID
    modifier onlyValidLockOrUnlockProposalID(uint256 lockorUnlockProposalID_) {
        // require valid ID
        require(
            lockorUnlockProposalID_ != 0 &&
                lockorUnlockProposalID_ <= _lockOrUnlockProposalCount,
            "Multi-Sig: Invalid proposal ID!"
        );
        _;
    }

    // only lock or unlock proposer
    modifier onlyLockOrUnlockProposer(uint256 lockorUnlockProposalID_) {
        // require sender be proposer
        require(
            msg.sender ==
                _lockOrUnlockProposals[lockorUnlockProposalID_].PROPOSER,
            "Multi-Sig: Sender is not proposer!"
        );
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    ////    Signatory Management    ////

    // add a new signer to signatories
    function addSigner(address newSigner_, uint256 expiration_)
        public
        onlySignatories
        notNullAddress(newSigner_)
    {
        // require account not be a signer
        require(
            !_isSigner[newSigner_],
            "Multi-Sig: Signer address already added!"
        );

        // create a proposal for new signer
        // increment signer proposal ID
        ++_signerProposalCount;

        // add the proposal
        _signerProposals[_signerProposalCount] = SignerProposal({
            ID: _signerProposalCount,
            PROPOSER: msg.sender,
            MODIFIEDSIGNER: newSigner_,
            UPDATETYPE: SignerProposalType.ADD_SIGNER,
            ISEXECUTED: false,
            EXPIRATION: expiration_,
            ISREVOKED: false,
            APPROVEDCOUNT: 1
        });

        // approve by sender
        _signerProposalApprovers[_signerProposalCount][msg.sender] = true;

        // emit event
        emit AddSignerProposalCreated(
            msg.sender,
            _signerProposalCount,
            newSigner_,
            expiration_,
            block.timestamp
        );

        // execute the proposal if there is only one signagory
        if (_signatories.length == 1 || _minSignatures == 1) {
            // add the new signer directly: no need to create proposal
            // add to the signatories
            _signatories.push(newSigner_);

            // update signer status
            _isSigner[newSigner_] = true;

            // update is executed
            _signerProposals[_signerProposalCount].ISEXECUTED = true;

            // emit execution event
            emit AddSignerProposalExecuted(
                msg.sender,
                newSigner_,
                _signerProposalCount,
                block.timestamp
            );
        }
    }

    // remove a signer from signatories
    function removeSigner(address signer_, uint256 expiration_)
        public
        onlySignatories
        notNullAddress(signer_)
    {
        // require address be a signer
        require(_isSigner[signer_], "Multi-Sig: Signer address not found!");

        // require having more signers than min signature
        require(
            _signatories.length > _minSignatures && _signatories.length > 1,
            "Multi-Sig: Min Signatures should be less than the number of signers!"
        );

        // create a proposal for removing signer
        // increment signer proposal ID
        ++_signerProposalCount;

        // add proposal
        _signerProposals[_signerProposalCount] = SignerProposal({
            ID: _signerProposalCount,
            PROPOSER: msg.sender,
            MODIFIEDSIGNER: signer_,
            UPDATETYPE: SignerProposalType.REMOVE_SIGNER,
            ISEXECUTED: false,
            EXPIRATION: expiration_,
            ISREVOKED: false,
            APPROVEDCOUNT: 1
        });

        // approve the proposal by sender
        _signerProposalApprovers[_signerProposalCount][msg.sender] = true;

        // emit event
        emit RemoveSignerProposalCreated(
            msg.sender,
            _signerProposalCount,
            signer_,
            expiration_,
            block.timestamp
        );

        // execute proposl if following criteria satisfied
        if (_signatories.length >= 2 && _minSignatures == 1) {
            // remove signer
            _isSigner[signer_] = false;
            for (uint256 i = 0; i < _signatories.length; i++) {
                if (_signatories[i] == signer_) {
                    _signatories[i] = _signatories[_signatories.length - 1];
                    break;
                }
            }
            _signatories.pop();

            // update is executed
            _signerProposals[_signerProposalCount].ISEXECUTED = true;

            // emit execution event
            emit RemoveSignerProposalExecuted(
                msg.sender,
                signer_,
                _signerProposalCount,
                block.timestamp
            );
        }
    }

    // approve signer proposal
    function approveSignerProposal(uint256 signerProposalID_)
        public
        onlySignatories
        onlyValidSignerProposalID(signerProposalID_)
    {
        // proposal info
        SignerProposal storage proposal = _signerProposals[signerProposalID_];

        // require a valid proposer (if by address(0) then this is not valid)
        require(
            proposal.PROPOSER != address(0),
            "Multi-Sig: Not valid proposal!"
        );

        // require proposal not being executed, revoked, expired or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION < block.timestamp ||
                _signerProposalApprovers[signerProposalID_][msg.sender]),
            "Multi-Sig: Proposal is already executed, revoked, expired or approved by sender!"
        );

        // update proposal approved by sender status
        _signerProposalApprovers[signerProposalID_][msg.sender] = true;

        // increment approved count
        proposal.APPROVEDCOUNT++;

        // emit approve signer proposal
        emit SignerProposalApproved(
            msg.sender,
            signerProposalID_,
            block.timestamp
        );

        // execute the proposal if enough signatories have approved it
        if (proposal.APPROVEDCOUNT >= _minSignatures) {
            // signer proposal type: ADD or REMOVE
            if (proposal.UPDATETYPE == SignerProposalType.ADD_SIGNER) {
                // add the new signer
                _signatories.push(proposal.MODIFIEDSIGNER);

                // update role
                _isSigner[proposal.MODIFIEDSIGNER] = true;

                // update is executed
                proposal.ISEXECUTED = true;

                // emit execution event
                emit AddSignerProposalExecuted(
                    msg.sender,
                    proposal.MODIFIEDSIGNER,
                    signerProposalID_,
                    block.timestamp
                );
            } else {
                // remove signer
                _isSigner[proposal.MODIFIEDSIGNER] = false;
                for (uint256 i = 0; i < _signatories.length; i++) {
                    if (_signatories[i] == proposal.MODIFIEDSIGNER) {
                        _signatories[i] = _signatories[_signatories.length - 1];
                        break;
                    }
                }
                _signatories.pop();

                // update is executed
                proposal.ISEXECUTED = true;

                // emit execution event
                emit RemoveSignerProposalExecuted(
                    msg.sender,
                    proposal.MODIFIEDSIGNER,
                    signerProposalID_,
                    block.timestamp
                );
            }
        }
    }

    // revoke signer proposal
    function revokeSignerProposal(uint256 signerProposalID_)
        public
        onlySignatories
        onlyProposer(signerProposalID_)
        onlyValidSignerProposalID(signerProposalID_)
    {
        // proposal info
        SignerProposal storage proposal = _signerProposals[signerProposalID_];

        // require proposal not being executed, revoked, expired or revoked by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION < block.timestamp),
            "Multi-Sig: Proposal is already executed, revoked, expired or revoked by sender!"
        );

        // update is revoked
        proposal.ISREVOKED = true;

        // emit revoke signer proposal
        emit SignerProposalRevoked(
            msg.sender,
            signerProposalID_,
            block.timestamp
        );
    }

    ////    Min Signatures Management    ////

    // Create a proposal to change the minimum signer requirement
    function minSignatureProposal(uint256 newMinSignature_, uint256 expiration_)
        public
        onlySignatories
    {
        require(
            newMinSignature_ > 0,
            "Multi-Sig: Invalid minimum signature value!"
        );
        require(
            _minSignatures != newMinSignature_,
            "Multi-Sig: Minimum Signatories already set"
        );
        require(
            newMinSignature_ <= _signatories.length,
            "Multi-Sig: Min SIgnature Cannot exceed signatories"
        );
        // Create a new proposal ID
        ++_minSignatureProposalCount;

        // Create the proposal
        _minSignatureProposals[
            _minSignatureProposalCount
        ] = MinSignatureProposal({
            ID: _minSignatureProposalCount,
            PROPOSER: msg.sender,
            MINSIGNATURE: newMinSignature_,
            APPROVEDCOUNT: 1,
            ISEXECUTED: false,
            ISREVOKED: false,
            EXPIRATION: expiration_
        });

        // Approve the proposal by the sender
        _minSignatureProposalApprovers[_minSignatureProposalCount][
            msg.sender
        ] = true;

        // Emit event
        emit MinSignatureProposalCreated(
            msg.sender,
            _minSignatureProposalCount,
            newMinSignature_,
            expiration_,
            block.timestamp
        );

        // execute if there is only one signatory
        if (_signatories.length == 1 || _minSignatures == 1) {
            // old min signature
            uint256 oldMinSignature = _minSignatures;

            // update is executed
            _minSignatureProposals[_minSignatureProposalCount]
                .ISEXECUTED = true;

            // udpate min signature
            _minSignatures = newMinSignature_;

            // emit event
            emit MinSignatureProposalExecuted(
                msg.sender,
                _minSignatureProposalCount,
                oldMinSignature,
                newMinSignature_,
                block.timestamp
            );
        }
    }

    // approve signer proposal
    function approveMinSignatureProposal(uint256 minSignatureProposalID_)
        public
        onlySignatories
        onlyValidMinSignatureProposalID(minSignatureProposalID_)
    {
        // proposal info
        MinSignatureProposal storage proposal = _minSignatureProposals[
            minSignatureProposalID_
        ];

        // require a valid proposer (if by address(0) then this is not valid)
        require(
            proposal.PROPOSER != address(0),
            "Multi-Sig: Not valid proposal!"
        );

        // require proposal not being executed, revoked, expired or already been approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION < block.timestamp ||
                _minSignatureProposalApprovers[minSignatureProposalID_][
                    msg.sender
                ]),
            "Multi-Sig: Proposal already executed, revoked, expired or approved by sender!"
        );

        // approve proposal by sender
        _minSignatureProposalApprovers[minSignatureProposalID_][
            msg.sender
        ] = true;

        // update approved count
        proposal.APPROVEDCOUNT++;

        // emit event
        emit MinSignatureProposalApproved(
            msg.sender,
            minSignatureProposalID_,
            block.timestamp
        );

        // execute if enough signatories have approved the proposal
        if (proposal.APPROVEDCOUNT >= _minSignatures) {
            // old min signatures
            uint256 oldMinSignature = _minSignatures;

            // update min signatures
            _minSignatures = proposal.MINSIGNATURE;

            // update is executed
            proposal.ISEXECUTED = true;

            // emit event
            emit MinSignatureProposalExecuted(
                msg.sender,
                minSignatureProposalID_,
                oldMinSignature,
                proposal.MINSIGNATURE,
                block.timestamp
            );
        }
    }

    // dissapprove signer proposal
    function revokeMinSignatureProposal(uint256 minSignatureProposalID_)
        public
        onlySignatories
        onlyMinSignatureProposer(minSignatureProposalID_)
        onlyValidMinSignatureProposalID(minSignatureProposalID_)
    {
        // proposal info
        MinSignatureProposal storage proposal = _minSignatureProposals[
            minSignatureProposalID_
        ];

        // require proposal not being executed, revoked, expired, or already revoked by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION < block.timestamp),
            "Multi-Sig: Proposal already executed, revoked, expired or revoked by sender!"
        );

        // change the revoked status
        proposal.ISREVOKED = true;

        // emit event
        emit MinSignatureProposalRevoked(
            msg.sender,
            minSignatureProposalID_,
            block.timestamp
        );
    }

    ////    Lock / Unlock Management    ////

    // create lock proposal
    function createLockProposal(
        BatchNFTsStruct[] memory lockData_,
        address SegMintVault_,
        uint256 expiration_
    ) public onlySignatories {
        // require data be passed
        require(lockData_.length > 0, "Multi-Sig: No unlock data provided!");

        // increment lock or unlock proposal ID
        ++_lockOrUnlockProposalCount;

        // create lock proposal
        _lockOrUnlockProposals[
            _lockOrUnlockProposalCount
        ] = LockOrUnlockProposal({
            ID: _lockOrUnlockProposalCount,
            PROPOSER: msg.sender,
            SegMintVault: SegMintVault_,
            PROPOSALTYPE: LockOrUnlockProposalType.LOCK,
            APPROVEDCOUNT: 1,
            ISEXECUTED: false,
            ISREVOKED: false,
            EXPIRATION: expiration_
        });

        // add lock proposal
        for (uint256 i = 0; i < lockData_.length; i++) {
            // lockData info
            BatchNFTsStruct memory data = lockData_[i];

            // require non-zero contract address
            require(
                data.contractAddress != address(0),
                "Multi-Sig: Invalid contract address!"
            );

            for (uint256 j = 0; j < data.tokenIds.length; j++) {
                // require entered tokenID
                require(
                    data.tokenIds.length != 0,
                    "Multi-Sig: Invalid token ID!"
                );

                // require NFTs not be locked
                require(
                    !SegMintNFTVault(SegMintVault_).isLocked(
                        data.contractAddress,
                        data.tokenIds[j]
                    ),
                    string.concat(
                        "Multi-Sig : ",
                        "Token Id",
                        Strings.toString(data.tokenIds[j]),
                        "of Contract Address",
                        Strings.toHexString(data.contractAddress),
                        " is already locked!"
                    )
                );
                // add proposal
                _batchLockInfo[_lockOrUnlockProposalCount].push(lockData_[i]);
            }
        }

        // approve the lock proposal by sender
        _lockOrUnlockProposalApprovers[_lockOrUnlockProposalCount][
            msg.sender
        ] = true;

        // emit event
        emit LockProposalCreated(
            msg.sender,
            _lockOrUnlockProposalCount,
            lockData_,
            expiration_,
            block.timestamp
        );

        // execute if sender is the only signatory
        if (_signatories.length == 1 || _minSignatures == 1) {
            // change the is executed status
            _lockOrUnlockProposals[_lockOrUnlockProposalCount]
                .ISEXECUTED = true;

            // call SegMint Vault and batch lock NFTs
            SegMintNFTVault(SegMintVault_).batchLockNFTs(
                _batchLockInfo[_lockOrUnlockProposalCount]
            );

            // add NFTs to locked NFTs
            _addBatchNFTsToLockedNFTs(lockData_);

            // emit event
            emit LockProposalExecuted(
                msg.sender,
                _lockOrUnlockProposalCount,
                block.timestamp
            );
        }
    }

    // create unlock proposal
    function createUnlockProposal(
        BatchNFTsStruct[] memory lockData_,
        address SegMintVault_,
        uint256 expiration_
    ) public onlySignatories {
        // require data be passed
        require(lockData_.length > 0, "Multi-Sig: No unlock data provided!");

        // increment lock or unlock proposal ID
        ++_lockOrUnlockProposalCount;

        // create lock proposal
        _lockOrUnlockProposals[
            _lockOrUnlockProposalCount
        ] = LockOrUnlockProposal({
            ID: _lockOrUnlockProposalCount,
            PROPOSER: msg.sender,
            SegMintVault: SegMintVault_,
            PROPOSALTYPE: LockOrUnlockProposalType.UNLOCK,
            APPROVEDCOUNT: 1,
            ISEXECUTED: false,
            ISREVOKED: false,
            EXPIRATION: expiration_
        });

        // add unlock proposal
        for (uint256 i = 0; i < lockData_.length; i++) {
            // lockData info
            BatchNFTsStruct memory data = lockData_[i];

            // require non-zero contract address
            require(
                data.contractAddress != address(0),
                "Multi-Sig: Invalid contract address!"
            );

            for (uint256 j = 0; j < data.tokenIds.length; j++) {
                // require entered tokenID
                require(
                    data.tokenIds.length != 0,
                    "Multi-Sig: Invalid token ID!"
                );
                require(
                    SegMintNFTVault(SegMintVault_).isLocked(
                        data.contractAddress,
                        data.tokenIds[j]
                    ),
                    string.concat(
                        "Multi-Sig : ",
                        "Token Id",
                        Strings.toString(data.tokenIds[j]),
                        "of Contract Address",
                        Strings.toHexString(data.contractAddress),
                        " is not locked!"
                    )
                );
                // add proposal
                _batchUnlockInfo[_lockOrUnlockProposalCount].push(lockData_[i]);
            }
        }

        // approve the ulock proposal by sender
        _lockOrUnlockProposalApprovers[_lockOrUnlockProposalCount][
            msg.sender
        ] = true;

        // emit event
        emit UnlockProposalCreated(
            msg.sender,
            _lockOrUnlockProposalCount,
            lockData_,
            block.timestamp
        );

        // execute if sender is the only signatory
        if (_signatories.length == 1 || _minSignatures == 1) {
            // change the is executed status
            _lockOrUnlockProposals[_lockOrUnlockProposalCount]
                .ISEXECUTED = true;

            // call SegMint Vault and batch unlock NFTs
            SegMintNFTVault(
                _lockOrUnlockProposals[_lockOrUnlockProposalCount].SegMintVault
            ).batchUnlockNFTs(_batchUnlockInfo[_lockOrUnlockProposalCount]);

            // remove NFTs from locked NFTs
            _removeBatchNFTsToLockedNFTs(lockData_);

            // emit UNLOCK execution
            emit UnlockProposalExecuted(
                msg.sender,
                _lockOrUnlockProposalCount,
                block.timestamp
            );
        }
    }

    // approve lock or unlock proposal
    function approveLockorUnlockProposal(uint256 lockorUnlockProposalID_)
        public
        onlySignatories
        onlyValidLockOrUnlockProposalID(lockorUnlockProposalID_)
    {
        // proposal info
        LockOrUnlockProposal storage proposal = _lockOrUnlockProposals[
            lockorUnlockProposalID_
        ];

        // require proposal not been executed, revoked, expired, or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION < block.timestamp ||
                _lockOrUnlockProposalApprovers[lockorUnlockProposalID_][
                    msg.sender
                ]),
            "Multi-Sig: Proposal already executed, revoked, expired, or approved by sender!"
        );

        // approve by sender
        _lockOrUnlockProposalApprovers[lockorUnlockProposalID_][
            msg.sender
        ] = true;

        // update approved count
        proposal.APPROVEDCOUNT++;
         emit LockOrUnlockProposalApproved(msg.sender, lockorUnlockProposalID_, block.timestamp);

        // execute if proposal reached min signature requirement
        if (proposal.APPROVEDCOUNT >= _minSignatures) {
            // change the approve status
            proposal.ISEXECUTED = true;

            if (proposal.PROPOSALTYPE == LockOrUnlockProposalType.LOCK) {
                // call SegMint Vault and batch lock NFTs
                SegMintNFTVault(proposal.SegMintVault).batchLockNFTs(
                    _batchLockInfo[lockorUnlockProposalID_]
                );

                // add NFTs to locked NFTs
                _addBatchNFTsToLockedNFTs(_batchLockInfo[lockorUnlockProposalID_]);

                // emit execution event
                emit LockProposalExecuted(
                    msg.sender,
                    lockorUnlockProposalID_,
                    block.timestamp
                );
            } else {
                // call SegMint Vault and batch unlock NFTs
                SegMintNFTVault(proposal.SegMintVault).batchUnlockNFTs(
                    _batchUnlockInfo[lockorUnlockProposalID_]
                );

                // remove NFTs from locked NFTs
                _removeBatchNFTsToLockedNFTs(_batchUnlockInfo[lockorUnlockProposalID_]);

                // emit UNLOCK execution
                emit UnlockProposalExecuted(
                    msg.sender,
                    lockorUnlockProposalID_,
                    block.timestamp
                );
            }
        }
    }

    // revoke lock or unlock proposal
    function revokeLockorUnlockProposal(uint256 lockorUnlockProposalID_)
        public
        onlySignatories
        onlyLockOrUnlockProposer(lockorUnlockProposalID_)
        onlyValidLockOrUnlockProposalID(lockorUnlockProposalID_)
    {
        // proposal info
        LockOrUnlockProposal storage proposal = _lockOrUnlockProposals[
            lockorUnlockProposalID_
        ];

        // require proposal not been executed, revoked, expired, or revoked by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION < block.timestamp),
            "Multi-Sig: Proposal already executed, revoked, expired or revoked by sender!"
        );

        // emit revoked proposal
        emit LockOrUnlockProposalRevoked(
            msg.sender,
            lockorUnlockProposalID_,
            block.timestamp
        );
    }

    ///   GETTER FUNCTIONS   ///

    // get contract version
    function getContractVersion() external view returns (uint256) {
        // return version
        return _contractVersion;
    }

    // get signatories
    function getSignatories() external view returns (address[] memory) {
        return _signatories;
    }

    // is signer
    function IsSigner(address account_) external view returns (bool) {
        return _isSigner[account_];
    }

    // get min signature
    function getMinSignature() external view returns (uint256) {
        return _minSignatures;
    }

    // get signer proposal counts
    function getSignerProposalCount() external view returns (uint256) {
        return _signerProposalCount;
    }

    // get min signature proposal counts
    function getMinSignatureProposalCount() external view returns (uint256) {
        return _minSignatureProposalCount;
    }

    // get signer proposal detail
    function getSignerProposalDetail(uint256 signerProposalID_)
        external
        view
        returns (SignerProposal memory)
    {
        return _signerProposals[signerProposalID_];
    }

    // is signer proposal approver
    function isSignerProposalApprover(
        uint256 signerProposalID_,
        address account_
    ) external view returns (bool) {
        return _signerProposalApprovers[signerProposalID_][account_];
    }

    // get MinSignature proposal detail
    function getMinSignatureProposalDetail(uint256 MinSignatureProposalID_)
        external
        view
        returns (MinSignatureProposal memory)
    {
        return _minSignatureProposals[MinSignatureProposalID_];
    }

    // is Min Signature proposal approver
    function isMinSignatureProposalApprover(
        uint256 MinSignatureProposalID_,
        address account_
    ) external view returns (bool) {
        return
            _minSignatureProposalApprovers[MinSignatureProposalID_][account_];
    }

    // get lock or unlock proposal counts
    function getLockOrUnlockProposalCount() external view returns (uint256) {
        return _lockOrUnlockProposalCount;
    }

    // get lock or unlock proposal detail
    function getLockOrUnlockProposalDetail(uint256 lockOrUnlockProposalID_)
        external
        view
        returns (LockOrUnlockProposal memory)
    {
        return _lockOrUnlockProposals[lockOrUnlockProposalID_];
    }

    // is lock or unlock proposal approver
    function isLockOrUnlockProposalApprover(
        uint256 lockOrUnlockProposalID_,
        address account_
    ) external view returns (bool) {
        return
            _lockOrUnlockProposalApprovers[lockOrUnlockProposalID_][account_];
    }

    // get batch lock info
    function getBatchLockInfo(uint256 lockOrUnlockProposalID_)
        external
        view
        returns (BatchNFTsStruct[] memory)
    {
        return _batchLockInfo[lockOrUnlockProposalID_];
    }

    // get batch unlock info
    function getBatchUnlockInfo(uint256 lockOrUnlockProposalID_)
        external
        view
        returns (BatchNFTsStruct[] memory)
    {
        return _batchUnlockInfo[lockOrUnlockProposalID_];
    }

    // get list of NFT Contract Addresses locked
    function getLockedNFTContractAddresses() external view returns (address[] memory) {
      return _NFTContractAddressesLocked;
    }

    // get list of Token IDs locked for a NFT
    function getLockedTokenIDs(address NFTContractAddress_) external view returns (uint256[] memory) {
      return _TokenIDsLocked[NFTContractAddress_];
    }

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    // add NFT contract address to locked NFTs
    function _addNFTContractAddressToLockedNFTs(address NFTContractAddress_)
        internal
    {
        // require not locked
        if (!_isNFTLocked[NFTContractAddress_]) {
            
            // add to locked NFTs
            _NFTContractAddressesLocked.push(NFTContractAddress_);
            
            // update is locked status
            _isNFTLocked[NFTContractAddress_] = true;
        }
    }

    // remove NFT Contract Address from locked NFTs
    function _removeNFTContractAddressFromLockedNFTs(
        address NFTContractAddress_
    ) internal {
        // require NFT be already locked
        if (_isNFTLocked[NFTContractAddress_]) {
            for (uint256 i = 0; i < _NFTContractAddressesLocked.length; i++) {
                if (_NFTContractAddressesLocked[i] == NFTContractAddress_) {
                    // remove NFT
                    _NFTContractAddressesLocked[i] = _NFTContractAddressesLocked[_NFTContractAddressesLocked.length - 1];
                    _NFTContractAddressesLocked.pop();
                    // update is locked status
                    _isNFTLocked[NFTContractAddress_] = false;
                    break;
                }
            }
        }
    }

    // add Token ID to locked Token IDs
    function _addTokenIDToLockedTokenIDs(address NFTContractAddress_, uint256 TokenID_)
        internal
    {
        // require not locked
        if (!_isTokenIDLocked[NFTContractAddress_][TokenID_]) {
            
            // add to locked NFTs
            _TokenIDsLocked[NFTContractAddress_].push(TokenID_);
            
            // update is locked status
            _isTokenIDLocked[NFTContractAddress_][TokenID_] = true;
        }
    }

    // remove Token ID from locked Token IDs
    function _removeTokenIDFromLockedTokenIDs(
        address NFTContractAddress_,
        uint256 TokenID_
    ) internal {
        // require NFT be already locked
        if (_isTokenIDLocked[NFTContractAddress_][TokenID_]) {
            for (uint256 i = 0; i < _TokenIDsLocked[NFTContractAddress_].length; i++) {
                if (_TokenIDsLocked[NFTContractAddress_][i] == TokenID_) {
                    // remove Token ID
                    _TokenIDsLocked[NFTContractAddress_][i] = _TokenIDsLocked[NFTContractAddress_][_TokenIDsLocked[NFTContractAddress_].length - 1];
                    _TokenIDsLocked[NFTContractAddress_].pop();
                    // update is locked status
                    _isTokenIDLocked[NFTContractAddress_][TokenID_] = false;
                    break;
                }
            }
        }
    }

    // Batch Add NFTs to locked NFTs and Token IDs
    function _addBatchNFTsToLockedNFTs(BatchNFTsStruct[] memory lockData_)
        internal
    {
        
        // loop through NFTs
        for (uint256 i = 0; i < lockData_.length; i++) {
          
            // lockData info
            BatchNFTsStruct memory data = lockData_[i];

            // add NFT Contract Address to Locked NFTs
            _addNFTContractAddressToLockedNFTs(data.contractAddress);

            for (uint256 j = 0; j < data.tokenIds.length; j++) {
              // add Token ID to locked Token IDs
              _addTokenIDToLockedTokenIDs(data.contractAddress, data.tokenIds[j]);
            }
        }
    }

    // Batch Remove NFTs to locked NFTs and Token IDs
    function _removeBatchNFTsToLockedNFTs(BatchNFTsStruct[] memory lockData_)
        internal
    {
        // loop through NFTs
        for (uint256 i = 0; i < lockData_.length; i++) {
          
            // lockData info
            BatchNFTsStruct memory data = lockData_[i];

            for (uint256 j = 0; j < data.tokenIds.length; j++) {
              // remove Token ID to locked Token IDs
              _removeTokenIDFromLockedTokenIDs(data.contractAddress, data.tokenIds[j]);
            }

            // remove NFT Contract Address to Locked NFTs if there is no token ID locked
            if(_TokenIDsLocked[data.contractAddress].length == 0) {
              _removeNFTContractAddressFromLockedNFTs(data.contractAddress);
            }
        }
    }
}

// SegMint KYC Interface
interface SegMintKYCInterface {
    // get global authorization status
    function getGlobalAuthorizationStatus() external view returns (bool);
    // is authorized address?
    function isAuthorizedAddress(address account_) external view returns (bool);
    // get geo location
    function getUserLocation(address account_) external view returns (string memory);
}

/**
 * @title MultiSigFactory
 * @dev A factory contract for deploying MultiSig contracts.
 */
contract SegMint_MultiSig_Factory {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // SegMint Multi Sig Factory Owner Address
    address private _owner;

    // contract version
    uint256 private _contractVersion = 1;

    // Mapping to track SegMint MultiSig contracts
    mapping(address => bool) private _isSegMintMultiSig;

    // deployed SegMint-Multi-Sig by deployer
    mapping(address => address[]) private _deployedSegMintMultiSigByDeployer;

    // all deployed SegMint Multi-Sig contracts
    address[] private _deployedSegMintMultiSigList;

    // restricted SegMint Multi-Sig
    address[] private _restrictedDeployedSegMintMultiSigList;

    // KYC contract address and interface
    address private _SegMintKYCContractAddress;

    // SegMint KYC Interface
    SegMintKYCInterface private _SegMintKYC;

    ///////////////////////
    //    constructor    //
    ///////////////////////

    // Constructor

    /**
     * @dev Constructs the MultiSigFactory contract.
     */
    constructor() {
        _owner = msg.sender;
    }

    ////////////////////
    ////   Events   ////
    ////////////////////

    // Event emitted when the owner address is updated
    event updateOwnerAddressEvent(
        address indexed previousOwner,
        address indexed newOwnerAddress,
        uint256 indexed timestamp
    );

    // set SegMint KYC Contract Address
    event setSegMintKYCAddressEvent(
        address indexed owner,
        address previousSegMintKYCContractAddress,
        address indexed newSegMintKYCContractAddress,
        uint256 indexed timestamp
    );

    // Event emitted when a SegMint MultiSig contract is deployed
    event SegMintMultiSigDeployed(
        address indexed deployer,
        address indexed deployed,
        uint256 indexed timestamp
    );

    // Event emitted when a SegMint MultiSig contract is restricted
    event restrictSegMintMultiSigAddressEvent(
        address indexed ownerAddress,
        address indexed SegMintMultiSigAddress,
        uint256 indexed timestamp
    );

    // Event emitted when a SegMint MultiSig contract is added or unrestricted
    event AddSegMintMultiSigAddressEvent(
        address indexed ownerAddress,
        address indexed SegMintMultiSigAddress,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    /**
     * @dev Modifier to only allow the owner to execute a function.
     */
    modifier onlyOwner() {
        require(
            msg.sender == _owner,
            "SegMint MultiSig Factory: Sender is not the owner!"
        );
        _;
    }

    /**
     * @dev Modifier to ensure that an address is not the zero address.
     * @param account The address to check.
     * @param accountName The name of the account.
     */
    modifier notNullAddress(address account, string memory accountName) {
        require(
            account != address(0),
            string(
                abi.encodePacked(
                    "SegMint MultiSig Factory: ",
                    accountName,
                    " cannot be the zero address!"
                )
            )
        );
        _;
    }

    // not NUll Addresses
    modifier notNullAddresses(address[] memory accounts_) {
        // require all accounts be not zero address
        for (uint256 i = 0; i < accounts_.length; i++) {
            require(
                accounts_[i] != address(0),
                "SegMint MultiSig Factory: Address zero is not allowed."
            );
        }
        _;
    }

    /**
     * @dev Modifier to only allow KYC authorized accounts to execute a function.
     */
    modifier onlyKYCAuthorized() {
        require(
            _SegMintKYC.isAuthorizedAddress(msg.sender) || _SegMintKYC.getGlobalAuthorizationStatus(),
            "SegMint MultiSig Factory: Sender is not an authorized account!"
        );
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // get contract version
    function getContractVersion() public view returns (uint256) {
        // return version
        return _contractVersion;
    }

    /**
     * @dev Retrieves the owner address.
     * @return The owner address.
     */
    function getOwnerAddress() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Updates the owner address.
     * @param newOwnerAddress_ The new owner address.
     */

    function updateOwnerAddress(address newOwnerAddress_)
        public
        onlyOwner
        notNullAddress(newOwnerAddress_, "New Owner")
    {
        // update address
        _owner = newOwnerAddress_;

        // emit event
        emit updateOwnerAddressEvent(msg.sender, _owner, block.timestamp);
    }

    /**
     * @dev Sets the SegMintKYC contract address and interface.
     * @param SegMintKYCContractAddress_ The address of the SegMintKYC contract.
     */
    function setSegMintKYCAddress(address SegMintKYCContractAddress_)
        public
        onlyOwner
        notNullAddress(SegMintKYCContractAddress_, "SegMint KYC Address")
    {
        // previous address
        address previousSegMintKYCContractAddress = _SegMintKYCContractAddress;

        // update address
        _SegMintKYCContractAddress = SegMintKYCContractAddress_;

        // update interface
        _SegMintKYC = SegMintKYCInterface(SegMintKYCContractAddress_);

        // emit event
        emit setSegMintKYCAddressEvent(
            msg.sender,
            previousSegMintKYCContractAddress,
            SegMintKYCContractAddress_,
            block.timestamp
        );
    }

    /**
     * @dev Deploys a MultiSig contract.
     * @param owners_ The addresses of the owners of the MultiSig contract.
     * @param requiredConfirmations_ The number of required confirmations for a transaction in the MultiSig contract.
     */
    function deployMultiSig(
        address[] memory owners_,
        uint256 requiredConfirmations_
    ) external onlyKYCAuthorized notNullAddresses(owners_) {
        // Deploy the SegMint MultiSig contract and store its address
        address deployedAddress = address(
            new MultiSig(msg.sender, requiredConfirmations_, owners_)
        );

        // add deployed Multi-Sig to list by deployer
        _deployedSegMintMultiSigByDeployer[msg.sender].push(deployedAddress);

        // add to list of all Multi-Sigs
        _deployedSegMintMultiSigList.push(deployedAddress);

        // update status
        _isSegMintMultiSig[deployedAddress] = true;

        emit SegMintMultiSigDeployed(
            msg.sender,
            deployedAddress,
            block.timestamp
        );
    }

    /**
     * @dev Restricts a SegMint MultiSig contract address.
     * @param SegMintMultiSigAddress_ The address of the SegMint MultiSig contract to restrict.
     */
    function restrictSegMintMultiSigAddress(address SegMintMultiSigAddress_)
        public
        onlyOwner
    {
        // require address be a SegMint MultiSig
        require(
            isSegmintMultiSig(SegMintMultiSigAddress_),
            "SegMint MultiSig Factory: Address is not a SegMint MultiSig Contract!"
        );

        // remove from SegMint MultiSig list
        _removeAddressFromSegMintMultiSig(SegMintMultiSigAddress_);

        // add to restricted SegMint MultiSig
        _restrictedDeployedSegMintMultiSigList.push(SegMintMultiSigAddress_);

        // emit event
        emit restrictSegMintMultiSigAddressEvent(
            msg.sender,
            SegMintMultiSigAddress_,
            block.timestamp
        );
    }

    /**
     * @dev Adds or unrestricts a SegMint MultiSig contract address.
     * @param SegMintMultiSigAddress_ The address of the SegMint MultiSig contract to add or unrestrict.
     */
    function AddOrUnrestrictSegMintMultiSigAddress(
        address SegMintMultiSigAddress_
    ) public onlyOwner {
        // require address not be in the SegMint MultiSig list
        require(
            !isSegmintMultiSig(SegMintMultiSigAddress_),
            "SegMint MultiSig Factory: Address is already in SegMint"
        );

        // update is SegMint MultiSig
        _isSegMintMultiSig[SegMintMultiSigAddress_] = true;

        // add contract address to all deployed SegMint MultiSig list
        _deployedSegMintMultiSigList.push(SegMintMultiSigAddress_);

        // emit event
        emit AddSegMintMultiSigAddressEvent(
            msg.sender,
            SegMintMultiSigAddress_,
            block.timestamp
        );
    }

    /**
     * @dev Checks if an address is a SegMint MultiSig contract.
     * @param contractAddress The address to check.
     * @return True if the address is a SegMint MultiSig contract, false otherwise.
     */
    function isSegmintMultiSig(address contractAddress)
        public
        view
        returns (bool)
    {
        return _isSegMintMultiSig[contractAddress];
    }

    /**
     * @dev Retrieves the addresses of all deployed SegMint MultiSig contracts.
     * @return An array of SegMint MultiSig contract addresses.
     */
    function getDeployedSegMintMultiSigContracts()
        public
        view
        returns (address[] memory)
    {
        return _deployedSegMintMultiSigList;
    }

    /**
     * @dev Retrieves the addresses of all restricted SegMint MultiSig contracts.
     * @return An array of restricted SegMint MultiSig contract addresses.
     */
    function getRestrictedSegMintMultiSigContracts()
        public
        view
        returns (address[] memory)
    {
        return _restrictedDeployedSegMintMultiSigList;
    }

    /**
     * @dev Retrieves the addresses of deployed SegMint MultiSig contracts by a specific deployer.
     * @param deployer_ The address of the deployer.
     * @return An array of SegMint MultiSig contract addresses.
     */
    function getSegMintMultiSigDeployedAddressByDeployer(address deployer_)
        public
        view
        returns (address[] memory)
    {
        return _deployedSegMintMultiSigByDeployer[deployer_];
    }

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////

    /**
     * @dev Internal function to remove an address from the SegMint MultiSig list.
     * @param MultiSigAddress_ The address to remove.
     */
    function _removeAddressFromSegMintMultiSig(address MultiSigAddress_)
        private
    {
        if (_isSegMintMultiSig[MultiSigAddress_]) {
            for (uint256 i = 0; i < _deployedSegMintMultiSigList.length; i++) {
                if (_deployedSegMintMultiSigList[i] == MultiSigAddress_) {
                    _deployedSegMintMultiSigList[
                        i
                    ] = _deployedSegMintMultiSigList[
                        _deployedSegMintMultiSigList.length - 1
                    ];
                    _deployedSegMintMultiSigList.pop();
                    // update status
                    _isSegMintMultiSig[MultiSigAddress_] = false;
                    break;
                }
            }
        }
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////
}