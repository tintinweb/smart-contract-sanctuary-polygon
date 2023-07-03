/**
 *Submitted for verification at polygonscan.com on 2023-07-03
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

// SegMint ERC1155 Whitelist Management Contract
contract SegMintERC1155WhitelistManagement {
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

    // whitelist manager address
    address private _whitelistManager;

    // global whitelist addresses
    address[] private _globalWhitelistAddresses;

    // global whitelist addresses status: Address => status
    mapping(address => bool) private _globalWhitelistAddressesStatus;

    // global SegMinting whitelist addresses
    address[] private _globalSegmintingWhitelistAddresses;

    // global SegMinting whitelist addresses status: Address => status
    mapping(address => bool) private _globalSegmintingWhitelistAddressesStatus;

    // global Reclaiming whitelist addresses
    address[] private _globalReclaimingWhitelistAddresses;

    // lobal Reclaiming whitelist addresses status: Address => status
    mapping(address => bool) private _globalReclaimingWhitelistAddressesStatus;

    // specific TokenID reclaiming whitelist addresses: TokenID => accounts
    mapping(uint256 => address[]) private _TokenIDReclaimingWhitelistAddresses;

    // specific TokenID reclaiming whitelist addresses status: TokenID => account => status
    mapping(uint256 => mapping(address => bool))
        private _TokenIDReclaimingWhitelistAddressesStatus;

    // all TokenIDes transfer whitelist addresses
    address[] private _globalTransferWhitelistAddresses;

    // all TokenIDes transfer whitelist addresses status: Address => status
    mapping(address => bool) private _globalTransferWhitelistAddressesStatus;

    // specific TokenID transfer whitelist addresses: TokenID => accounts
    mapping(uint256 => address[]) private _TokenIDTransferWhitelistAddresses;

    // specific TokenID transfer whitelist addresses status: TokenID => account => status
    mapping(uint256 => mapping(address => bool))
        private _TokenIDTransferWhitelistAddressesStatus;

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

    // set Whitelist Manager Address
    event setWhitelistManagerAddressEvent(
        address indexed OwnerAddress,
        address previousWhitelistManager,
        address indexed newWhitelistManager,
        uint256 indexed timestamp
    );

    // modify global whitelist
    event modifyGlobalWhitelistAddressesEvent(
        address indexed WhitelistManager,
        address indexed account,
        bool status,
        uint256 indexed timestamp
    );

    // modify global segminting whitelist addresses
    event modifyGlobalSegmintingWhitelistAddressesEvent(
        address indexed WhitelistManager,
        address indexed account,
        bool status,
        uint256 indexed timestamp
    );

    // modify global reclaiming whitelist addresses
    event modifyGlobalReclaimingwhitelistAddressesEvent(
        address indexed WhitelistManager,
        address indexed account,
        bool status,
        uint256 indexed timestamp
    );

    // modify TokenID reclaiming whitelist addresses
    event modifyTokenIDReclaimingwhitelistAddressesEvent(
        address indexed WhitelistManager,
        address indexed account,
        uint256 TokenID,
        bool status,
        uint256 indexed timestamp
    );

    // modify global transfer whitelist addresses
    event modifyGlobalTransferAddressesEvent(
        address indexed WhitelistManager,
        address indexed account,
        bool status,
        uint256 indexed timestamp
    );

    // modify TokenID transfer whitelist addresses
    event modifyTokenIDTransferAddressesEvent(
        address indexed WhitelistManager,
        address indexed account,
        uint256 TokenID,
        bool status,
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
                "SegMint ERC1155 Whitelist Management: ",
                "Sender ",
                Strings.toHexString(msg.sender),
                " is not the owner address!"
            )
        );
        _;
    }

    // only whitelist manager
    modifier onlyWhitelistManager() {
        // require sender be the whitelist manager address
        require(
            msg.sender == _whitelistManager,
            string.concat(
                "SegMint ERC1155 Whitelist Management: ",
                "Sender ",
                Strings.toHexString(msg.sender),
                " is not the Whitelist Manager Address!"
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
                "SegMint ERC1155 Whitelist Management: ",
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

    // get owner address
    function getOwnerAddress()
        public
        view 
        returns(address)
    {
        return _owner;
    }

    // set whitelist manager address
    function setWhitelistManagerAddress(address whitelistManager_)
        public
        onlyOwner
        notNullAddress(whitelistManager_, "Whitelist Manager Address")
    {
        // previous address
        address previousWhitelistManager = _whitelistManager;

        // update address
        _whitelistManager = whitelistManager_;

        // emit event
        emit setWhitelistManagerAddressEvent(
            msg.sender,
            previousWhitelistManager,
            whitelistManager_,
            block.timestamp
        );
    }

    // get whitelist manager address
    function getWhitelistManagerAddress()
        public
        view
        returns(address)
    {
        return _whitelistManager;
    }

    // add or remove an account in global whitelisted address
    function modifyGlobalWhitelistAddresses(address account_, bool status_)
        public
        notNullAddress(account_, "Account")
        onlyWhitelistManager
    {
        if (status_) {
            // add account to global whitelist
            _addAccountToGlobalWhitelistAddresses(account_);
        } else {
            // remove account from global whitelist
            _removeAccountFromGlobalWhitelistAddresses(account_);
        }

        // emit event
        emit modifyGlobalWhitelistAddressesEvent(
            msg.sender,
            account_,
            status_,
            block.timestamp
        );
    }

    // add or remove an account in global Segminting whitelisted address
    function modifyGlobalSegmintingWhitelistAddresses(
        address account_,
        bool status_
    ) public onlyWhitelistManager notNullAddress(account_, "Account") {
        if (status_) {
            // add account to global segminting whitelist
            _addAccountToGlobalSegmintingWhitelistAddresses(account_);
        } else {
            // remove account from global segminting whitelist
            _removeAccountFromGlobalSegmintingWhitelistAddresses(account_);
        }

        // emit event
        emit modifyGlobalSegmintingWhitelistAddressesEvent(
            msg.sender,
            account_,
            status_,
            block.timestamp
        );
    }

    // add or remove an account in global Segminting whitelisted address
    function modifyGlobalReclaimingwhitelistAddresses(
        address account_,
        bool status_
    ) public onlyWhitelistManager notNullAddress(account_, "Account") {
        if (status_) {
            // add account to global reclaiming whitelist
            _addAccountToGlobalReclaimingWhitelistAddresses(account_);
        } else {
            // remove account from global reclaiming whitelist
            _removeAccountFromGlobalReclaimingWhitelistAddresses(account_);
        }

        // emit event
        emit modifyGlobalReclaimingwhitelistAddressesEvent(
            msg.sender,
            account_,
            status_,
            block.timestamp
        );
    }

    // add or remove an account in TokenID reclaiming whitelisted address
    function modifyTokenIDReclaimingwhitelistAddresses(
        uint256 TokenID_,
        address account_,
        bool status_
    )
        public
        onlyWhitelistManager
        notNullAddress(account_, "Account")
    {
        if (status_) {
            // add account to TokenID reclaiming whitelist
            _addAccountToTokenIDReclaimingWhitelistAddresses(
                TokenID_,
                account_
            );
        } else {
            // remove account from TokenID reclaiming whitelist
            _removeAccountFromTokenIDReclaimingWhitelistAddresses(
                TokenID_,
                account_
            );
        }

        // emit event
        emit modifyTokenIDReclaimingwhitelistAddressesEvent(
            msg.sender,
            account_,
            TokenID_,
            status_,
            block.timestamp
        );
    }

    // add or remove an account in global transfer whitelisted address
    function modifyGlobalTransferAddresses(address account_, bool status_)
        public
        onlyWhitelistManager
        notNullAddress(account_, "Account")
    {
        if (status_) {
            // add account to global transfer whitelist
            _addAccountToGlobalTransferWhitelistAddresses(account_);
        } else {
            // remove account from global transfer whitelist
            _removeAccountFromGlobalTransferWhitelistAddresses(account_);
        }

        // emit event
        emit modifyGlobalTransferAddressesEvent(
            msg.sender,
            account_,
            status_,
            block.timestamp
        );
    }

    // add or remove an account as TokenID transfer whitelisted address
    function modifyTokenIDTransferAddresses(
        uint256 TokenID_,
        address account_,
        bool status_
    )
        public
        onlyWhitelistManager
        notNullAddress(account_, "Account")
    {
        if (status_) {
            // add account to TokenID transfer whitelist
            _addAccountToTokenIDTransferWhitelistAddresses(TokenID_, account_);
        } else {
            // remove account from TokenID transfer whitelist
            _removeAccountFromTokenIDTransferWhitelistAddresses(
                TokenID_,
                account_
            );
        }

        // emit event
        emit modifyTokenIDTransferAddressesEvent(
            msg.sender,
            account_,
            TokenID_,
            status_,
            block.timestamp
        );
    }

    // is global whitelisted
    function isGlobalWhitelisted(address account_) public view returns (bool) {
        return _globalWhitelistAddressesStatus[account_];
    }

    // get global whitelist addresses
    function getGlobalWhitelistAddresses()
        public
        view
        returns (address[] memory)
    {
        return _globalWhitelistAddresses;
    }

    // isGlobalSegmintingWhitelisted
    function isGlobalSegmintingWhitelisted(address account_)
        public
        view
        returns (bool)
    {
        return _globalSegmintingWhitelistAddressesStatus[account_];
    }

    // get global segminting whitelist addresses
    function getGlobalSegmintingWhitelistAddresses()
        public
        view
        returns (address[] memory)
    {
        return _globalSegmintingWhitelistAddresses;
    }

    // isGlobalReclaimingWhitelisted
    function isGlobalReclaimingWhitelisted(address account_)
        public
        view
        returns (bool)
    {
        return _globalReclaimingWhitelistAddressesStatus[account_];
    }

    // get global reclaiming whitelist addresses
    function getGlobalReclaimingWhitelistAddresses()
        public
        view
        returns (address[] memory)
    {
        return _globalReclaimingWhitelistAddresses;
    }

    // isTokenIDReclaimingWhitelisted
    function isTokenIDReclaimingWhitelisted(address account_, uint256 TokenID_)
        public
        view
        returns (bool)
    {
        return _TokenIDReclaimingWhitelistAddressesStatus[TokenID_][account_];
    }

    // get TokenID reclaiming whitelist addresses
    function getTokenIDReclaimingWhitelistAddresses(uint256 TokenID_)
        public
        view
        returns (address[] memory)
    {
        return _TokenIDReclaimingWhitelistAddresses[TokenID_];
    }


    // isGlobalTransferWhitelisted
    function isGlobalTransferWhitelisted(address account_)
        public
        view
        returns (bool)
    {
        return _globalTransferWhitelistAddressesStatus[account_];
    }

    // get global transfer whitelist addresses
    function getGlobalTransferWhitelistAddresses()
        public
        view
        returns (address[] memory)
    {
        return _globalTransferWhitelistAddresses;
    }

    // isTokenIDTransferWhitelisted
    function isTokenIDTransferWhitelisted(address account_, uint256 TokenID_)
        public
        view
        returns (bool)
    {
        return _TokenIDTransferWhitelistAddressesStatus[TokenID_][account_];
    }

    // get TokenID transfer whitelist addresses
    function getTokenIDTransferWhitelistAddresses(uint256 TokenID_)
        public
        view
        returns (address[] memory)
    {
        return _TokenIDTransferWhitelistAddresses[TokenID_];
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    // add account to _globalWhitelistAddresses
    function _addAccountToGlobalWhitelistAddresses(address account_) internal {
        if (!_globalWhitelistAddressesStatus[account_]) {
            _globalWhitelistAddresses.push(account_);
            _globalWhitelistAddressesStatus[account_] = true;
        }
    }

    // remove account from _globalWhitelistAddresses
    function _removeAccountFromGlobalWhitelistAddresses(address account_)
        internal
    {
        if (_globalWhitelistAddressesStatus[account_]) {
            for (uint256 i = 0; i < _globalWhitelistAddresses.length; i++) {
                if (_globalWhitelistAddresses[i] == account_) {
                    _globalWhitelistAddresses[i] = _globalWhitelistAddresses[
                        _globalWhitelistAddresses.length - 1
                    ];
                    _globalWhitelistAddresses.pop();
                    _globalWhitelistAddressesStatus[account_] = false;
                    break;
                }
            }
        }
    }

    // add account to _globalSegmintingWhitelistAddresses
    function _addAccountToGlobalSegmintingWhitelistAddresses(address account_)
        internal
    {
        if (!_globalSegmintingWhitelistAddressesStatus[account_]) {
            _globalSegmintingWhitelistAddresses.push(account_);
            _globalSegmintingWhitelistAddressesStatus[account_] = true;
        }
    }

    // remove account from _globalSegmintingWhitelistAddresses
    function _removeAccountFromGlobalSegmintingWhitelistAddresses(
        address account_
    ) internal {
        if (_globalSegmintingWhitelistAddressesStatus[account_]) {
            for (
                uint256 i = 0;
                i < _globalSegmintingWhitelistAddresses.length;
                i++
            ) {
                if (_globalSegmintingWhitelistAddresses[i] == account_) {
                    _globalSegmintingWhitelistAddresses[
                        i
                    ] = _globalSegmintingWhitelistAddresses[
                        _globalSegmintingWhitelistAddresses.length - 1
                    ];
                    _globalSegmintingWhitelistAddresses.pop();
                    _globalSegmintingWhitelistAddressesStatus[
                        account_
                    ] = false;
                    break;
                }
            }
        }
    }

    // add account to _globalReclaimingWhitelistAddresses
    function _addAccountToGlobalReclaimingWhitelistAddresses(address account_)
        internal
    {
        if (!_globalReclaimingWhitelistAddressesStatus[account_]) {
            _globalReclaimingWhitelistAddresses.push(account_);
            _globalReclaimingWhitelistAddressesStatus[account_] = true;
        }
    }

    // remove account from _globalReclaimingWhitelistAddresses
    function _removeAccountFromGlobalReclaimingWhitelistAddresses(
        address account_
    ) internal {
        if (_globalReclaimingWhitelistAddressesStatus[account_]) {
            for (
                uint256 i = 0;
                i < _globalReclaimingWhitelistAddresses.length;
                i++
            ) {
                if (_globalReclaimingWhitelistAddresses[i] == account_) {
                    _globalReclaimingWhitelistAddresses[
                        i
                    ] = _globalReclaimingWhitelistAddresses[
                        _globalReclaimingWhitelistAddresses.length - 1
                    ];
                    _globalReclaimingWhitelistAddresses.pop();
                    _globalReclaimingWhitelistAddressesStatus[account_] = false;
                    break;
                }
            }
        }
    }

    // add account to _TokenIDReclaimingWhitelistAddresses
    function _addAccountToTokenIDReclaimingWhitelistAddresses(
        uint256 TokenID_,
        address account_
    ) internal {
        if (!_TokenIDReclaimingWhitelistAddressesStatus[TokenID_][account_]) {
            _TokenIDReclaimingWhitelistAddresses[TokenID_].push(account_);
            _TokenIDReclaimingWhitelistAddressesStatus[TokenID_][
                account_
            ] = true;
        }
    }

    // remove account from _TokenIDReclaimingWhitelistAddresses
    function _removeAccountFromTokenIDReclaimingWhitelistAddresses(
        uint256 TokenID_,
        address account_
    ) internal {
        if (_TokenIDReclaimingWhitelistAddressesStatus[TokenID_][account_]) {
            for (
                uint256 i = 0;
                i < _TokenIDReclaimingWhitelistAddresses[TokenID_].length;
                i++
            ) {
                if (
                    _TokenIDReclaimingWhitelistAddresses[TokenID_][i] ==
                    account_
                ) {
                    _TokenIDReclaimingWhitelistAddresses[TokenID_][
                        i
                    ] = _TokenIDReclaimingWhitelistAddresses[TokenID_][
                        _TokenIDReclaimingWhitelistAddresses[TokenID_].length -
                            1
                    ];
                    _TokenIDReclaimingWhitelistAddresses[TokenID_].pop();
                    _TokenIDReclaimingWhitelistAddressesStatus[TokenID_][
                        account_
                    ] = false;
                    break;
                }
            }
        }
    }

    // add account to _globalTransferWhitelistAddresses
    function _addAccountToGlobalTransferWhitelistAddresses(address account_)
        internal
    {
        if (!_globalTransferWhitelistAddressesStatus[account_]) {
            _globalTransferWhitelistAddresses.push(account_);
            _globalTransferWhitelistAddressesStatus[account_] = true;
        }
    }

    // remove account from _globalTransferWhitelistAddresses
    function _removeAccountFromGlobalTransferWhitelistAddresses(
        address account_
    ) internal {
        if (_globalTransferWhitelistAddressesStatus[account_]) {
            for (
                uint256 i = 0;
                i < _globalTransferWhitelistAddresses.length;
                i++
            ) {
                if (_globalTransferWhitelistAddresses[i] == account_) {
                    _globalTransferWhitelistAddresses[
                        i
                    ] = _globalTransferWhitelistAddresses[
                        _globalTransferWhitelistAddresses.length - 1
                    ];
                    _globalTransferWhitelistAddresses.pop();
                    _globalTransferWhitelistAddressesStatus[account_] = false;
                    break;
                }
            }
        }
    }

    // add account to _TokenIDTransferWhitelistAddresses
    function _addAccountToTokenIDTransferWhitelistAddresses(
        uint256 TokenID_,
        address account_
    ) internal {
        if (!_TokenIDTransferWhitelistAddressesStatus[TokenID_][account_]) {
            _TokenIDTransferWhitelistAddresses[TokenID_].push(account_);
            _TokenIDTransferWhitelistAddressesStatus[TokenID_][account_] = true;
        }
    }

    // remove account from _TokenIDTransferWhitelistAddresses
    function _removeAccountFromTokenIDTransferWhitelistAddresses(
        uint256 TokenID_,
        address account_
    ) internal {
        if (_TokenIDTransferWhitelistAddressesStatus[TokenID_][account_]) {
            for (
                uint256 i = 0;
                i < _TokenIDTransferWhitelistAddresses[TokenID_].length;
                i++
            ) {
                if (
                    _TokenIDTransferWhitelistAddresses[TokenID_][i] == account_
                ) {
                    _TokenIDTransferWhitelistAddresses[TokenID_][
                        i
                    ] = _TokenIDTransferWhitelistAddresses[TokenID_][
                        _TokenIDTransferWhitelistAddresses[TokenID_].length - 1
                    ];
                    _TokenIDTransferWhitelistAddresses[TokenID_].pop();
                    _TokenIDTransferWhitelistAddressesStatus[TokenID_][
                        account_
                    ] = false;
                    break;
                }
            }
        }
    }
}