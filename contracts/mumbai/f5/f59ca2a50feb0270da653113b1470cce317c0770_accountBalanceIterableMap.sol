/**
 *Submitted for verification at polygonscan.com on 2023-01-15
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File @openzeppelin/contracts/utils/math/[email protected]

// License-Identifier: MIT
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


// File @openzeppelin/contracts/utils/[email protected]

// License-Identifier: MIT
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


// File contracts/iterableMapLib.sol

// License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

library pendingRentFeeIterableMap {
    struct pendingRentFee {
        address renterAddress;
        address serviceAddress;
        address feeTokenAddress;
        uint256 amount;
    }

    struct pendingRentFeeEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        pendingRentFee data;
    }

    struct pendingRentFeeMap {
        mapping(string => pendingRentFeeEntry) data;
        string[] keys;
    }

    function encodeKey(
        address renterAddress,
        address serviceAddress,
        address feeTokenAddress
    ) public pure returns (string memory) {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(renterAddress)), 20),
                Strings.toHexString(uint256(uint160(serviceAddress)), 20),
                Strings.toHexString(uint256(uint160(feeTokenAddress)), 20)
            )
        );

        return keyString;
    }

    function decodeKey(pendingRentFeeMap storage self, string memory key)
        public
        view
        returns (
            address renterAddress,
            address serviceAddress,
            address feeTokenAddress
        )
    {
        pendingRentFeeEntry memory e = self.data[key];

        return (
            e.data.renterAddress,
            e.data.serviceAddress,
            e.data.feeTokenAddress
        );
    }

    function insert(
        pendingRentFeeMap storage self,
        address renterAddress,
        address serviceAddress,
        address feeTokenAddress,
        uint256 amount
    ) public returns (bool success) {
        string memory key = encodeKey(
            renterAddress,
            serviceAddress,
            feeTokenAddress
        );
        pendingRentFeeEntry storage e = self.data[key];

        if (e.idx > 0) {
            return false;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.renterAddress = renterAddress;
            e.data.serviceAddress = serviceAddress;
            e.data.feeTokenAddress = feeTokenAddress;
            e.data.amount = amount;

            return true;
        }
    }

    function add(
        pendingRentFeeMap storage self,
        address renterAddress,
        address serviceAddress,
        address feeTokenAddress,
        uint256 amount
    ) public returns (bool success) {
        string memory key = encodeKey(
            renterAddress,
            serviceAddress,
            feeTokenAddress
        );
        pendingRentFeeEntry storage e = self.data[key];

        if (e.idx > 0) {
            e.data.amount = e.data.amount + amount;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.renterAddress = renterAddress;
            e.data.serviceAddress = serviceAddress;
            e.data.feeTokenAddress = feeTokenAddress;
            e.data.amount = amount;
        }

        return true;
    }

    function sub(
        pendingRentFeeMap storage self,
        address renterAddress,
        address serviceAddress,
        address feeTokenAddress,
        uint256 amount
    ) public returns (bool success) {
        string memory key = encodeKey(
            renterAddress,
            serviceAddress,
            feeTokenAddress
        );
        pendingRentFeeEntry storage e = self.data[key];

        if (e.idx > 0 && e.data.amount >= amount) {
            e.data.amount = e.data.amount - amount;

            if (e.data.amount == 0) {
                remove(self, renterAddress, serviceAddress, feeTokenAddress);
            }
            return true;
        } else {
            return false;
        }
    }

    function remove(
        pendingRentFeeMap storage self,
        address renterAddress,
        address serviceAddress,
        address feeTokenAddress
    ) public returns (bool success) {
        string memory key = encodeKey(
            renterAddress,
            serviceAddress,
            feeTokenAddress
        );
        pendingRentFeeEntry storage e = self.data[key];

        // Check if entry not exist or invalid idx value.
        if (e.idx == 0 || e.idx > self.keys.length) {
            return false;
        }

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(
        pendingRentFeeMap storage self,
        address renterAddress,
        address serviceAddress,
        address feeTokenAddress
    ) public view returns (bool exists) {
        string memory key = encodeKey(
            renterAddress,
            serviceAddress,
            feeTokenAddress
        );
        return self.data[key].idx > 0;
    }

    function size(pendingRentFeeMap storage self)
        public
        view
        returns (uint256)
    {
        return self.keys.length;
    }

    function getAmount(
        pendingRentFeeMap storage self,
        address renterAddress,
        address serviceAddress,
        address feeTokenAddress
    ) public view returns (uint256) {
        string memory key = encodeKey(
            renterAddress,
            serviceAddress,
            feeTokenAddress
        );
        return self.data[key].data.amount;
    }

    function getByAddress(
        pendingRentFeeMap storage self,
        address renterAddress,
        address serviceAddress,
        address feeTokenAddress
    ) public view returns (pendingRentFee memory) {
        string memory key = encodeKey(
            renterAddress,
            serviceAddress,
            feeTokenAddress
        );
        return self.data[key].data;
    }

    function getKeyByIndex(pendingRentFeeMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(pendingRentFeeMap storage self, uint256 idx)
        public
        view
        returns (pendingRentFee memory)
    {
        return self.data[self.keys[idx]].data;
    }
}

library accountBalanceIterableMap {
    struct accountBalance {
        address accountAddress;
        address tokenAddress;
        uint256 amount;
    }

    struct accountBalanceEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        accountBalance data;
    }

    struct accountBalanceMap {
        mapping(string => accountBalanceEntry) data;
        string[] keys;
    }

    function encodeKey(address accountAddress, address tokenAddress)
        public
        pure
        returns (string memory)
    {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(accountAddress)), 20),
                Strings.toHexString(uint256(uint160(tokenAddress)), 20)
            )
        );

        return keyString;
    }

    function decodeKey(accountBalanceMap storage self, string memory key)
        public
        view
        returns (address accountAddress, address tokenAddress)
    {
        accountBalanceEntry memory e = self.data[key];

        return (e.data.accountAddress, e.data.tokenAddress);
    }

    function add(
        accountBalanceMap storage self,
        address accountAddress,
        address tokenAddress,
        uint256 amount
    ) public returns (bool success) {
        string memory key = encodeKey(accountAddress, tokenAddress);
        accountBalanceEntry storage e = self.data[key];

        if (e.idx > 0) {
            e.data.amount = e.data.amount + amount;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.accountAddress = accountAddress;
            e.data.tokenAddress = tokenAddress;
            e.data.amount = amount;
        }

        return true;
    }

    function insert(
        accountBalanceMap storage self,
        address accountAddress,
        address tokenAddress,
        uint256 amount
    ) public returns (bool success) {
        string memory key = encodeKey(accountAddress, tokenAddress);
        accountBalanceEntry storage e = self.data[key];

        if (e.idx > 0) {
            return false;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.accountAddress = accountAddress;
            e.data.tokenAddress = tokenAddress;
            e.data.amount = amount;

            return true;
        }
    }

    function remove(
        accountBalanceMap storage self,
        address accountAddress,
        address tokenAddress
    ) public returns (bool success) {
        string memory key = encodeKey(accountAddress, tokenAddress);
        accountBalanceEntry storage e = self.data[key];

        // Check if entry not exist or invalid idx value.
        if (e.idx == 0 || e.idx > self.keys.length) {
            return false;
        }

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(
        accountBalanceMap storage self,
        address accountAddress,
        address tokenAddress
    ) public view returns (bool exists) {
        string memory key = encodeKey(accountAddress, tokenAddress);
        return self.data[key].idx > 0;
    }

    function size(accountBalanceMap storage self)
        public
        view
        returns (uint256)
    {
        return self.keys.length;
    }

    function getAmount(
        accountBalanceMap storage self,
        address accountAddress,
        address tokenAddress
    ) public view returns (uint256) {
        string memory key = encodeKey(accountAddress, tokenAddress);
        return self.data[key].data.amount;
    }

    function getByAddress(
        accountBalanceMap storage self,
        address accountAddress,
        address tokenAddress
    ) public view returns (accountBalance memory) {
        string memory key = encodeKey(accountAddress, tokenAddress);
        return self.data[key].data;
    }

    function getKeyByIndex(accountBalanceMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(accountBalanceMap storage self, uint256 idx)
        public
        view
        returns (accountBalance memory)
    {
        return self.data[self.keys[idx]].data;
    }
}

library tokenDataIterableMap {
    struct tokenData {
        address tokenAddress;
        string name;
    }

    struct tokenDataEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        tokenData data;
    }

    struct tokenDataMap {
        mapping(string => tokenDataEntry) data;
        string[] keys;
    }

    function encodeKey(address tokenAddress)
        public
        pure
        returns (string memory)
    {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(tokenAddress)), 20)
            )
        );

        return keyString;
    }

    function decodeKey(tokenDataMap storage self, string memory key)
        public
        view
        returns (address tokenAddress)
    {
        tokenDataEntry memory e = self.data[key];

        return e.data.tokenAddress;
    }

    function insert(
        tokenDataMap storage self,
        address tokenAddress,
        string memory name
    ) public returns (bool success) {
        string memory key = encodeKey(tokenAddress);
        tokenDataEntry storage e = self.data[key];

        if (e.idx > 0) {
            return false;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.tokenAddress = tokenAddress;
            e.data.name = name;

            return true;
        }
    }

    function remove(tokenDataMap storage self, address tokenAddress)
        public
        returns (bool success)
    {
        string memory key = encodeKey(tokenAddress);
        tokenDataEntry storage e = self.data[key];

        // Check if entry not exist or invalid idx value.
        if (e.idx == 0 || e.idx > self.keys.length) {
            return false;
        }

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(tokenDataMap storage self, address tokenAddress)
        public
        view
        returns (bool exists)
    {
        string memory key = encodeKey(tokenAddress);
        return self.data[key].idx > 0;
    }

    function size(tokenDataMap storage self) public view returns (uint256) {
        return self.keys.length;
    }

    function getName(tokenDataMap storage self, address tokenAddress)
        public
        view
        returns (string memory)
    {
        string memory key = encodeKey(tokenAddress);
        return self.data[key].data.name;
    }

    function getByAddress(tokenDataMap storage self, address tokenAddress)
        public
        view
        returns (tokenData memory)
    {
        string memory key = encodeKey(tokenAddress);
        return self.data[key].data;
    }

    function getKeyByIndex(tokenDataMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(tokenDataMap storage self, uint256 idx)
        public
        view
        returns (tokenData memory)
    {
        return self.data[self.keys[idx]].data;
    }
}

library collectionDataIterableMap {
    struct collectionData {
        address collectionAddress;
        string uri;
    }

    struct collectionDataEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        collectionData data;
    }

    struct collectionDataMap {
        mapping(string => collectionDataEntry) data;
        string[] keys;
    }

    function encodeKey(address collectionAddress)
        public
        pure
        returns (string memory)
    {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(collectionAddress)), 20)
            )
        );

        return keyString;
    }

    function decodeKey(collectionDataMap storage self, string memory key)
        public
        view
        returns (address collectionAddress)
    {
        collectionDataEntry memory e = self.data[key];

        return e.data.collectionAddress;
    }

    function insert(
        collectionDataMap storage self,
        address collectionAddress,
        string memory uri
    ) public returns (bool success) {
        string memory key = encodeKey(collectionAddress);
        collectionDataEntry storage e = self.data[key];

        if (e.idx > 0) {
            return false;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.collectionAddress = collectionAddress;
            e.data.uri = uri;

            return true;
        }
    }

    function remove(collectionDataMap storage self, address collectionAddress)
        public
        returns (bool success)
    {
        string memory key = encodeKey(collectionAddress);
        collectionDataEntry storage e = self.data[key];

        // Check if entry not exist or invalid idx value.
        if (e.idx == 0 || e.idx > self.keys.length) {
            return false;
        }

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(collectionDataMap storage self, address collectionAddress)
        public
        view
        returns (bool exists)
    {
        string memory key = encodeKey(collectionAddress);
        return self.data[key].idx > 0;
    }

    function size(collectionDataMap storage self)
        public
        view
        returns (uint256)
    {
        return self.keys.length;
    }

    function getUri(collectionDataMap storage self, address collectionAddress)
        public
        view
        returns (string memory)
    {
        string memory key = encodeKey(collectionAddress);
        return self.data[key].data.uri;
    }

    function getByAddress(
        collectionDataMap storage self,
        address collectionAddress
    ) public view returns (collectionData memory) {
        string memory key = encodeKey(collectionAddress);
        return self.data[key].data;
    }

    function getKeyByIndex(collectionDataMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(collectionDataMap storage self, uint256 idx)
        public
        view
        returns (collectionData memory)
    {
        return self.data[self.keys[idx]].data;
    }
}

library serviceDataIterableMap {
    struct serviceData {
        address serviceAddress;
        string uri;
    }

    struct serviceDataEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        serviceData data;
    }

    struct serviceDataMap {
        mapping(string => serviceDataEntry) data;
        string[] keys;
    }

    function encodeKey(address serviceAddress)
        public
        pure
        returns (string memory)
    {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(serviceAddress)), 20)
            )
        );

        return keyString;
    }

    function decodeKey(serviceDataMap storage self, string memory key)
        public
        view
        returns (address serviceAddress)
    {
        serviceDataEntry memory e = self.data[key];

        return e.data.serviceAddress;
    }

    function insert(
        serviceDataMap storage self,
        address serviceAddress,
        string memory uri
    ) public returns (bool success) {
        string memory key = encodeKey(serviceAddress);
        serviceDataEntry storage e = self.data[key];

        if (e.idx > 0) {
            return false;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.serviceAddress = serviceAddress;
            e.data.uri = uri;

            return true;
        }
    }

    function remove(serviceDataMap storage self, address serviceAddress)
        public
        returns (bool success)
    {
        string memory key = encodeKey(serviceAddress);
        serviceDataEntry storage e = self.data[key];

        // Check if entry not exist or invalid idx value.
        if (e.idx == 0 || e.idx > self.keys.length) {
            return false;
        }

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(serviceDataMap storage self, address serviceAddress)
        public
        view
        returns (bool exists)
    {
        string memory key = encodeKey(serviceAddress);
        return self.data[key].idx > 0;
    }

    function size(serviceDataMap storage self) public view returns (uint256) {
        return self.keys.length;
    }

    function getUri(serviceDataMap storage self, address serviceAddress)
        public
        view
        returns (string memory)
    {
        string memory key = encodeKey(serviceAddress);
        return self.data[key].data.uri;
    }

    function getByAddress(serviceDataMap storage self, address serviceAddress)
        public
        view
        returns (serviceData memory)
    {
        string memory key = encodeKey(serviceAddress);
        return self.data[key].data;
    }

    function getKeyByIndex(serviceDataMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(serviceDataMap storage self, uint256 idx)
        public
        view
        returns (serviceData memory)
    {
        return self.data[self.keys[idx]].data;
    }
}

library requestDataIterableMap {
    struct requestData {
        address nftAddress;
        uint256 tokenId;
    }

    struct requestDataEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        requestData data;
    }

    struct requestDataMap {
        mapping(string => requestDataEntry) data;
        string[] keys;
    }

    function encodeKey(address nftAddress, uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(nftAddress)), 20),
                Strings.toString(tokenId)
            )
        );

        return keyString;
    }

    function decodeKey(requestDataMap storage self, string memory key)
        public
        view
        returns (address nftAddress, uint256 tokenId)
    {
        requestDataEntry memory e = self.data[key];

        return (e.data.nftAddress, e.data.tokenId);
    }

    function insert(
        requestDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public returns (bool success) {
        string memory key = encodeKey(nftAddress, tokenId);
        requestDataEntry storage e = self.data[key];

        if (e.idx > 0) {
            return false;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.nftAddress = nftAddress;
            e.data.tokenId = tokenId;

            return true;
        }
    }

    function remove(
        requestDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public returns (bool success) {
        string memory key = encodeKey(nftAddress, tokenId);
        requestDataEntry storage e = self.data[key];

        // Check if entry not exist or invalid idx value.
        if (e.idx == 0 || e.idx > self.keys.length) {
            return false;
        }

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(
        requestDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public view returns (bool exists) {
        string memory key = encodeKey(nftAddress, tokenId);
        return self.data[key].idx > 0;
    }

    function size(requestDataMap storage self) public view returns (uint256) {
        return self.keys.length;
    }

    function getByNFT(
        requestDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public view returns (requestData memory) {
        string memory key = encodeKey(nftAddress, tokenId);
        return self.data[key].data;
    }

    function getKeyByIndex(requestDataMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(requestDataMap storage self, uint256 idx)
        public
        view
        returns (requestData memory)
    {
        return self.data[self.keys[idx]].data;
    }
}

library registerDataIterableMap {
    struct registerData {
        address nftAddress;
        uint256 tokenId;
        uint256 rentFee;
        address feeTokenAddress;
        uint256 rentFeeByToken;
        uint256 rentDuration;
    }

    struct registerDataEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        registerData data;
    }

    struct registerDataMap {
        mapping(string => registerDataEntry) data;
        string[] keys;
    }

    function encodeKey(address nftAddress, uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(nftAddress)), 20),
                Strings.toString(tokenId)
            )
        );

        return keyString;
    }

    function decodeKey(registerDataMap storage self, string memory key)
        public
        view
        returns (address nftAddress, uint256 tokenId)
    {
        registerDataEntry memory e = self.data[key];

        return (e.data.nftAddress, e.data.tokenId);
    }

    function insert(
        registerDataMap storage self,
        address nftAddress,
        uint256 tokenId,
        uint256 rentFee,
        address feeTokenAddress,
        uint256 rentFeeByToken,
        uint256 rentDuration
    ) public returns (bool success) {
        string memory key = encodeKey(nftAddress, tokenId);
        registerDataEntry storage e = self.data[key];

        if (e.idx > 0) {
            return false;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.nftAddress = nftAddress;
            e.data.tokenId = tokenId;
            e.data.rentFee = rentFee;
            e.data.feeTokenAddress = feeTokenAddress;
            e.data.rentFeeByToken = rentFeeByToken;
            e.data.rentDuration = rentDuration;

            return true;
        }
    }

    function set(
        registerDataMap storage self,
        address nftAddress,
        uint256 tokenId,
        uint256 rentFee,
        address feeTokenAddress,
        uint256 rentFeeByToken,
        uint256 rentDuration
    ) public returns (bool success) {
        string memory key = encodeKey(nftAddress, tokenId);
        registerDataEntry storage e = self.data[key];

        // Check if entry not exist or invalid idx value.
        if (e.idx == 0 || e.idx > self.keys.length) {
            return false;
        }

        // Set data.
        e.data.rentFee = rentFee;
        e.data.feeTokenAddress = feeTokenAddress;
        e.data.rentFeeByToken = rentFeeByToken;
        e.data.rentDuration = rentDuration;

        return true;
    }

    function remove(
        registerDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public returns (bool success) {
        string memory key = encodeKey(nftAddress, tokenId);
        registerDataEntry storage e = self.data[key];

        // Check if entry not exist or invalid idx value.
        if (e.idx == 0 || e.idx > self.keys.length) {
            return false;
        }

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(
        registerDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public view returns (bool exists) {
        string memory key = encodeKey(nftAddress, tokenId);
        return self.data[key].idx > 0;
    }

    function size(registerDataMap storage self) public view returns (uint256) {
        return self.keys.length;
    }

    function getByNFT(
        registerDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public view returns (registerData memory) {
        string memory key = encodeKey(nftAddress, tokenId);
        return self.data[key].data;
    }

    function getKeyByIndex(registerDataMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(registerDataMap storage self, uint256 idx)
        public
        view
        returns (registerData memory)
    {
        return self.data[self.keys[idx]].data;
    }
}

library rentDataIterableMap {
    struct rentData {
        address nftAddress;
        uint256 tokenId;
        uint256 rentFee;
        address feeTokenAddress;
        uint256 rentFeeByToken;
        bool isRentByToken;
        uint256 rentDuration;
        address renterAddress;
        address renteeAddress;
        address serviceAddress;
        uint256 rentStartTimestamp;
    }

    struct rentDataEntry {
        // idx should be same as the index of the key of this item in keys + 1.
        uint256 idx;
        rentData data;
    }

    struct rentDataMap {
        mapping(string => rentDataEntry) data;
        string[] keys;
    }

    function encodeKey(address nftAddress, uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        string memory keyString = string(
            abi.encodePacked(
                Strings.toHexString(uint256(uint160(nftAddress)), 20),
                Strings.toString(tokenId)
            )
        );

        return keyString;
    }

    function decodeKey(rentDataMap storage self, string memory key)
        public
        view
        returns (address nftAddress, uint256 tokenId)
    {
        rentDataEntry memory e = self.data[key];

        return (e.data.nftAddress, e.data.tokenId);
    }

    function insert(rentDataMap storage self, rentData memory data)
        public
        returns (bool success)
    {
        string memory key = encodeKey(data.nftAddress, data.tokenId);
        rentDataEntry storage e = self.data[key];

        if (e.idx > 0) {
            return false;
        } else {
            // Add self.keys.
            self.keys.push(key);

            // Add self.data.
            e.idx = self.keys.length;
            e.data.nftAddress = data.nftAddress;
            e.data.tokenId = data.tokenId;
            e.data.rentFee = data.rentFee;
            e.data.feeTokenAddress = data.feeTokenAddress;
            e.data.rentFeeByToken = data.rentFeeByToken;
            e.data.isRentByToken = data.isRentByToken;
            e.data.rentDuration = data.rentDuration;
            e.data.renterAddress = data.renterAddress;
            e.data.renteeAddress = data.renteeAddress;
            e.data.serviceAddress = data.serviceAddress;
            e.data.rentStartTimestamp = data.rentStartTimestamp;

            return true;
        }
    }

    function remove(
        rentDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public returns (bool success) {
        string memory key = encodeKey(nftAddress, tokenId);
        rentDataEntry storage e = self.data[key];

        // Check if entry not exist or invalid idx value.
        if (e.idx == 0 || e.idx > self.keys.length) {
            return false;
        }

        // Move an existing element into the vacated key slot.
        uint256 mapKeyArrayIndex = e.idx - 1;
        uint256 keyArrayLastIndex = self.keys.length - 1;

        // Move.
        self.data[self.keys[keyArrayLastIndex]].idx = mapKeyArrayIndex + 1;
        self.keys[mapKeyArrayIndex] = self.keys[keyArrayLastIndex];

        // Delete self.keys.
        self.keys.pop();

        // Delete self.data.
        delete self.data[key];

        return true;
    }

    function contains(
        rentDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public view returns (bool exists) {
        string memory key = encodeKey(nftAddress, tokenId);
        return self.data[key].idx > 0;
    }

    function size(rentDataMap storage self) public view returns (uint256) {
        return self.keys.length;
    }

    function getByNFT(
        rentDataMap storage self,
        address nftAddress,
        uint256 tokenId
    ) public view returns (rentData memory) {
        string memory key = encodeKey(nftAddress, tokenId);
        return self.data[key].data;
    }

    function getKeyByIndex(rentDataMap storage self, uint256 idx)
        public
        view
        returns (string memory)
    {
        return self.keys[idx];
    }

    function getDataByIndex(rentDataMap storage self, uint256 idx)
        public
        view
        returns (rentData memory)
    {
        return self.data[self.keys[idx]].data;
    }
}