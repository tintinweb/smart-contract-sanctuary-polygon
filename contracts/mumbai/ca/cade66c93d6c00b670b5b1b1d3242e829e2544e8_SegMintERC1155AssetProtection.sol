/**
 *Submitted for verification at polygonscan.com on 2023-06-28
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

// SegMint ERC1155 Asset Protection Interface
interface SegMintERC1155AssetProtectionInterface {
    // get contract version
    function getContractVersion() external view returns (uint256);

    // set asset prtection address
    function setAssetProtection(address assetProtection_) external;

    // get asset protection address
    function getAssetProtection() external view returns (address);

    // set SegMint ERC1155 Contract Address
    function setSegMintERC1155ContractAddress(
        address SegMintERC1155ContractAddress_
    ) external;

    // get SegMint ERC1155 Contract Address
    function getSegMintERC1155ContractAddress() external view returns (address);

    // set SegMint ERC1155 DB Contract Address
    function setSegMintERC1155DBContractAddress(
        address SegMintERC1155DBContractAddress_
    ) external;

    // get SegMint ERC1155 DB Contract Address
    function getSegMintERC1155DBAddress() external view returns (address);

    // freeze account for trading all TokenIDs
    function freezeAccount(address account_) external;

    // unfreeze account for trading all TokenIDs
    function unFreezeAccount(address account_) external;

    // get account freeze status
    function isAccountFreezed(address account_) external view returns(bool);

    // freeze an account for trading a specific TokenID
    function freezeAccountTransactionsSpecificTokenID(
        address account_,
        uint256 TokenID_
    ) external;

    // unfreeze an account for trading a specific TokenID
    function unFreezeAccountTransactionsSpecificTokenID(
        address account_,
        uint256 TokenID_
    ) external;

    // get freeze status of an account for a specific TokenID
    function isAccountFreezedForSpecificTokenID(address account_, uint256 TokenID_) external view returns(bool);

    // wipe frozen account for specific TokenID
    function wipeFrozenAccountSpecificTokenID(
        address account_,
        uint256 TokenID_
    ) external returns (bool);

    // wipe and freez account for specific TokenID
    function wipeAndFreezeAccountSpecificTokenID(
        address account_,
        uint256 TokenID_
    ) external returns (bool);

    // wipe, freeze account and transfer balance to An Account for specific TokenID
    function WipeFreezeAndTransferAccountSpecificTokenID(
        address account_,
        uint256 TokenID_,
        address receiverAccount_
    ) external returns (bool);
}

// SegMint ERC1155 Asset Protection Contract
contract SegMintERC1155AssetProtection is SegMintERC1155AssetProtectionInterface {
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

    // asset protection
    address private _assetProtection;

    // SegMint ERC1155 Contract Address
    address private _SegMintERC1155ContractAddress;

    // SegMint ERC1155 DB Contract Address
    address private _SegMintERC1155DBContractAddress;

    /****************************/
    /*    Transaction Freeze    */
    /****************************/

    // freeze specific account for all TokenIDs status
    mapping(address => bool) private _freezeAccountStatus;

    // freezing specific account specifit TokenID status: TokenID => account => bool
    mapping(uint256 => mapping(address => bool))
        private _freezeAccountTokenIDStatus;

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

    // set asset protection address
    event setAssetProtectionEvent(
        address indexed OwnerAddress,
        address previousAssetProtection,
        address indexed newAssetProtection,
        uint256 indexed timestamp
    );

    // set SegMint ERC1155 Contract Address
    event setSegMintERC1155ContractAddressEvent(
        address indexed OwnerAddress,
        address previousERC1155ContractAddress,
        address indexed newERC1155ContractAddress,
        uint256 indexed timestamp
    );

    // set SegMint ERC1155 DB Contract Address
    event setSegMintERC1155DBContractAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintERC1155ContractAddress,
        address indexed newSegMintERC1155ContractAddress,
        uint256 indexed timestamp
    );

    // freeze account
    event freezeAccountEvent(
        address indexed AssetProtection,
        address indexed Account,
        bool previousStatus,
        uint256 indexed timestamp
    );

    // unfreeze account
    event unFreezeAccountEvent(
        address indexed AssetProtection,
        address indexed Account,
        bool previousStatus,
        uint256 indexed timestamp
    );

    // freeze account tradings for specific token id
    event freezeAccountTransactionsSpecificTokenIDEvent(
        address indexed AssetProtection,
        address indexed Account,
        uint256 TokenID,
        bool previousStatus,
        uint256 indexed timestamp
    );

    // unfreeze account tradings for specific token id
    event unFreezeAccountTransactionsSpecificTokenIDEvent(
        address indexed AssetProtection,
        address indexed Account,
        uint256 TokenID,
        bool previousStatus,
        uint256 indexed timestamp
    );

    // wipe Frozen Account Specific TokenID
    event wipeFrozenAccountSpecificTokenIDEvent(
        address indexed Sender,
        address account,
        uint256 indexed TokenID,
        uint256 totalBalance,
        uint256 indexed timestamp
    );

    // wipe and freeze Account Specific TokenID
    event wipeAndFreezeAccountSpecificTokenIDEvent(
        address indexed Sender,
        address account,
        uint256 indexed TokenID,
        uint256 totalBalance,
        uint256 indexed timestamp
    );

    // wipe , freeze and transfer (mint) Specific Token ID
    event WipeFreezeAndTransferAccountSpecificTokenIDEvent(
        address indexed Sender,
        address account,
        uint256 indexed TokenID,
        uint256 totalBalance,
        address receiverAccount,
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
                "SegMint ERC1155 Asset Protection: ",
                "Sender ",
                Strings.toHexString(msg.sender),
                " is not the owner address!"
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
                "SegMint ERC115 Asset Protection: ",
                accountName_,
                " ",
                Strings.toHexString(address_),
                " should not be the zero address!"
            )
        );
        _;
    }

    //only AssetProtection
    modifier onlyAssetProtection() {
        // require sender be the AssetProtection address
        require(
            msg.sender == _assetProtection,
            string.concat(
                "SegMint ERC1155 Asset Protection: ",
                "Sender ",
                Strings.toHexString(msg.sender),
                " is not the Asset Protection Address!"
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
    function getOwnerAddress()
        public
        view 
        returns(address)
    {
        return _owner;
    }

    // set asset prtection address
    function setAssetProtection(address assetProtection_)
        public
        onlyOwner
        notNullAddress(assetProtection_, "Asset Protection Address")
    {
        // previous asset protection role
        address previousAssetProtection = _assetProtection;

        // update
        _assetProtection = assetProtection_;

        // emit event
        emit setAssetProtectionEvent(
            msg.sender,
            previousAssetProtection,
            assetProtection_,
            block.timestamp
        );
    }

    // get asset protection address
    function getAssetProtection() public view returns (address) {
        return _assetProtection;
    }

    // set SegMint ERC1155 Contract Address
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

        // emit event
        emit setSegMintERC1155ContractAddressEvent(
            msg.sender,
            previousSegMintERC1155ContractAddress,
            SegMintERC1155ContractAddress_,
            block.timestamp
        );
    }

    // get SegMint ERC1155 Contract Address
    function getSegMintERC1155ContractAddress() public view returns (address) {
        return _SegMintERC1155ContractAddress;
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
        address previousSegMintERC1155DBContractAddress = _SegMintERC1155DBContractAddress;

        // update contract
        _SegMintERC1155DBContractAddress = SegMintERC1155DBContractAddress_;

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
        return _SegMintERC1155DBContractAddress;
    }

    // freeze account for trading all TokenIDs
    function freezeAccount(address account_) public onlyAssetProtection {
        // previous status
        bool status = _freezeAccountStatus[account_];

        // update status
        _freezeAccountStatus[account_] = true;

        // emit event
        emit freezeAccountEvent(
            msg.sender, 
            account_, 
            status,
            block.timestamp);
    }

    // unfreeze account for trading all TokenIDs
    function unFreezeAccount(address account_) public onlyAssetProtection {
        // previous status
        bool status = _freezeAccountStatus[account_];

        // update status
        _freezeAccountStatus[account_] = false;

        // emit event
        emit unFreezeAccountEvent(
            msg.sender, 
            account_, 
            status,
            block.timestamp
        );
    }

    // get account freeze status
    function isAccountFreezed(address account_) public view returns(bool){
        return _freezeAccountStatus[account_];
    }

    // freeze an account for trading a specific TokenID
    function freezeAccountTransactionsSpecificTokenID(
        address account_,
        uint256 TokenID_
    ) public onlyAssetProtection {
        // previous Status
        bool previousStatus = _freezeAccountTokenIDStatus[TokenID_][account_];

        // update status
        _freezeAccountTokenIDStatus[TokenID_][account_] = true;

        // emit event
        emit freezeAccountTransactionsSpecificTokenIDEvent(
            msg.sender,
            account_,
            TokenID_,
            previousStatus,
            block.timestamp
        );
    }

    // unfreeze an account for trading a specific TokenID
    function unFreezeAccountTransactionsSpecificTokenID(
        address account_,
        uint256 TokenID_
    ) public onlyAssetProtection {
        // previous Status
        bool previousStatus = _freezeAccountTokenIDStatus[TokenID_][account_];

        // update status
        _freezeAccountTokenIDStatus[TokenID_][account_] = false;

        // emit event
        emit unFreezeAccountTransactionsSpecificTokenIDEvent(
            msg.sender,
            account_,
            TokenID_,
            previousStatus,
            block.timestamp
        );
    }

    // get freeze status of an account for a specific TokenID
    function isAccountFreezedForSpecificTokenID(address account_, uint256 TokenID_) public view returns(bool){
        return _freezeAccountTokenIDStatus[TokenID_][account_];
    }

    // wipe frozen account for specific TokenID
    function wipeFrozenAccountSpecificTokenID(
        address account_,
        uint256 TokenID_
    )
        public
        onlyAssetProtection
        notNullAddress(account_, "Account")
        returns (bool)
    {
        // require account be frozen
        require(
            _freezeAccountTokenIDStatus[TokenID_][account_],
            "SegMint ERC1155 Asset Protection: Account is already unfronzen for the TokenID!"
        );

        // get balance of account_
        uint256 totalBalance = SegMintERC1155DBInterface(
            _SegMintERC1155DBContractAddress
        ).getBalanceOf(TokenID_, account_);

        // burn account balance (wipe out)
        bool burnStatus = SegMintERC1155Interface(
            _SegMintERC1155ContractAddress
        ).burnKeys(account_, TokenID_, totalBalance);

        // require Success Status
        require(
            burnStatus,
            "SegMint ERC1155 Asset Protection: Failed to burn keys!"
        );

        // emit event
        emit wipeFrozenAccountSpecificTokenIDEvent(
            msg.sender,
            account_,
            TokenID_,
            totalBalance,
            block.timestamp
        );

        // return
        return true;
    }

    // wipe and freez account for specific TokenID
    function wipeAndFreezeAccountSpecificTokenID(
        address account_,
        uint256 TokenID_
    )
        public
        onlyAssetProtection
        notNullAddress(account_, "Account")
        returns (bool)
    {
        // require account be unfreezed
        require(
            !_freezeAccountTokenIDStatus[TokenID_][account_],
            "SegMint ERC1155 Asset Protection: Account is freezed for the TokenID!"
        );

        // freeze
        _freezeAccountTokenIDStatus[TokenID_][account_] = true;    
        

        // get balance of account_
        uint256 totalBalance = SegMintERC1155DBInterface(
            _SegMintERC1155DBContractAddress
        ).getBalanceOf(TokenID_, account_);

        // burn account balance (wipe out)
        bool burnStatus = SegMintERC1155Interface(
            _SegMintERC1155ContractAddress
        ).burnKeys(account_, TokenID_, totalBalance);

        // require Success Status
        require(
            burnStatus,
            "SegMint ERC1155 Asset Protection: Failed to burn keys!"
        );

        // emit event
        emit wipeAndFreezeAccountSpecificTokenIDEvent(
            msg.sender,
            account_,
            TokenID_,
            totalBalance,
            block.timestamp
        );

        // return
        return true;
    }

    // wipe, freeze account and transfer balance to An Account for specific TokenID
    function WipeFreezeAndTransferAccountSpecificTokenID(
        address account_,
        uint256 TokenID_,
        address receiverAccount_
    )
        public
        onlyAssetProtection
        notNullAddress(account_, "Account")
        notNullAddress(receiverAccount_, "Receiver Account")
        returns (bool)
    {
        // require account be unfreezed
        require(
            !_freezeAccountTokenIDStatus[TokenID_][account_],
            "SegMint ERC1155 Asset Protection: Account is freezed for the TokenID!"
        );

        // call freeze
        _freezeAccountTokenIDStatus[TokenID_][account_] = true;

        // get balance of account_
        uint256 totalBalance = SegMintERC1155DBInterface(
            _SegMintERC1155DBContractAddress
        ).getBalanceOf(TokenID_, account_);

        // wipe (burn) total balance from account
        bool burnStatus = SegMintERC1155Interface(
            _SegMintERC1155ContractAddress
        ).burnKeys(account_, TokenID_, totalBalance);

        // require Success Status
        require(
            burnStatus,
            "SegMint ERC1155 Asset Protection: Failed to burn keys!"
        );

        // mint total balance to receiver address
        bool mintStatus = SegMintERC1155Interface(
            _SegMintERC1155ContractAddress
        ).mintKey(TokenID_, account_, totalBalance);

        // require Success Status
        require(
            mintStatus,
            "SegMint ERC1155 Asset Protection: Failed to mint keys!"
        );

        // emit event
        emit WipeFreezeAndTransferAccountSpecificTokenIDEvent(
            msg.sender,
            account_,
            TokenID_,
            totalBalance,
            receiverAccount_,
            block.timestamp
        );

        // return
        return true;
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////
}