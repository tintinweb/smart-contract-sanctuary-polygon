/**
 *Submitted for verification at polygonscan.com on 2023-07-01
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-17
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

// SegMint ERC1155 Fee Management Interface
interface SegMintERC1155FeeManagementInterface {
    // Set Fee Manager Address
    function setFeeManager(address feeManager_) external;

    // get Fee Manager address
    function getFeeManager() external view returns (address);

    // Set Treasurer Address
    function setTreasurer(address treasurer_) external;

    // get treasurer address
    function getTreasurer() external view returns (address);

    // set fees decimal
    function setFeesDecimal(uint256 value_) external;

    // get Fees decimal
    function getFeesDecimal() external view returns (uint256);

    // set segminting fees
    function setSegmintingFees(uint256 value_) external;

    // get segminting fees
    function getSegmintingFees() external view returns (uint256);

    // set reclaiming fees
    function setReclaimingFees(uint256 value_) external;

    // get reclaiming fees
    function getReclaimingFees() external view returns (uint256);

    // get transfer fees
    function getTransferFees() external view returns (uint256);
}

// SegMint ERC1155 Fee Management Contract
contract SegMintERC1155FeeManagement is SegMintERC1155FeeManagementInterface {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // contract version
    uint256 private _contractVersion = 0;

    // owner
    address private _owner;

    // fee manager
    address private _feeManager;

    // treasurer
    address private _treasurer;

    // fee decimals
    uint256 public _feeDecimals = 18;

    // segminting fee
    uint256 public _segmintingFee = 1000000000000000; // 10 bps per key

    // reclaiming NFT fee
    uint256 public _reclaimingFee = 1000000000000000; // 10 bps per key

    // transfer fee
    uint256 public _transferFee = 100000000000000; // 1 bps per key

    ///////////////////////////
    ////    Constructor    ////
    ///////////////////////////

    constructor() {
        _owner = msg.sender;
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // set owner address
    event setOwnerAddressEvent(
        address indexed OwnerAddress,
        address previousOwnerAddress,
        address indexed newOwnerAddress,
        uint256 indexed timestamp
    );

    // set fee manager address
    event setFeeManagerEvent(
        address indexed OwnerAddress,
        address previousFeeManager,
        address indexed newFeeManager,
        uint256 indexed timestamp
    );

    // set treasurer address
    event setTreasurerEvent(
        address indexed OwnerAddress,
        address previousTreasurer,
        address indexed newTreasurer,
        uint256 indexed timestamp
    );

    // set ERC1155 DB Admin Address
    event setERC1155DBAdminEvent(
        address indexed OwnerAddress,
        address previousERC1155DBAdmin,
        address newERC1155DBAdmin,
        uint256 indexed timestamp
    );

    // set fee decimal
    event setFeesDecimalEvent(
        address indexed OwnerAddress,
        uint256 previousFeeDecimals,
        uint256 newFeeDecimals,
        uint256 indexed timestamp
    );

    // set segminting fee
    event setSegmintingFeesEvent(
        address indexed OwnerAddress,
        uint256 previousSegmintingFee,
        uint256 newSegmintingFee,
        uint256 indexed timestamp
    );

    // set reclaiming fee
    event setReclaimingFeesEvent(
        address indexed OwnerAddress,
        uint256 previousReclaimingFee,
        uint256 newReclaimingFee,
        uint256 indexed timestamp
    );

    // set transfer fee
    event setTransferFeesEvent(
        address indexed OwnerAddress,
        uint256 previousTransferFee,
        uint256 newTransferFee,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only owner
    modifier onlyOwner() {
        // require sender be the owner address
        require(
            msg.sender == _owner,
            string.concat(
                "SegMint ERC1155 Fee Management: ",
                "Sender ",
                Strings.toHexString(msg.sender),
                " is not the owner address!"
            )
        );
        _;
    }

    // only fee manager
    modifier onlyFeeManager() {
        // require sender be the fee manager address
        require(
            msg.sender == _feeManager,
            string.concat(
                "SegMint ERC1155 Fee Management: ",
                "Sender ",
                Strings.toHexString(msg.sender),
                " is not the Fee Manager address!"
            )
        );
        _;
    }

    // not Null address
    modifier notNullAddress(address address_, string memory accountName_) {
        // require address not be the zero address
        require(
            address_ != address(0),
            string.concat(
                "SegMint ERC1155 Fee Management: ",
                accountName_,
                " ",
                Strings.toHexString(address_),
                " is the zero address!"
            )
        );
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // get contract version
    function getContractVersion()
        public
        view
        returns(uint256)
    {
        return _contractVersion;
    }

    // set Owner Address
    function setOwnerAddress(address owner_)
        public
        onlyOwner
        notNullAddress(owner_, "Owner Address")
    {
        // previous address
        address previousOwnerAddress = _owner;

        // udpate address
        _owner = owner_;

        // emit event
        emit setOwnerAddressEvent(
            msg.sender,
            previousOwnerAddress,
            owner_,
            block.timestamp
        );
    }

    // get Owner Address
    function getOwnerAddress() public view returns(address){
        return _owner;
    }

    // Set Fee Manager Address
    function setFeeManager(address feeManager_)
        public
        onlyOwner
        notNullAddress(feeManager_, "Fee Manager Address")
    {
        // previous Fee Manager
        address previousFeeManager = feeManager_;

        // update
        _feeManager = feeManager_;

        // emit event
        emit setFeeManagerEvent(
            msg.sender,
            previousFeeManager,
            feeManager_,
            block.timestamp
        );
    }

    // get Fee Manager address
    function getFeeManager() public view returns (address) {
        return _feeManager;
    }

    // Set Treasurer Address
    function setTreasurer(address treasurer_)
        public
        onlyOwner
        notNullAddress(treasurer_, "Treasurer Address")
    {
        // previous Treasurer
        address previousTreasurer = _treasurer;

        // update
        _treasurer = treasurer_;

        // emit event
        emit setTreasurerEvent(
            msg.sender,
            previousTreasurer,
            treasurer_,
            block.timestamp
        );
    }

    // get treasurer address
    function getTreasurer() public view returns (address) {
        return _treasurer;
    }

    // set fees decimal
    function setFeesDecimal(uint256 value_) public onlyFeeManager {
        // previous fee decimal
        uint256 previousFeeDecimals = _feeDecimals;

        // update fee decimals
        _feeDecimals = value_;

        // emit event
        emit setFeesDecimalEvent(
            msg.sender,
            previousFeeDecimals,
            value_,
            block.timestamp
        );
    }

    // get Fees decimal
    function getFeesDecimal() public view returns (uint256) {
        return _feeDecimals;
    }

    // set segminting fees
    function setSegmintingFees(uint256 value_) public onlyFeeManager {
        // previous segminting fee
        uint256 previousSegmintingFee = _segmintingFee;

        // update
        _segmintingFee = value_;

        // emit event
        emit setSegmintingFeesEvent(
            msg.sender,
            previousSegmintingFee,
            value_,
            block.timestamp
        );
    }

    // get segminting fees
    function getSegmintingFees() public view returns (uint256) {
        return _segmintingFee;
    }

    // set reclaiming fees
    function setReclaimingFees(uint256 value_) public onlyFeeManager {
        // previous reclaiming fee
        uint256 previousReclaimingFee = _reclaimingFee;

        // update
        _reclaimingFee = value_;

        // emit event
        emit setReclaimingFeesEvent(
            msg.sender,
            previousReclaimingFee,
            value_,
            block.timestamp
        );
    }

    // get reclaiming fees
    function getReclaimingFees() public view returns (uint256) {
        return _reclaimingFee;
    }

    // set transfer fees
    function setTransferFees(uint256 value_) public onlyFeeManager {
        // previous transfer fee
        uint256 previousTransferFee = _transferFee;

        // update
        _transferFee = value_;

        // emit event
        emit setTransferFeesEvent(
            msg.sender,
            previousTransferFee,
            value_,
            block.timestamp
        );
    }

    // get transfer fees
    function getTransferFees() public view returns (uint256) {
        return _transferFee;
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////
}