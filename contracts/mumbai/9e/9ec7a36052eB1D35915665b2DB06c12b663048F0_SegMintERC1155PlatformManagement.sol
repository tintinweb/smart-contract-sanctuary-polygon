/**
 *Submitted for verification at polygonscan.com on 2023-06-16
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

// SegMing ERC1155 DB Interface
interface SegMintERC1155DBInterface {
    // update owner address
    function setOwnerAddress(address owner_) external;

    // get owner address
    function getOwner() external view returns (address);

    // set SegMint ERC. 1155 Platform Management Contract Address
    function setSegMintERC1155PlatformManagementContractAddress(
        address SegMintERC1155PlatformManagementContractAddress_
    ) external;

    // get SegMint Platform Management Contract Address
    function getSegMintPlatformManagementContractAddress()
        external
        view
        returns (address);

    // set SegMintERC1155ContractAddress address
    function setSegMintERC1155ContractAddress(
        address SegMintERC1155ContractAddress_
    ) external;

    // get SegMintERC1155ContractAddress address
    function getSegMintERC1155ContractAddress() external view returns (address);

    // set meta data
    function setMetaData(
        uint256 TokenID_,
        string memory name_,
        string memory symbol_,
        string memory description_,
        address minter_
    ) external;

    // increase total Supply
    function increaseTokenIDTotalSupply(uint256 TokenID_, uint256 amount_)
        external;

    // decrease total supply
    function decreaseTokenIDTotalSupply(uint256 TokenID_, uint256 amount_)
        external;

    // function set Balance
    function setTokenIDBalance(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) external;

    // function add balance
    function addBalance(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) external;

    // function deduct balance
    function deductBalance(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) external;

    // function lock ERC1155 TokenID for an account (for listing)
    function lockToken(
        uint256 TokenID_,
        address holder_,
        // address locker_,
        uint256 amount_
    ) external returns (bool);

    // function unlock locked ERC1155 TokenID balance (delisting / sales)
    function unlockToken(
        uint256 TokenID_,
        address holder_,
        // address locker_,
        uint256 amount_
    ) external returns (bool);

    // set approval for all
    function setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) external;

    // add account to holders
    function appendToHolders(uint256 TokenID_, address account_) external;

    // remove account from holders
    function removeFromHolders(uint256 TokenID_, address account_) external;

    // set locker info
    function setLockerInfo(
        uint256 TokenID_,
        address holder_,
        address locker_,
        uint256 amount_
    ) external;

    // add account to lockers of token id by owner
    function appendToLockersOfTokenIDByOwner(
        uint256 TokenID_,
        address holder_,
        address locker_
    ) external;

    // remove account from lockers of token id by owner
    function removeFromLockersOfTokenIDByOwner(
        uint256 TokenID_,
        address holder_,
        address locker_
    ) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    // get metadata
    function getMetaData(uint256 TokenID_)
        external
        view
        returns (
            string memory name_,
            string memory symbol_,
            string memory description_,
            address minter_,
            uint256 totalSupply_
        );

    // get balance Of
    function getBalanceOf(uint256 TokenID_, address account_)
        external
        view
        returns (uint256);

    // get locked balance
    function getLockedBalance(uint256 TokenID_, address account_)
        external
        view
        returns (uint256);

    // get available balance
    function getAvailableBalance(uint256 TokenID_, address account_)
        external
        view
        returns (uint256);

    // Sender has sufficient unlocked balance
    function HaveSufficientUnlockedBalance(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) external view;

    // check if an address is locker of a token id for a holder
    function isLocker(
        uint256 TokenID_,
        address holder_,
        address locker_,
        uint256 lockedAmount_
    ) external view returns (bool);

    // returns array of token holders of specific TokenID
    function getTokenIDHolders(uint256 TokenID_)
        external
        view
        returns (address[] memory);

    // is minted
    function isMinted(uint256 TokenID_) external view returns (bool);
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


// SegMint ERC1155 Platform Management Contract
contract SegMintERC1155PlatformManagement is
    SegMintERC1155PlatformManagementInterface
{
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

    // SegMint ERC 1155 DB Contract Address
    address private _SegMintERC1155DBAddress;

    // exchange smart contract address
    address private _SegMintExchangeContractAddress;

    // SegMint ERC 1155 Contract Address
    address private _SegMintERC1155Address;

    /******************************/
    /*    Platform Restriction    */
    /******************************/

    // Trades restriction for all Token IDs on SegMint Exchange (initialize with true)
    bool private _globalTradingPlatfromRestriction = true;

    // status of ERC1155 Token ID trade restriction on SegMint Exchange Platfrom: ERC1155 Token ID => bool
    mapping(uint256 => bool)
        private _unrestrictedToSegMintPlatformTokenIDsStatus;

    // list of ERC1155 Token IDs not restricted to trade on SegMint Exchange
    uint256[] private _unrestrictedToSegMintPlatformTokenIDs;

    /****************************/
    /*    Transaction Freeze    */
    /****************************/

    // global freeze all TokenIDs transactions status
    bool private _globalFreezeStatus;

    // global freeze specific TokenID transactions status
    mapping(uint256 => bool) private _globalFreezeTokenIDStatus;


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

    // set SegMint ERC1155 DB Contract Address
    event setSegMintERC1155DBContractAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintERC1155ContractAddress,
        address indexed newSegMintERC1155ContractAddress,
        uint256 indexed timestamp
    );

    // set SegMint Exchange Contract Address
    event setSegMintExchangeAddressEvent(
        address indexed OwnerAddress,
        address previousExchange,
        address indexed newSegMintExchangeContractAddress,
        uint256 indexed timestamp
    );

    // set SegMint ERC1155 Contract Address
    event setSegMintERC1155AddressEvent(
        address indexed OwnerAddress,
        address previousERC1155,
        address indexed newERC1155,
        uint256 indexed timestamp
    );

    // update global trading platfrom restriction
    event updateGlobalTradingPlatfromRestrictionEvent(
        address indexed OwnerAddress,
        bool previousGlobalTradeRestrictionStatus,
        bool newGlobalTradeRestrictionStatus,
        uint256 indexed timestamp
    );

    // allow a Token ID to be tradable on other platforms
    event addERC1155TokenIDToUnrestrictedToSegMintPlatformTokenIDsEvent(
        address indexed OwnerAddress,
        uint256 indexed ERC1155TokenID,
        uint256 indexed timestamp
    );

    // restrict Token ID to be tradable ONLY on SegMint platform
    event removeERC1155TokenIDToUnrestrictedToSegMintPlatformTokenIDsEvent(
        address indexed OwnerAddress,
        uint256 indexed ERC1155TokenID,
        uint256 indexed timestamp
    );

    // freeze global transaction
    event freezeGlobalTransactionsEvent(
        address indexed OwnerAddress,
        bool previousStatus,
        bool newStatus,
        uint256 indexed timestamp
    );

    // unfreeze global transaction
    event unFreezeGlobalTransactionsEvent(
        address indexed OwnerAddress,
        bool previousStatus,
        bool newStatus,
        uint256 indexed timestamp
    );

    // freeze global transactions for specific Token ID
    event freezeGlobalTransactionsSpecificTokenIDEvent(
        address indexed OwnerAddress,
        uint256 indexed TokenID,
        bool previousStatus,
        bool newStatus,
        uint256 indexed timestamp
    );

    // unfreeze global transactions for specific Token ID
    event unFreezeGlobalTransactionsSpecificTokenIDEvent(
        address indexed OwnerAddress,
        uint256 indexed TokenID,
        bool previousStatus,
        bool newStatus,
        uint256 indexed timestamp
    );

    // lock ERC1155 Token for listing
    event lockTokenEvent(
        address indexed SegMintExchangeContractAddress,
        uint256 TokenID,
        address indexed account,
        uint256 amount,
        uint256 indexed timestamp
    );

    // unlock ERC1155 Token for listing
    event unlockTokenEvent(
        address indexed SegMintExchangeContractAddress,
        uint256 TokenID,
        address indexed account,
        uint256 amount,
        uint256 indexed timestamp
    );

    // unlock and transfer token (buying/delisting)
    event unLockAndTransferTokenEvent(
        address indexed Sender,
        address seller,
        address buyer,
        uint256 indexed TokenID,
        uint256 amount,
        uint256 indexed timestamp
    );

    // buyout from all holders
    event BuyoutFromAllHoldersEvent(
        address SegMinExchange,
        address indexed buyer,
        address creator,
        uint256 indexed TokenID,
        uint256 buyOutPricePerFraction,
        uint256 reservePricePerFraction,
        uint256 payment,
        address[] holders,
        uint256 indexed timestamp
    );

    // buyout from specific holders
    event BuyoutFromSpecificHoldersEvent(
        address SegMinExchange,
        address indexed buyer,
        address[] holders,
        address creator,
        uint256 indexed TokenID,
        uint256 buyOutPricePerFraction,
        uint256 reservePricePerFraction,
        uint256 payment,
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
                "SegMint ERC1155 Platform Management: ",
                "Sender ",
                Strings.toHexString(msg.sender),
                " is not the owner address!"
            )
        );
        _;
    }

    // only Exchange
    modifier onlyExchange() {
        // require sender be the exchange address
        require(
            msg.sender == _SegMintExchangeContractAddress,
            string.concat(
                "SegMint ERC1155 Platform Management: ",
                "Sender ",
                Strings.toHexString(msg.sender),
                " is not the SegMint Exchange address!"
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
                "SegMint ERC115 Platform Management: ",
                accountName_,
                " ",
                Strings.toHexString(address_),
                " should not be the zero address!"
            )
        );
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // get contract version
    function getContractVersion() public view returns (uint256) {
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

    // get owner address
    function getOwnerAddress() public view returns (address) {
        return _owner;
    }

    // set SegMint ERC1155 DB Contract Address
    function setSegMintERC1155DBContractAddress(
        address SegMintERC1155DBContractAddress_
    )
        public
        onlyOwner
        notNullAddress(
            SegMintERC1155DBContractAddress_,
            "SegMint ERC1155 DB Address"
        )
    {
        // previous SegMint ERC1155 DB Contract Address
        address previousSegMintERC1155DBContractAddress = _SegMintERC1155DBAddress;

        // update contract
        _SegMintERC1155DBAddress = SegMintERC1155DBContractAddress_;

        // emit event
        emit setSegMintERC1155DBContractAddressEvent(
            msg.sender,
            previousSegMintERC1155DBContractAddress,
            SegMintERC1155DBContractAddress_,
            block.timestamp
        );
    }

    // get SegMint ERC1155 DB Contract Address
    function getSegMintERC1155DBAddress() public view returns (address) {
        return _SegMintERC1155DBAddress;
    }

    // set SegMint Exchange Contract Address
    function setSegMintExchangeAddress(address SegMintExchangeAddress_)
        public
        onlyOwner
        notNullAddress(SegMintExchangeAddress_, "SegMint Exchange Address")
    {
        // previous SegMint Exchange Address
        address previousExchange = _SegMintExchangeContractAddress;

        // update
        _SegMintExchangeContractAddress = SegMintExchangeAddress_;

        // emit event
        emit setSegMintExchangeAddressEvent(
            msg.sender,
            previousExchange,
            SegMintExchangeAddress_,
            block.timestamp
        );
    }

    // get exchange contract
    function getSegmintExchangeContractAddress() public view returns (address) {
        return _SegMintExchangeContractAddress;
    }

    // set SegMint ERC1155 Contract Address
    function setSegMintERC1155Address(address SegMintERC1155Address_)
        public
        onlyOwner
        notNullAddress(SegMintERC1155Address_, "SegMint ERC1155 Address")
    {
        // previous SegMint ERC1155 Address
        address previousERC1155 = _SegMintERC1155Address;

        // update
        _SegMintERC1155Address = SegMintERC1155Address_;

        // emit event
        emit setSegMintERC1155AddressEvent(
            msg.sender,
            previousERC1155,
            SegMintERC1155Address_,
            block.timestamp
        );
    }

    // get ERC1155 contract
    function getSegmintERC1155ContractAddress() public view returns (address) {
        return _SegMintERC1155Address;
    }

    /******************************/
    /*    Platform Restriction    */
    /******************************/


    // update _globalTradingPlatfromRestriction
    function updateGlobalTradingPlatfromRestriction(bool status_)
        public
        onlyOwner
    {
        // previous global trade restriction status
        bool previousGlobalTradeRestrictionStatus = _globalTradingPlatfromRestriction;

        // update status
        _globalTradingPlatfromRestriction = status_;

        // emit event
        emit updateGlobalTradingPlatfromRestrictionEvent(
            msg.sender,
            previousGlobalTradeRestrictionStatus,
            status_,
            block.timestamp
        );
    }

    // get global trading platform restriction status
    function getGlobalTradingPlatformRestrictionStatus()
        public
        view
        returns (bool)
    {
        return _globalTradingPlatfromRestriction;
    }

    // add ERC1155 Token ID to _unrestrictedToSegMintPlatformTokenIDs if already not in the array
    // alow Token ID to be tradable on other platforms
    function addERC1155TokenIDToUnrestrictedToSegMintPlatformTokenIDs(
        uint256 ERC1155TokenID_
    ) public onlyOwner {
        if (!_unrestrictedToSegMintPlatformTokenIDsStatus[ERC1155TokenID_]) {
            _unrestrictedToSegMintPlatformTokenIDs.push(ERC1155TokenID_);
            _unrestrictedToSegMintPlatformTokenIDsStatus[
                ERC1155TokenID_
            ] = true;

            // emit event
            emit addERC1155TokenIDToUnrestrictedToSegMintPlatformTokenIDsEvent(
                msg.sender,
                ERC1155TokenID_,
                block.timestamp
            );
        } else {
            revert("SegMint ERC1155 Platform Management: ERC1155 Token ID is already added!");
        }
    }

    // remove ERC1155 Token ID fom _unrestrictedToSegMintPlatformTokenIDs if already in the array
    // restrict the Token ID to be tradable ONLY on SegMint platform
    function removeERC1155TokenIDToUnrestrictedToSegMintPlatformTokenIDs(
        uint256 ERC1155TokenID_
    ) public onlyOwner {
        if (_unrestrictedToSegMintPlatformTokenIDsStatus[ERC1155TokenID_]) {
            for (
                uint256 i = 0;
                i < _unrestrictedToSegMintPlatformTokenIDs.length;
                i++
            ) {
                if (
                    _unrestrictedToSegMintPlatformTokenIDs[i] == ERC1155TokenID_
                ) {
                    _unrestrictedToSegMintPlatformTokenIDs[
                        i
                    ] = _unrestrictedToSegMintPlatformTokenIDs[
                        _unrestrictedToSegMintPlatformTokenIDs.length - 1
                    ];
                    _unrestrictedToSegMintPlatformTokenIDs.pop();
                    _unrestrictedToSegMintPlatformTokenIDsStatus[
                        ERC1155TokenID_
                    ] = false;

                    // emit event
                    emit removeERC1155TokenIDToUnrestrictedToSegMintPlatformTokenIDsEvent(
                        msg.sender,
                        ERC1155TokenID_,
                        block.timestamp
                    );
                    break;
                }
            }
        } else {
            revert("SegMint ERC1155 Platform Management: ERC1155 Token ID is not in the list!");
        }
    }

    // get unrestricted ERC1155 Token IDs to trade on any platform
    function getUnrestrictedERC1155TokenIDs()
        public
        view
        returns (uint256[] memory)
    {
        return _unrestrictedToSegMintPlatformTokenIDs;
    }

    // is restricted to SegMint Platform
    function isRestrictedToSegMintPlatform(uint256 ERC1155TokenID_)
        public
        view
        returns (bool)
    {
        // restricted to segmint platfrom in One situation:
        // _globalTradingPlatfromRestriction = True AND _unrestrictedToSegMintPlatformTokenIDsStatus = False
        return
            (_globalTradingPlatfromRestriction) &&
            (!_unrestrictedToSegMintPlatformTokenIDsStatus[ERC1155TokenID_]);
    }

    /****************************/
    /*    Transaction Freeze    */
    /****************************/

    // freeze global transactions
    function freezeGlobalTransactions() public onlyOwner {
        // previous status
        bool status = _globalFreezeStatus;

        // update status
        _globalFreezeStatus = true;

        // emit event
        emit freezeGlobalTransactionsEvent(
            msg.sender,
            status,
            true,
            block.timestamp
        );
    }

    // unfreeze global transactions
    function unFreezeGlobalTransactions() public onlyOwner {
        // previous status
        bool status = _globalFreezeStatus;

        // update and send event
        _globalFreezeStatus = false;

        // emit event
        emit unFreezeGlobalTransactionsEvent(
            msg.sender,
            status,
            false,
            block.timestamp
        );
    }

    // get global transaction freeze status
    function getGlobalTransactionsFreezeStatus() public view returns(bool){
        return _globalFreezeStatus;
    }

    // freeze global transaction for specific TokenID
    function freezeGlobalTransactionsSpecificTokenID(uint256 TokenID_)
        public
        onlyOwner
    {
        // get previous status
        bool status = _globalFreezeTokenIDStatus[TokenID_];

        // update status
        _globalFreezeTokenIDStatus[TokenID_] = true;

        // emit event
        emit freezeGlobalTransactionsSpecificTokenIDEvent(
            msg.sender,
            TokenID_,
            status,
            true,
            block.timestamp
        );
    }

    // unfreeze global transaction for specific TokenID
    function unFreezeGlobalTransactionsSpecificTokenID(uint256 TokenID_)
        public
        onlyOwner
    {
        // get previous status
        bool status = _globalFreezeTokenIDStatus[TokenID_];

        // update status
        _globalFreezeTokenIDStatus[TokenID_] = false;

        // emit event
        emit unFreezeGlobalTransactionsSpecificTokenIDEvent(
            msg.sender,
            TokenID_,
            status,
            false,
            block.timestamp
        );
    }

    // get global transaction status for Specific TokenID
    function getGlobalTransactionsFreezeStatusSpecificTokenID(uint256 TokenID_)
        public
        view
        returns(bool)
    {
        return _globalFreezeTokenIDStatus[TokenID_];
    }

    ////////////////////////
    // Exchange Functions //
    ////////////////////////

    // function to lock ERC1155 tokens while listing the NFT
    function lockToken(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) public onlyExchange returns (bool) {
        // lock token in DB
        bool status = SegMintERC1155DBInterface(_SegMintERC1155DBAddress)
            .lockToken(
                TokenID_, 
                account_, 
                // msg.sender, 
                amount_);

        // require successful locking
        require(
            status,
            "SegMint ERC1155 Platform Management: Failed to lock token!"
        );

        // emit event
        emit lockTokenEvent(
            msg.sender,
            TokenID_,
            account_,
            amount_,
            block.timestamp
        );

        return true;
    }

    // function to un lock ERC1155 tokens while de-listing the NFT
    function unlockToken(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) public onlyExchange returns (bool) {
        // unlock
        bool status = SegMintERC1155DBInterface(_SegMintERC1155DBAddress)
            .unlockToken(
                TokenID_, 
                account_, 
                // msg.sender, 
                amount_);

        // require successful unlocking
        require(
            status,
            "SegMint ERC1155 Platform Management: Failed to unlock token!"
        );

        // emit event
        emit unlockTokenEvent(
            msg.sender,
            TokenID_,
            account_,
            amount_,
            block.timestamp
        );

        return true;
    }

    // unlock ERC1155 tokens and transfer to buyer
    function unLockAndTransferToken(
        uint256 TokenID_,
        address seller,
        address buyer,
        uint256 amount_
    ) public onlyExchange returns (bool) {
        // unlock
        bool status = SegMintERC1155DBInterface(_SegMintERC1155DBAddress)
            .unlockToken(
                TokenID_, 
                seller, 
                // msg.sender, 
                amount_);

        // require successful unlocking
        require(
            status,
            "SegMint ERC1155 Platform Management: Failed to unlock token!"
        );

        // safe transfer
        SegMintERC1155Interface(_SegMintERC1155Address).safeTransferFromBuyOut(
            seller,
            buyer,
            TokenID_,
            amount_,
            ""
        );

        // emit event
        emit unLockAndTransferTokenEvent(
            msg.sender,
            seller,
            buyer,
            TokenID_,
            amount_,
            block.timestamp
        );

        return true;
    }

    // buyout Price for all holders for ERC1155 Token ID
    function getBuyoutPriceFromAllHolders(
        address buyer,
        address creator,
        uint256 TokenID_,
        uint256 buyOutPricePerFraction,
        uint256 reservePricePerFraction
    ) public view returns (uint256) {
        // all holders
        address[] memory holders = SegMintERC1155DBInterface(
            _SegMintERC1155DBAddress
        ).getTokenIDHolders(TokenID_);

        uint256 totalPrice;
        reservePricePerFraction = reservePricePerFraction == 0
            ? buyOutPricePerFraction
            : reservePricePerFraction;
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            if (holder != buyer) {
                uint256 balance = SegMintERC1155Interface(
                    _SegMintERC1155Address
                ).balanceOf(holder, TokenID_);
                uint256 pricePerFraction = creator == holder
                    ? reservePricePerFraction
                    : buyOutPricePerFraction;
                uint256 pAmount = balance * pricePerFraction;
                totalPrice += pAmount;
            }
        }
        return totalPrice;
    }

    // returns the buy Price to be paid as msg value
    function getBuyOutPriceFromSpecificHolders(
        address buyer,
        address[] memory holders,
        address creator,
        uint256 TokenID_,
        uint256 buyOutPricePerFraction,
        uint256 reservePricePerFraction
    ) public view returns (uint256) {
        uint256 totalPrice;
        reservePricePerFraction = reservePricePerFraction == 0
            ? buyOutPricePerFraction
            : reservePricePerFraction;
        for (uint256 i = 0; i < holders.length; i++) {
            address holder = holders[i];
            if (holder != buyer) {
                uint256 balance = SegMintERC1155Interface(
                    _SegMintERC1155Address
                ).balanceOf(holder, TokenID_);
                uint256 pricePerFraction = creator == holder
                    ? reservePricePerFraction
                    : buyOutPricePerFraction;
                uint256 pAmount = balance * pricePerFraction;
                totalPrice += pAmount;
            }
        }
        return totalPrice;
    }

    // Buyout all fractions testing
    function BuyoutFromAllHolders(
        address buyer,
        address creator,
        uint256 TokenID_,
        uint256 buyOutPricePerFraction,
        uint256 reservePricePerFraction
    ) public payable onlyExchange returns (bool) {
        // payment amount
        uint256 payment = getBuyoutPriceFromAllHolders(
            buyer,
            creator,
            TokenID_,
            buyOutPricePerFraction,
            reservePricePerFraction
        );

        // require payment value match
        require(
            payment == msg.value,
            "SegMint ERC1155 Platform Management: Payment amount does not match!"
        );

        // all holders
        address[] memory holders = SegMintERC1155DBInterface(
            _SegMintERC1155DBAddress
        ).getTokenIDHolders(TokenID_);

        // uint256 totalPrice;
        reservePricePerFraction = reservePricePerFraction == 0
            ? buyOutPricePerFraction
            : reservePricePerFraction;
        for (uint256 i = 0; i < holders.length; i++) {
            // address holder = holders[i];
            if (holders[i] != buyer) {
                uint256 balance = SegMintERC1155Interface(
                    _SegMintERC1155Address
                ).balanceOf(holders[i], TokenID_);
                if (balance > 0) {
                    uint256 pricePerFraction = creator == holders[i]
                        ? reservePricePerFraction
                        : buyOutPricePerFraction;
                    uint256 pAmount = balance * pricePerFraction;
                    // if there is freezed balance => unfreeze
                    // get locked balance
                    uint256 lockedBalance = SegMintERC1155DBInterface(
                        _SegMintERC1155DBAddress
                    ).getLockedBalance(TokenID_, holders[i]);
                    // unfreeze balance
                    if (lockedBalance > 0) {
                        SegMintERC1155DBInterface(_SegMintERC1155DBAddress)
                            .unlockToken(
                                TokenID_,
                                holders[i],
                                // msg.sender,
                                lockedBalance
                            );
                    }
                    // totalPrice += pAmount;
                    payable(holders[i]).transfer(pAmount);
                    SegMintERC1155Interface(_SegMintERC1155Address)
                        .safeTransferFromBuyOut(
                            holders[i],
                            buyer,
                            TokenID_,
                            balance,
                            ""
                        );
                }
            } else {
                // holder == buyer (which could be the NFT owner or a generic holder
                // if there is any balance listed (locked) then it needs to be unlocked.

                // get locked balance
                uint256 lockedBalance = SegMintERC1155DBInterface(
                    _SegMintERC1155DBAddress
                ).getLockedBalance(TokenID_, holders[i]);
                // unfreeze balance
                if (lockedBalance > 0) {
                    SegMintERC1155DBInterface(_SegMintERC1155DBAddress)
                        .unlockToken(
                            TokenID_,
                            holders[i],
                            // msg.sender,
                            lockedBalance
                        );
                }
            }
        }

        // emit event
        emit BuyoutFromAllHoldersEvent(
            msg.sender,
            buyer,
            creator,
            TokenID_,
            buyOutPricePerFraction,
            reservePricePerFraction,
            payment,
            holders,
            block.timestamp
        );

        // return
        return true;
    }

    // // buy out
    function BuyoutFromSpecificHolders(
        address buyer,
        address[] memory holders,
        address creator,
        uint256 TokenID_,
        uint256 buyOutPricePerFraction,
        uint256 reservePricePerFraction
    ) public payable onlyExchange returns (bool) {
        // payment amount
        uint256 payment = getBuyOutPriceFromSpecificHolders(
            buyer,
            holders,
            creator,
            TokenID_,
            buyOutPricePerFraction,
            reservePricePerFraction
        );

        // require payment value match
        require(
            payment == msg.value,
            "SegMint ERC1155 Platform Management: Payment amount does not match!"
        );

        // unlock, transfer and pay for keys
        reservePricePerFraction = reservePricePerFraction == 0
            ? buyOutPricePerFraction
            : reservePricePerFraction;
        for (uint256 i = 0; i < holders.length; i++) {
            // address holder = holders[i];
            if (holders[i] != buyer) {
                uint256 balance = SegMintERC1155Interface(
                    _SegMintERC1155Address
                ).balanceOf(holders[i], TokenID_);
                if (balance > 0) {
                    uint256 pricePerFraction = creator == holders[i]
                        ? reservePricePerFraction
                        : buyOutPricePerFraction;
                    uint256 pAmount = balance * pricePerFraction;
                    // if there is freezed balance => unfreeze
                    // get locked balance
                    uint256 lockedBalance = SegMintERC1155DBInterface(
                        _SegMintERC1155DBAddress
                    ).getLockedBalance(TokenID_, holders[i]);
                    // unfreeze balance
                    if (lockedBalance > 0) {
                        SegMintERC1155DBInterface(_SegMintERC1155DBAddress)
                            .unlockToken(
                                TokenID_,
                                holders[i],
                                // msg.sender,
                                lockedBalance
                            );
                    }
                    // totalPrice += pAmount;
                    payable(holders[i]).transfer(pAmount);
                    SegMintERC1155Interface(_SegMintERC1155Address)
                        .safeTransferFromBuyOut(
                            holders[i],
                            buyer,
                            TokenID_,
                            balance,
                            ""
                        );
                }
            } else {
                // holder == buyer (which could be the NFT owner or a generic holder
                // if there is any balance listed (locked) then it needs to be unlocked.

                // get locked balance
                uint256 lockedBalance = SegMintERC1155DBInterface(
                    _SegMintERC1155DBAddress
                ).getLockedBalance(TokenID_, holders[i]);
                // unfreeze balance
                if (lockedBalance > 0) {
                    SegMintERC1155DBInterface(_SegMintERC1155DBAddress)
                        .unlockToken(
                            TokenID_,
                            holders[i],
                            // msg.sender,
                            lockedBalance
                        );
                }
            }
        }

        // emit event
        emit BuyoutFromSpecificHoldersEvent(
            msg.sender,
            buyer,
            holders,
            creator,
            TokenID_,
            buyOutPricePerFraction,
            reservePricePerFraction,
            payment,
            block.timestamp
        );

        // return
        return true;
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////
}