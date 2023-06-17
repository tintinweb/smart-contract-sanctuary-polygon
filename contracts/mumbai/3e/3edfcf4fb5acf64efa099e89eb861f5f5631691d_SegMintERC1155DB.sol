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

// SegMint ERC1155 DB Contract
contract SegMintERC1155DB is SegMintERC1155DBInterface {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    ////    Standard ERC1155 Fields    ////

    // Mapping from TokenID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    // string private _uri;

    ////    SegMint Fields    ////

    // owner
    address private _owner;

    // SegMintERC1155ContractAddress
    address private _SegMintERC1155ContractAddress;

    // SegMint ERC1155 Platform Management Contract Address
    address private _SegMintPlatformManagementContractAddress;

    // holders of a TokenID
    mapping(uint256 => address[]) private _holersOfTokenID;

    // holders of a TokenID status
    mapping(uint256 => mapping(address => bool)) private _holersOfTokenIDStatus;

    // 1155 meta data for each TokenID
    struct METADATA {
        string _name;
        string _symbol;
        string _description;
        address _minter;
        uint256 _totalSupply;
    }

    // TokenID meta data
    mapping(uint256 => METADATA) private _metaData;

    /************************/
    /*    Locking Fields    */
    /************************/

    // locker info
    struct LOCKERINFO {
        // amount locked
        uint256 _amount;
        // locking timestamp
        uint256 _lockingTimestamp;
        // unlocking timestamp
        uint256 _unlockingTimestamp;
    }

    // locker info of a specific TokenID, holder, locker: TokenID => holder => locker => LockerInfo
    mapping(uint256 => mapping(address => mapping(address => LOCKERINFO)))
        private _lockerInfo;

    // list of all lockers of a TokenID for a holder: TokenID => holder => lockers
    mapping(uint256 => mapping(address => address[]))
        private _lockersOfTokenIDByOwner;

    // list of all lockers of a TokenID for a holder status: TokenID => holder => locker => bool
    mapping(uint256 => mapping(address => mapping(address => bool)))
        private _lockersOfTokenIDByOwnerStatus;

    // amount locked for a specific TokenID and holder: TokenID => holder => lockedBalance
    mapping(uint256 => mapping(address => uint256)) private _lockedBalances;

    ///////////////////////////
    ////    Constructor    ////
    ///////////////////////////

    constructor(string memory uri_) {
        _setURI(uri_);
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

    // set SegMint Platform Management Contract Address
    event setSegMintERC1155PlatformManagementContractAddressEvent(
        address indexed OwnerAddress,
        address previousSegMintPlatormManagementContractAddress,
        address indexed newSegMintPlatormManagementContractAddress,
        uint256 indexed timestamp
    );

    // set SegMintERC1155ContractAddress
    event setSegMintERC1155ContractAddressEvent(
        address indexed Sender,
        address previousSegMintERC1155ContractAddress,
        address newSegMintERC1155ContractAddress,
        uint256 indexed timestamp
    );

    // set meta data
    event setMetaDataEvent(
        address indexed SegMintERC1155ContractAddress,
        uint256 indexed TokenID,
        string name,
        string symbol,
        string description,
        address minter_,
        uint256 indexed timestamp
    );

    // increase total supply
    event increaseTokenIDTotalSupplyEvent(
        address indexed Sender,
        uint256 indexed TokenID,
        uint256 previousTotalSupply,
        uint256 increaseAmount,
        uint256 indexed timestamp
    );

    // decrese total supply
    event decreaseTokenIDTotalSupplyEvent(
        address indexed Sender,
        uint256 indexed TokenID,
        uint256 previousTotalSupply,
        uint256 decreaseAmount,
        uint256 indexed timestamp
    );

    // set balance for an account for specific TokenID
    event setTokenIDBalanceEvent(
        address indexed Sender,
        address indexed account,
        uint256 TokenID,
        uint256 previousBalance,
        uint256 newBalance,
        uint256 indexed timestamp
    );

    // add balance to an account for specific TokenID
    event addBalanceEvent(
        address indexed Sender,
        address indexed account,
        uint256 TokenID,
        uint256 previousBalance,
        uint256 addedAmount,
        uint256 indexed timestamp
    );

    // deduct balance from an account for specific TokenID
    event deductBalanceEvent(
        address indexed Sender,
        address indexed account,
        uint256 TokenID,
        uint256 previousBalance,
        uint256 addedAmount,
        uint256 indexed timestamp
    );

    // lock Tokens for an account
    event lockTokenEvent(
        address indexed Sender,
        address indexed holderAccount,
        // address lockerAccount,
        uint256 TokenID,
        // uint256 previousLockedBalance,
        uint256 lockAmount,
        // uint256 totalBalance,
        uint256 indexed timestamp
    );

    // unlock Tokens for an acount
    event unlockTokenEvent(
        address indexed Sender,
        address indexed holderAccount,
        // address lockerAccount,
        uint256 TokenID,
        // uint256 previousLockedBalance,
        uint256 lockAmount,
        // uint256 totalBalance,
        uint256 indexed timestamp
    );

    // set locker info
    event setLockerInfoEvent(
        address indexed Sender,
        uint256 indexed TokenID,
        address holderAddress,
        address lockerAddress,
        uint256 lockingAmount,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // generic only role
    modifier onlyRole(string memory RoleName_) {
        // role address
        address RoleAddress;

        if (Strings.equal(RoleName_, "owner")) {
            RoleAddress = _owner;
        } else if (Strings.equal(RoleName_, "Platform Management")) {
            RoleAddress = _SegMintPlatformManagementContractAddress;
        } else if (Strings.equal(RoleName_, "SegMint ERC1155")) {
            RoleAddress = _SegMintERC1155ContractAddress;
        } else {
            RoleAddress = _owner;
        }

        // require sender be the role specified
        require(
            msg.sender == RoleAddress,
            string.concat(
                "SegMint ERC1155 DB: ",
                "Sender ",
                Strings.toHexString(msg.sender),
                " is not the ",
                RoleName_,
                " address!"
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
                "SegMint ERC1155 DB: ",
                accountName_,
                " ",
                Strings.toHexString(address_),
                " is the zero address!"
            )
        );
        _;
    }

    // only minted
    modifier onlyMinted(uint256 TokenID_) {
        // require TokenID be minted
        require(
            _isMinted(TokenID_),
            string.concat(
                "SegMint ERC1155 DB: ",
                "Token ID ",
                Strings.toString(TokenID_),
                " is not minted!"
            )
        );
        _;
    }

    // only value > 0
    modifier onlyGreaterThanZero(uint256 value_, string memory valueName_) {
        require(
            value_ > 0,
            string.concat(
                "SegMint ERC1155 DB: ",
                "Entered ",
                valueName_,
                " should be greater than zero!"
            )
        );
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // update owner address
    function setOwnerAddress(address owner_)
        public
        onlyRole("owner")
        notNullAddress(owner_, "Owner Address")
    {
        // previous owner
        address previousOwnerAddress = _owner;

        // update owner
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
    function getOwner() public view returns (address) {
        return _owner;
    }

    // set SegMint ERC. 1155 Platform Management Contract Address
    function setSegMintERC1155PlatformManagementContractAddress(
        address SegMintERC1155PlatformManagementContractAddress_
    )
        public
        onlyRole("owner")
        notNullAddress(
            SegMintERC1155PlatformManagementContractAddress_,
            "Platform Management Contract Address"
        )
    {
        // previous address
        address previousSegMintPlatormManagementContractAddress = _SegMintPlatformManagementContractAddress;

        // update
        _SegMintPlatformManagementContractAddress = SegMintERC1155PlatformManagementContractAddress_;

        // emit event
        emit setSegMintERC1155PlatformManagementContractAddressEvent(
            msg.sender,
            previousSegMintPlatormManagementContractAddress,
            SegMintERC1155PlatformManagementContractAddress_,
            block.timestamp
        );
    }

    // get SegMint Platform Management Contract Address
    function getSegMintPlatformManagementContractAddress()
        public
        view
        returns (address)
    {
        return _SegMintPlatformManagementContractAddress;
    }

    // set SegMintERC1155ContractAddress address
    function setSegMintERC1155ContractAddress(
        address SegMintERC1155ContractAddress_
    )
        public
        onlyRole("owner")
        notNullAddress(
            SegMintERC1155ContractAddress_,
            "SegMint ERC1155 Contract Address"
        )
    {
        // previous SegMintERC1155ContractAddress address
        address previousSegMintERC1155ContractAddress = _SegMintERC1155ContractAddress;

        // update SegMintERC1155ContractAddress
        _SegMintERC1155ContractAddress = SegMintERC1155ContractAddress_;

        // emit event
        emit setSegMintERC1155ContractAddressEvent(
            msg.sender,
            previousSegMintERC1155ContractAddress,
            _SegMintERC1155ContractAddress,
            block.timestamp
        );
    }

    // get SegMintERC1155ContractAddress address
    function getSegMintERC1155ContractAddress() public view returns (address) {
        return _SegMintERC1155ContractAddress;
    }

    /////////////////////////////////////////////
    ////    Only ERC1155 Contract Address    ////
    /////////////////////////////////////////////

    // set meta data
    function setMetaData(
        uint256 TokenID_,
        string memory name_,
        string memory symbol_,
        string memory description_,
        address minter_
    )
        public
        onlyRole("SegMint ERC1155")
        notNullAddress(minter_, "Minter Address")
    {
        // set name
        _metaData[TokenID_]._name = name_;

        // set symbol
        _metaData[TokenID_]._symbol = symbol_;

        // set description
        _metaData[TokenID_]._description = description_;

        // set minter
        _metaData[TokenID_]._minter = minter_;

        // emit event
        emit setMetaDataEvent(
            msg.sender,
            TokenID_,
            name_,
            symbol_,
            description_,
            minter_,
            block.timestamp
        );
    }

    // increase total Supply
    function increaseTokenIDTotalSupply(uint256 TokenID_, uint256 amount_)
        public
        onlyRole("SegMint ERC1155")
    {
        // previous total supply
        uint256 previousTotalSupply = _metaData[TokenID_]._totalSupply;

        // update
        _metaData[TokenID_]._totalSupply += amount_;

        // emit event
        emit increaseTokenIDTotalSupplyEvent(
            msg.sender,
            TokenID_,
            previousTotalSupply,
            amount_,
            block.timestamp
        );
    }

    // decrease total supply
    function decreaseTokenIDTotalSupply(uint256 TokenID_, uint256 amount_)
        public
        onlyRole("SegMint ERC1155")
        onlyMinted(TokenID_)
    {
        // previous total supply
        uint256 previousTotalSupply = _metaData[TokenID_]._totalSupply;

        // update
        _metaData[TokenID_]._totalSupply -= amount_;

        // emit event
        emit decreaseTokenIDTotalSupplyEvent(
            msg.sender,
            TokenID_,
            previousTotalSupply,
            amount_,
            block.timestamp
        );
    }

    // function set Balance
    function setTokenIDBalance(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) public notNullAddress(account_, "Account") onlyRole("SegMint ERC1155") {
        // previous balance
        uint256 previousBalance = _balances[TokenID_][account_];

        // update balance
        _balances[TokenID_][account_] = amount_;

        // emit event
        emit setTokenIDBalanceEvent(
            msg.sender,
            account_,
            TokenID_,
            previousBalance,
            amount_,
            block.timestamp
        );
    }

    // function add balance
    function addBalance(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    )
        public
        notNullAddress(account_, "Account")
        onlyMinted(TokenID_)
        onlyGreaterThanZero(amount_, "amount")
        onlyRole("SegMint ERC1155")
    {
        // previous balance
        uint256 previousBalance = _balances[TokenID_][account_];

        // update balance
        _balances[TokenID_][account_] += amount_;

        // emit event
        emit addBalanceEvent(
            msg.sender,
            account_,
            TokenID_,
            previousBalance,
            amount_,
            block.timestamp
        );
    }

    // function deduct balance
    function deductBalance(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    )
        public
        notNullAddress(account_, "Account")
        onlyMinted(TokenID_)
        onlyGreaterThanZero(amount_, "amount")
        onlyRole("SegMint ERC1155")
    {
        // previous balance
        uint256 previousBalance = _balances[TokenID_][account_];

        // update balance
        _balances[TokenID_][account_] -= amount_;

        // emit event
        emit deductBalanceEvent(
            msg.sender,
            account_,
            TokenID_,
            previousBalance,
            amount_,
            block.timestamp
        );
    }

    // function lock ERC1155 TokenID for an account (for listing)
    function lockToken(
        uint256 TokenID_,
        address holder_,
        // address locker_,
        uint256 amount_
    )
        public
        notNullAddress(holder_, "Holder Address")
        // notNullAddress(locker_, "Locker Address")
        onlyMinted(TokenID_)
        onlyGreaterThanZero(amount_, "amount")
        onlyRole("Platform Management")
        returns (bool)
    {
        // require account having sufficient unlocked balance
        require(
            getAvailableBalance(TokenID_, holder_) >= amount_,
            string.concat(
                "SegMint ERC1155 DB: Holder Address ",
                Strings.toHexString(holder_),
                " does not have sufficient unlocked token for TokenID : ",
                Strings.toString(TokenID_)
            )
        );

        // current locked balance
        // uint256 previousLockedBalance = _lockedBalances[TokenID_][holder_];

        // update locked balance
        _lockedBalances[TokenID_][holder_] += amount_;

        // emit event
        emit lockTokenEvent(
            msg.sender,
            holder_,
            // locker_,
            TokenID_,
            // previousLockedBalance,
            amount_,
            // _balances[TokenID_][holder_],
            block.timestamp
        );

        // return
        return true;
    }

    // function unlock locked ERC1155 TokenID balance (delisting / sales)
    function unlockToken(
        uint256 TokenID_,
        address holder_,
        // address locker_,
        uint256 amount_
    )
        public
        notNullAddress(holder_, "Holder Address")
        // notNullAddress(locker_, "Locker Address")
        onlyMinted(TokenID_)
        onlyGreaterThanZero(amount_, "amount")
        onlyRole("Platform Management")
        returns (bool)
    {
        // require account have sufficient locked balance
        require(
            _lockedBalances[TokenID_][holder_] >= amount_,
            string.concat(
                "SegMint ERC1155 DB: Account ",
                Strings.toHexString(holder_),
                " does not have sufficient locked token for TokenID : ",
                Strings.toString(TokenID_)
            )
        );

        // previous locked balance
        // uint256 previousLockedBalance = _lockedBalances[TokenID_][holder_];

        // update balance
        _lockedBalances[TokenID_][holder_] -= amount_;

        // emit event
        emit unlockTokenEvent(
            msg.sender,
            holder_,
            // locker_,
            TokenID_,
            // previousLockedBalance,
            amount_,
            // _balances[TokenID_][holder_],
            block.timestamp
        );

        // return
        return true;
    }

    // set approval for all
    function setApprovalForAll(
        address owner,
        address operator,
        bool approved
    )
        public
        virtual
        notNullAddress(owner, "Owner")
        notNullAddress(operator, "Operator")
        onlyRole("SegMint ERC1155")
    {
        require(
            owner != operator,
            "SegMint ERC1155 DB: ERC1155: setting approval status for self"
        );
        _operatorApprovals[owner][operator] = approved;
    }

    // add account to holders
    function appendToHolders(uint256 TokenID_, address account_)
        public
        notNullAddress(account_, "Account")
        onlyRole("SegMint ERC1155")
    {
        if (!_holersOfTokenIDStatus[TokenID_][account_]) {
            _holersOfTokenID[TokenID_].push(account_);
            _holersOfTokenIDStatus[TokenID_][account_] = true;
        }
    }

    // remove account from holders
    function removeFromHolders(uint256 TokenID_, address account_)
        public
        onlyRole("SegMint ERC1155")
        onlyMinted(TokenID_)
        notNullAddress(account_, "Account")
    {
        if (_holersOfTokenIDStatus[TokenID_][account_]) {
            for (uint256 i = 0; i < _holersOfTokenID[TokenID_].length; i++) {
                if (_holersOfTokenID[TokenID_][i] == account_) {
                    _holersOfTokenID[TokenID_][i] = _holersOfTokenID[TokenID_][
                        _holersOfTokenID[TokenID_].length - 1
                    ];
                    _holersOfTokenID[TokenID_].pop();
                    _holersOfTokenIDStatus[TokenID_][account_] = false;
                    break;
                }
            }
        }
    }

    // set locker info
    function setLockerInfo(
        uint256 TokenID_,
        address holder_,
        address locker_,
        uint256 amount_
    )
        public
        onlyMinted(TokenID_)
        notNullAddress(holder_, "Holder Address")
        notNullAddress(locker_, "Locker Address")
        onlyGreaterThanZero(amount_, "amount")
        onlyRole("SegMint ERC1155")
    {
        // add locker info
        _lockerInfo[TokenID_][holder_][locker_] = LOCKERINFO({
            _amount: amount_,
            _lockingTimestamp: block.timestamp,
            _unlockingTimestamp: 0
        });

        // emit event
        emit setLockerInfoEvent(
            msg.sender,
            TokenID_,
            holder_,
            locker_,
            amount_,
            block.timestamp
        );
    }

    // add account to lockers of token id by owner
    function appendToLockersOfTokenIDByOwner(
        uint256 TokenID_,
        address holder_,
        address locker_
    )
        public
        notNullAddress(holder_, "Holder Address")
        notNullAddress(locker_, "Locker Address")
        onlyMinted(TokenID_)
        onlyRole("SegMint ERC1155")
    {
        if (!_lockersOfTokenIDByOwnerStatus[TokenID_][holder_][locker_]) {
            _lockersOfTokenIDByOwner[TokenID_][holder_].push(locker_);
            _lockersOfTokenIDByOwnerStatus[TokenID_][holder_][locker_] = true;
        }
    }

    // remove account from lockers of token id by owner
    function removeFromLockersOfTokenIDByOwner(
        uint256 TokenID_,
        address holder_,
        address locker_
    )
        public
        notNullAddress(holder_, "Holder Address")
        notNullAddress(locker_, "Locker Address")
        onlyMinted(TokenID_)
        onlyRole("SegMint ERC1155")
    {
        if (_lockersOfTokenIDByOwnerStatus[TokenID_][holder_][locker_]) {
            for (
                uint256 i = 0;
                i < _lockersOfTokenIDByOwner[TokenID_][holder_].length;
                i++
            ) {
                if (_lockersOfTokenIDByOwner[TokenID_][holder_][i] == locker_) {
                    _lockersOfTokenIDByOwner[TokenID_][holder_][
                        i
                    ] = _lockersOfTokenIDByOwner[TokenID_][holder_][
                        _lockersOfTokenIDByOwner[TokenID_][holder_].length - 1
                    ];
                    _lockersOfTokenIDByOwner[TokenID_][holder_].pop();
                    _lockersOfTokenIDByOwnerStatus[TokenID_][holder_][
                        locker_
                    ] = false;
                    break;
                }
            }
        }
    }

    //// GETTERS ////

    // // get uri
    // function uri(uint256) public view returns (string memory) {
    //     return _uri;
    // }

    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    // get metadata
    function getMetaData(uint256 TokenID_)
        public
        view
        onlyMinted(TokenID_)
        returns (
            string memory name_,
            string memory symbol_,
            string memory description_,
            address minter_,
            uint256 totalSupply_
        )
    {
        return (
            _metaData[TokenID_]._name,
            _metaData[TokenID_]._symbol,
            _metaData[TokenID_]._description,
            _metaData[TokenID_]._minter,
            _metaData[TokenID_]._totalSupply
        );
    }

    // get balance Of
    function getBalanceOf(uint256 TokenID_, address account_)
        public
        view
        notNullAddress(account_, "Account")
        returns (uint256)
    {
        // return balance of
        return _balances[TokenID_][account_];
    }

    // get locked balance
    function getLockedBalance(uint256 TokenID_, address account_)
        public
        view
        notNullAddress(account_, "Account")
        onlyMinted(TokenID_)
        returns (uint256)
    {
        // return locked balance
        return _lockedBalances[TokenID_][account_];
    }

    // get available balance
    function getAvailableBalance(uint256 TokenID_, address account_)
        public
        view
        notNullAddress(account_, "Account")
        onlyMinted(TokenID_)
        returns (uint256)
    {
        // return available balance
        return
            _balances[TokenID_][account_] - _lockedBalances[TokenID_][account_];
    }

    // Sender has sufficient unlocked balance
    function HaveSufficientUnlockedBalance(
        uint256 TokenID_,
        address account_,
        uint256 amount_
    ) public view virtual notNullAddress(account_, "Account") {
        // require the account have available unlocked balance
        require(
            _balances[TokenID_][account_] -
                _lockedBalances[TokenID_][account_] >=
                amount_,
            string.concat(
                "SegMint ERC1155 DB: ",
                "Account ",
                Strings.toHexString(account_),
                " does not have sufficient unlocked token for TokenID : ",
                Strings.toString(TokenID_),
                "! The account current unlocked balance is ",
                Strings.toString(
                    _balances[TokenID_][account_] -
                        _lockedBalances[TokenID_][account_]
                )
            )
        );
    }

    // check if an address is locker of a token id for a holder
    function isLocker(
        uint256 TokenID_,
        address holder_,
        address locker_,
        uint256 lockedAmount_
    ) public view returns (bool) {
        return _lockerInfo[TokenID_][holder_][locker_]._amount >= lockedAmount_;
    }

    // get info of locker
    function getLockerInfo(
        uint256 TokenID_,
        address holder_,
        address locker_
    ) public view returns (LOCKERINFO memory) {
        return _lockerInfo[TokenID_][holder_][locker_];
    }

    // returns array of token holders of specific TokenID
    function getTokenIDHolders(uint256 TokenID_)
        public
        view
        returns (address[] memory)
    {
        return _holersOfTokenID[TokenID_];
    }

    // is minted
    function isMinted(uint256 TokenID_) public view returns (bool) {
        return _isMinted(TokenID_);
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    ////   Standard ERC1155 Functions    ////

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        // _uri = newuri;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(
            owner != operator,
            "SegMint ERC1155 DB: ERC1155: setting approval status for self"
        );
        _operatorApprovals[owner][operator] = approved;
        // emit ApprovalForAll(owner, operator, approved);
    }

    ////    SegMint Functions    ////

    // TokenID is minted?
    function _isMinted(uint256 TokenID_) internal view virtual returns (bool) {
        if (_holersOfTokenID[TokenID_].length > 1) {
            return true;
        } else if (_holersOfTokenID[TokenID_].length == 1) {
            if (_holersOfTokenID[TokenID_][0] == address(0)) {
                return false;
            } else {
                return true;
            }
        } else {
            return false;
        }
        // return _holersOfTokenID[TokenID_].length > 0;
    }
}