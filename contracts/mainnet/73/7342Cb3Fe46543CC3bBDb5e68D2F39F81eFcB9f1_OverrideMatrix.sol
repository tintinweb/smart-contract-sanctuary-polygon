/**
 *Submitted for verification at polygonscan.com on 2023-02-28
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


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

// File: @openzeppelin/contracts/utils/math/Math.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: test/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);


    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;
}
// File: test/OverrideMatrix.sol


pragma solidity ^0.8.9;




contract OverrideMatrix is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant SETENV_ROLE = keccak256("SETENV_ROLE");
    bytes32 public constant REMOVE_ROLE = keccak256("REMOVE_ROLE");
    bytes32 public constant INIT_ROLE = keccak256("INIT_ROLE");

    struct matrix6 {
        address vertex;
        address upper;
        address[2] upperLayer;
        address[4] lowerLayer;
        uint256 amount;
        bool isReVote;
    }

    struct matrix3 {
        address vertex;
        address[3] upperLayer;
        uint256 amount;
        bool isReVote;
    }

    struct accountInfo {
        bool isRegister;
        address referRecommender;
        uint256 currentMaxGrade;
        mapping(uint256 => bool) gradeExist;
        mapping(uint256 => matrix6) matrix6Grade;
        mapping(uint256 => matrix3) matrix3Grade;
        mapping(uint256 => bool) isPauseAutoNewGrant;
        mapping(uint256 => bool) isPauseAutoReVote;
    }

    mapping(address => accountInfo) private accountInfoList;

    address public noReferPlatform;
    address public feePlatform;
    uint256 public maxAuto = 20;
    uint256 public baseRewardRate = 1e18;
    uint256 public baseLocationPrice = 5e6;
    uint256 public basePlatformRate = 25e4;

    IERC20 public USDToken;
    IERC20 public Token;

    uint256 public constant maxGrade = 12;
    uint256 private rate = 1e6;
    uint256 private perAutoTimes = 0;

    event NewLocationEvent(
        address indexed account,
        address indexed location,
        uint256 grade,
        uint256 index
    );

    constructor(address _usdt, address _token, address _noReferPlatform, address _feePlatform, address _initAcc) {
        // 0x538935d9bd028bF29D4c3B6BDd5AA02D885D59e2
        _grantRole(DEFAULT_ADMIN_ROLE, 0xB20F205C0a6B02e1024a6116031CA4406b03Ef86);
        // 0x538935d9bd028bF29D4c3B6BDd5AA02D885D59e2
        _grantRole(SETENV_ROLE, 0xB20F205C0a6B02e1024a6116031CA4406b03Ef86);
        // 0x538935d9bd028bF29D4c3B6BDd5AA02D885D59e2
        _grantRole(REMOVE_ROLE, 0xB20F205C0a6B02e1024a6116031CA4406b03Ef86);
        // 0x538935d9bd028bF29D4c3B6BDd5AA02D885D59e2
        _grantRole(INIT_ROLE, 0xB20F205C0a6B02e1024a6116031CA4406b03Ef86);

        USDToken = IERC20(_usdt); // 
        Token = IERC20(_token); // 
        noReferPlatform = _noReferPlatform; // 
        feePlatform = _feePlatform;  // 

        accountInfoList[_initAcc].isRegister = true; // 
    }

    function refer(address _refer) public {
        require(
            accountInfoList[_refer].referRecommender != _msgSender() &&
            accountInfoList[_msgSender()].referRecommender == address(0) &&
            _refer != address(0),
            "param account error"
        );
        require(accountInfoList[_refer].isRegister, "refer not registered");
        accountInfoList[_msgSender()].isRegister = true;
        accountInfoList[_msgSender()].referRecommender = _refer;
    }

    function newLocation(uint256 newGrade) public {
        require(newGrade > 0 && newGrade <= maxGrade, "param newGrade error");
        _newLocation(_msgSender(), newGrade);
        perAutoTimes = 0;
    }

    function openAutoGrade(uint256 grade) public {
        require(accountInfoList[_msgSender()].isPauseAutoNewGrant[grade], "already open AutoGrade");
        require(grade > 0 && grade < maxGrade, "param grade error");
        require(accountInfoList[_msgSender()].gradeExist[grade], "grade not exist");
        uint256 member = matrixMember(grade);
        if (member == 3) {
            require(accountInfoList[_msgSender()].matrix3Grade[grade].upperLayer[0] == address(0), "not close");
        } else {
            require(accountInfoList[_msgSender()].matrix6Grade[grade].lowerLayer[1] == address(0), "not close");
            require(accountInfoList[_msgSender()].matrix6Grade[grade].lowerLayer[2] == address(0), "not close");
        }
        accountInfoList[_msgSender()].isPauseAutoNewGrant[grade] = false;
    }

    function closeAutoGrade(uint256 grade) public {
        require(!accountInfoList[_msgSender()].isPauseAutoNewGrant[grade], "already close AutoGrade");
        require(grade > 0 && grade < maxGrade, "param grade error");
        require(accountInfoList[_msgSender()].gradeExist[grade], "grade not exist");
        uint256 member = matrixMember(grade);
        if (member == 3) {
            require(accountInfoList[_msgSender()].matrix3Grade[grade].upperLayer[0] == address(0), "not close");
        } else {
            require(accountInfoList[_msgSender()].matrix6Grade[grade].lowerLayer[1] == address(0), "not close");
            require(accountInfoList[_msgSender()].matrix6Grade[grade].lowerLayer[2] == address(0), "not close");
        }
        accountInfoList[_msgSender()].isPauseAutoNewGrant[grade] = true;
    }

    function openAutoVote(uint256 grade) public {
        require(accountInfoList[_msgSender()].isPauseAutoReVote[grade], "already open AutoVote");
        require(grade > 0 && grade < maxGrade && accountInfoList[_msgSender()].gradeExist[grade], "param grade error");
        accountInfoList[_msgSender()].isPauseAutoReVote[grade] = false;
    }

    function closeAutoVote(uint256 grade) public {
        require(!accountInfoList[_msgSender()].isPauseAutoReVote[grade], "already close AutoVote");
        accountInfoList[_msgSender()].isPauseAutoReVote[grade] = true;
    }

    function setBasePrice(uint256 amount) public onlyRole(SETENV_ROLE) {
        baseLocationPrice = amount;
    }

    function setMaxAuto(uint256 max) public onlyRole(SETENV_ROLE) {
        maxAuto = max;
    }

    function setBasePlatformRate(uint256 newRate) public onlyRole(SETENV_ROLE) {
        basePlatformRate = newRate;
    }

    function setNoReferPlatform(address platform) public onlyRole(SETENV_ROLE) {
        noReferPlatform = platform;
    }

    function setFeePlatform(address platform) public onlyRole(SETENV_ROLE) {
        feePlatform = platform;
    }

    function removeLiquidity(address token, address account, uint256 amount) public onlyRole(REMOVE_ROLE) {
        IERC20(token).transfer(account, amount);
    }

    function initRefer(address upper, address lower) public onlyRole(INIT_ROLE) {
        if (!accountInfoList[upper].isRegister) {
            accountInfoList[upper].isRegister = true;
        }
        if (!accountInfoList[lower].isRegister) {
            accountInfoList[lower].isRegister = true;
        }
        require(accountInfoList[lower].referRecommender == address(0) && accountInfoList[upper].referRecommender != lower);
        accountInfoList[lower].referRecommender = upper;
    }

    function _newLocation(address _account, uint256 _newGrade) internal {
        require(!accountInfoList[_account].gradeExist[_newGrade], "this grade already exists");
        require(accountInfoList[_account].currentMaxGrade.add(1) >= _newGrade, "new grade is more than the current");
        require(accountInfoList[_account].isRegister, "account must has recommender");
        uint256 price = currentPrice(_newGrade);
        USDToken.transferFrom(_account, address(this), price);
        Token.mint(_account, price.mul(baseRewardRate).div(rate));
        _addLocations(_account, accountInfoList[_account].referRecommender, _newGrade);
    }

    function _addLocations(address _account, address _vertex, uint256 _newGrade) internal {
        uint256 types = matrixMember(_newGrade);
        if (_vertex != address(0)) {
            if (!accountInfoList[_vertex].gradeExist[_newGrade]) {
                _vertex = address(0);
                USDToken.transfer(noReferPlatform, currentPrice(_newGrade));
                accountInfoList[_account].gradeExist[_newGrade] = true;
                if (accountInfoList[_account].currentMaxGrade < _newGrade) {
                    accountInfoList[_account].currentMaxGrade = _newGrade;
                }
                return;
            }
        } else {
            USDToken.transfer(noReferPlatform, currentPrice(_newGrade));
            accountInfoList[_account].gradeExist[_newGrade] = true;
            if (accountInfoList[_account].currentMaxGrade < _newGrade) {
                accountInfoList[_account].currentMaxGrade = _newGrade;
            }
            return;
        }
        if (types == 6) {
            if (_vertex != address(0)) {
                _addLocationsTo6(_account, _vertex, _newGrade);
            }
        }
        if (types == 3) {
            accountInfoList[_account].matrix3Grade[_newGrade].vertex = _vertex;
            if (_vertex != address(0)) {
                _addLocationsTo3(_account, _vertex, _newGrade);
            }
        }
        accountInfoList[_account].gradeExist[_newGrade] = true;
        if (accountInfoList[_account].currentMaxGrade < _newGrade) {
            accountInfoList[_account].currentMaxGrade = _newGrade;
        }
    }

    function _addLocationsTo6(address _account, address _vertex, uint256 _grade) internal {
        if (accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[0] == address(0) ||
            accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[1] == address(0)) {
            if (accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[0] == address(0)) {
                _set6Location(_vertex, _account, _grade, 0);
            } else {
                _set6Location(_vertex, _account, _grade, 1);
            }
        } else {
            for (uint256 i = 0; i < 4; i++) {
                if (accountInfoList[_vertex].matrix6Grade[_grade].lowerLayer[i] == address(0)) {
                    if (i == 0 || i == 1) {
                        address upper = accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[0];
                        if (i == 0) {
                            if (accountInfoList[upper].matrix6Grade[_grade].upperLayer[0] == address(0)) {
                                _set6Location(upper, _account, _grade, 0);
                            }
                        }
                        if (i == 1) {
                            if (accountInfoList[upper].matrix6Grade[_grade].upperLayer[1] == address(0)) {
                                _set6Location(upper, _account, _grade, 1);
                            }
                        }
                    } else {
                        address upper = accountInfoList[_vertex].matrix6Grade[_grade].upperLayer[1];
                        if (i == 2) {
                            if (accountInfoList[upper].matrix6Grade[_grade].upperLayer[0] == address(0)) {
                                _set6Location(upper, _account, _grade, 0);
                            }
                        }
                        if (i == 3) {
                            if (accountInfoList[upper].matrix6Grade[_grade].upperLayer[1] == address(0)) {
                                _set6Location(upper, _account, _grade, 1);
                            }
                        }
                    }
                    return;
                }
            }
        }
    }

    function _addLocationsTo3(address _account, address _vertex, uint256 _grade) internal {
        if (!accountInfoList[_vertex].gradeExist[_grade]) {
            USDToken.transfer(noReferPlatform, currentPrice(_grade));
        } else {
            for (uint256 i = 0; i < 3; i++) {
                if (accountInfoList[_vertex].matrix3Grade[_grade].upperLayer[i] == address(0)) {
                    _set3Location(_vertex, _account, _grade, i);
                    return;
                }
            }
        }
    }

    function _set6Location(address _setKey, address _setValue, uint256 _setGrade, uint256 _setLocation) internal {
        if (_setLocation == 0) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[0] = _setValue;
            if (accountInfoList[_setKey].matrix6Grade[_setGrade].upper != address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = accountInfoList[_setKey].matrix6Grade[_setGrade].upper;
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = _setKey;
            } else {
                accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = _setKey;
            }
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper != address(0)) {
                if (
                    accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].upperLayer[1] == _setKey
                ) {
                    if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].lowerLayer[2] == address(0)) {
                        _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].vertex, _setValue, _setGrade, 4);
                    }
                } else if (
                    accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].upperLayer[0] == _setKey
                ) {
                    if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].lowerLayer[0] == address(0)) {
                        _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].vertex, _setValue, _setGrade, 2);
                    }
                }
            }
            if (
                accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].vertex == address(0)
            ) {
                USDToken.transfer(noReferPlatform, currentPrice(_setGrade));
            }
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 1);
            return;
        }
        if (_setLocation == 1) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[1] = _setValue;
            if (accountInfoList[_setKey].matrix6Grade[_setGrade].upper != address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = accountInfoList[_setKey].matrix6Grade[_setGrade].upper;
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = _setKey;
            } else {
                accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = _setKey;
            }
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper != address(0)) {
                if (
                    accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].upperLayer[1] == _setKey
                ) {
                    if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].lowerLayer[3] == address(0)) {
                        _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].vertex, _setValue, _setGrade, 5);
                    }
                } else if (
                    accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].upperLayer[0] == _setKey
                ) {
                    if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].vertex].matrix6Grade[_setGrade].lowerLayer[1] == address(0)) {
                        _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].vertex, _setValue, _setGrade, 3);
                    }
                }
            }
            if (
                accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].vertex == address(0)
            ) {
                USDToken.transfer(noReferPlatform, currentPrice(_setGrade));
            }
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 2);
            return;
        }
        if (_setLocation == 2) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].lowerLayer[0] = _setValue;
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper == address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[0];
            }
            if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].upperLayer[0] == address(0)) {
                _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].upper, _setValue, _setGrade, 0);
            }
            accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 3);
            USDToken.transfer(_setKey, currentPrice(_setGrade));
            return;
        }
        if (_setLocation == 3) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].lowerLayer[1] = _setValue;
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper == address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[0];
            }
            if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].upperLayer[1] == address(0)) {
                _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].upper, _setValue, _setGrade, 1);
            }
            accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 4);
            _should6AutoNewGrant(_setKey, _setGrade);
            _should6AutoReVote(_setKey, _setGrade);
            return;
        }
        if (_setLocation == 4) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].lowerLayer[2] = _setValue;
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper == address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[1];
            }
            if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].upperLayer[0] == address(0)) {
                _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].upper, _setValue, _setGrade, 0);
            }
            accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 5);
            _should6AutoNewGrant(_setKey, _setGrade);
            return;
        }
        if (_setLocation == 5) {
            accountInfoList[_setKey].matrix6Grade[_setGrade].lowerLayer[3] = _setValue;
            if (accountInfoList[_setValue].matrix6Grade[_setGrade].upper == address(0)) {
                accountInfoList[_setValue].matrix6Grade[_setGrade].upper = accountInfoList[_setKey].matrix6Grade[_setGrade].upperLayer[1];
            }
            if (accountInfoList[accountInfoList[_setValue].matrix6Grade[_setGrade].upper].matrix6Grade[_setGrade].upperLayer[1] == address(0)) {
                _set6Location(accountInfoList[_setValue].matrix6Grade[_setGrade].upper, _setValue, _setGrade, 1);
            }
            accountInfoList[_setValue].matrix6Grade[_setGrade].vertex = _setKey;
            emit NewLocationEvent(_setValue, _setKey, _setGrade, 6);
            _should6AutoReVote(_setKey, _setGrade);
            return;
        }
    }

    function _set3Location(address _setKey, address _setValue, uint256 _setGrade, uint256 _setLocation) internal {
        accountInfoList[_setKey].matrix3Grade[_setGrade].upperLayer[_setLocation] = _setValue;
        emit NewLocationEvent(_setValue, _setKey, _setGrade, _setLocation.add(1));
        if (_setLocation == 0) {
            _should3AutoNewGrant(_setKey, _setGrade);
        }
        if (_setLocation == 1) {
            _should3AutoNewGrant(_setKey, _setGrade);
        }
        if (_setLocation == 2) {
            _should3AutoReVote(_setKey, _setGrade);
        }
    }

    function _should6AutoNewGrant(address _account, uint256 _grade) internal {
        if (perAutoTimes >= maxAuto) {
            require(false, "server timeout, please wait for some time, and try again");
        }
        
        if (accountInfoList[_account].currentMaxGrade >= _grade.add(1)) {
            uint256 price = currentPrice(_grade);
            if (accountInfoList[_account].matrix6Grade[_grade].isReVote) {
                USDToken.transfer(_account, price);
                return;
            }

            if ((
                    accountInfoList[_account].matrix6Grade[_grade].lowerLayer[1] != address(0) &&
                    accountInfoList[_account].matrix6Grade[_grade].lowerLayer[2] == address(0) &&
                    accountInfoList[_account].matrix6Grade[_grade].amount == 0
                ) ||
                (
                    accountInfoList[_account].matrix6Grade[_grade].lowerLayer[1] == address(0) &&
                    accountInfoList[_account].matrix6Grade[_grade].lowerLayer[2] != address(0) &&
                    accountInfoList[_account].matrix6Grade[_grade].amount == 0
                ) ||
                (
                    accountInfoList[_account].matrix6Grade[_grade].lowerLayer[1] != address(0) &&
                    accountInfoList[_account].matrix6Grade[_grade].lowerLayer[2] != address(0) &&
                    accountInfoList[_account].matrix6Grade[_grade].amount == 0
                )) {
                USDToken.transfer(_account, price);
                return;
            }

            if (
                accountInfoList[_account].matrix6Grade[_grade].lowerLayer[1] != address(0) &&
                accountInfoList[_account].matrix6Grade[_grade].lowerLayer[2] != address(0) &&
                accountInfoList[_account].matrix6Grade[_grade].amount != 0
            ) {
                if (accountInfoList[_account].matrix6Grade[_grade].amount != 1) {
                    price = price.add(accountInfoList[_account].matrix6Grade[_grade].amount);
                    accountInfoList[_account].matrix6Grade[_grade].amount = 1;
                    USDToken.transfer(_account, price);
                    return;
                }
                uint256 platformRate = price.mul(basePlatformRate).div(rate);
                USDToken.transfer(feePlatform, platformRate);
                USDToken.transfer(_account, price.sub(platformRate));
                return;
            }
        }

        if (
            accountInfoList[_account].currentMaxGrade >= _grade.add(1) &&
            accountInfoList[_account].isPauseAutoNewGrant[_grade]
            ) {
            uint256 price = currentPrice(_grade);
            if (accountInfoList[_account].matrix6Grade[_grade].isReVote) {
                USDToken.transfer(_account, price);
            } else {
                if (accountInfoList[_account].matrix6Grade[_grade].amount != 1) {
                    price = price.add(accountInfoList[_account].matrix6Grade[_grade].amount);
                    accountInfoList[_account].matrix6Grade[_grade].amount = 1;
                }
                uint256 platformRate = price.mul(basePlatformRate).div(rate);
                USDToken.transfer(feePlatform, platformRate);
                USDToken.transfer(_account, price.sub(platformRate));
            }
            return;
        }
        if (accountInfoList[_account].currentMaxGrade >= _grade.add(1)) {
            uint256 price = currentPrice(_grade);
            if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                if (accountInfoList[_account].matrix6Grade[_grade].amount == 0) {
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));
                } else {
                    if (accountInfoList[_account].matrix6Grade[_grade].amount != 1) {
                        price = price.add(accountInfoList[_account].matrix6Grade[_grade].amount);
                        accountInfoList[_account].matrix6Grade[_grade].amount = 1;
                    }
                    USDToken.transfer(_account, price);
                }
            } else {
                if (accountInfoList[_account].matrix6Grade[_grade].isReVote) {
                    USDToken.transfer(_account, price);
                } else {
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));   
                }
            }
            return;
        } else {
            if (
                accountInfoList[_account].matrix6Grade[_grade].lowerLayer[1] != address(0) &&
                accountInfoList[_account].matrix6Grade[_grade].lowerLayer[2] != address(0)
            ) {
                if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                    Token.mint(_account, currentPrice(_grade.add(1)).mul(baseRewardRate).div(rate));
                    perAutoTimes++;
                    address vertex = accountInfoList[_account].referRecommender;
                    if (!accountInfoList[vertex].gradeExist[_grade.add(1)]) {
                        vertex = address(0);
                    }
                    _addLocations(_account, vertex, _grade.add(1));
                } else {
                    uint256 price = currentPrice(_grade);
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));
                }
            } else {
                if (accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                    uint256 price = currentPrice(_grade);
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));
                } else {
                    accountInfoList[_account].matrix6Grade[_grade].amount = currentPrice(_grade);
                }
            }
        }
    }

    function _should6AutoReVote(address _account, uint256 _grade) internal {
        if (perAutoTimes >= maxAuto) {
            require(false, "server timeout, please wait for some time, and try again");
        }
        if (
            accountInfoList[_account].matrix6Grade[_grade].lowerLayer[0] != address(0) &&
            accountInfoList[_account].matrix6Grade[_grade].lowerLayer[1] != address(0) &&
            accountInfoList[_account].matrix6Grade[_grade].lowerLayer[2] != address(0) &&
            accountInfoList[_account].matrix6Grade[_grade].lowerLayer[3] != address(0)
        ) {
            accountInfoList[_account].matrix6Grade[_grade].isReVote = true;
            if (!accountInfoList[_account].isPauseAutoReVote[_grade]) {
                Token.mint(_account, currentPrice(_grade).mul(baseRewardRate).div(rate));
                perAutoTimes++;
                address recommender = accountInfoList[_account].referRecommender;
                if (accountInfoList[recommender].gradeExist[_grade]) {
                    _addLocations(_account, recommender, _grade);
                } else {
                    _addLocations(_account, address(0), _grade);
                }
                resetAccount6Matrix(_account, _grade);            
            } else {
                uint256 price = currentPrice(_grade);
                uint256 platformRate = price.mul(basePlatformRate).div(rate);
                USDToken.transfer(feePlatform, platformRate);
                USDToken.transfer(_account, price.sub(platformRate));
                accountInfoList[_account].gradeExist[_grade] = false;
                resetAccount6Matrix(_account, _grade);
            }
        }
    }

    function _should3AutoNewGrant(address _account, uint256 _grade) internal {
        if (perAutoTimes >= maxAuto) {
            require(false, "server timeout, please wait for some time, and try again");
        }
        if (_grade == maxGrade) {
            uint256 price = currentPrice(maxGrade);
            if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                USDToken.transfer(_account, price);
            } else {
                uint256 platformRate = price.mul(basePlatformRate).div(rate);
                USDToken.transfer(feePlatform, platformRate);
                USDToken.transfer(_account, price.sub(platformRate));
            }
            return;
        }

        if (accountInfoList[_account].currentMaxGrade >= _grade.add(1)) {
            uint256 price = currentPrice(_grade);
            if (accountInfoList[_account].matrix3Grade[_grade].isReVote) {
                USDToken.transfer(_account, price);
                return;
            }

            if ((
                    accountInfoList[_account].matrix3Grade[_grade].upperLayer[0] != address(0) &&
                    accountInfoList[_account].matrix3Grade[_grade].upperLayer[1] == address(0) &&
                    accountInfoList[_account].matrix3Grade[_grade].amount == 0
                ) ||
                (
                    accountInfoList[_account].matrix3Grade[_grade].upperLayer[0] == address(0) &&
                    accountInfoList[_account].matrix3Grade[_grade].upperLayer[1] != address(0) &&
                    accountInfoList[_account].matrix3Grade[_grade].amount == 0
                ) ||
                (
                    accountInfoList[_account].matrix3Grade[_grade].upperLayer[0] != address(0) &&
                    accountInfoList[_account].matrix3Grade[_grade].upperLayer[1] != address(0) &&
                    accountInfoList[_account].matrix3Grade[_grade].amount == 0
                )) {
                USDToken.transfer(_account, price);
                return;
            }

            if (
                accountInfoList[_account].matrix3Grade[_grade].upperLayer[0] != address(0) &&
                accountInfoList[_account].matrix3Grade[_grade].upperLayer[1] != address(0) &&
                accountInfoList[_account].matrix3Grade[_grade].amount != 0
            ) {
                if (accountInfoList[_account].matrix3Grade[_grade].amount != 1) {
                    price = price.add(accountInfoList[_account].matrix3Grade[_grade].amount);
                    accountInfoList[_account].matrix3Grade[_grade].amount = 1;
                    USDToken.transfer(_account, price);
                    return;
                }
                uint256 platformRate = price.mul(basePlatformRate).div(rate);
                USDToken.transfer(feePlatform, platformRate);
                USDToken.transfer(_account, price.sub(platformRate));
                return;
            }
        }

        if (
            accountInfoList[_account].currentMaxGrade >= _grade.add(1) &&
            accountInfoList[_account].isPauseAutoNewGrant[_grade]
            ) {
                uint256 price = currentPrice(_grade);
                if (accountInfoList[_account].matrix3Grade[_grade].isReVote) {
                    USDToken.transfer(_account, price);
                } else {
                    if (accountInfoList[_account].matrix3Grade[_grade].amount != 1) {
                        price = price.add(accountInfoList[_account].matrix3Grade[_grade].amount);
                        accountInfoList[_account].matrix3Grade[_grade].amount = 1;
                    }
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));
                }
                return;
        }

        if (accountInfoList[_account].currentMaxGrade >= _grade.add(1)) {
            uint256 price = currentPrice(_grade);
            if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                if (accountInfoList[_account].matrix3Grade[_grade].amount == 0) {
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));
                } else {
                    if (accountInfoList[_account].matrix3Grade[_grade].amount != 1) {
                        price = price.add(accountInfoList[_account].matrix3Grade[_grade].amount);
                        accountInfoList[_account].matrix3Grade[_grade].amount = 1;
                    }
                    USDToken.transfer(_account, price);
                }
            } else {        
                if (accountInfoList[_account].matrix3Grade[_grade].isReVote) {
                    USDToken.transfer(_account, price);
                } else {
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));  
                }
            }
            return;
        } else {
            if (
                accountInfoList[_account].matrix3Grade[_grade].upperLayer[0] != address(0) &&
                accountInfoList[_account].matrix3Grade[_grade].upperLayer[1] != address(0)
            ) {
                if (!accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                    Token.mint(_account, currentPrice(_grade.add(1)).mul(baseRewardRate).div(rate));
                    perAutoTimes++;
                    address vertex = address(0);
                    if (accountInfoList[accountInfoList[_account].referRecommender].gradeExist[_grade.add(1)]) {
                        vertex = accountInfoList[_account].referRecommender;
                    }
                    _addLocations(_account, vertex, _grade.add(1));
                } else {
                    uint256 price = currentPrice(_grade);
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));
                }
            } else {
                if (accountInfoList[_account].isPauseAutoNewGrant[_grade]) {
                    uint256 price = currentPrice(_grade);
                    uint256 platformRate = price.mul(basePlatformRate).div(rate);
                    USDToken.transfer(feePlatform, platformRate);
                    USDToken.transfer(_account, price.sub(platformRate));
                } else {
                    accountInfoList[_account].matrix3Grade[_grade].amount = currentPrice(_grade);
                }
            }
        }
    }

    function _should3AutoReVote(address _account, uint256 _grade) internal {
        if (perAutoTimes >= maxAuto) {
            require(false, "server timeout, please wait for some time, and try again");
        }
        if (
            accountInfoList[_account].matrix3Grade[_grade].upperLayer[0] != address(0) &&
            accountInfoList[_account].matrix3Grade[_grade].upperLayer[1] != address(0) &&
            accountInfoList[_account].matrix3Grade[_grade].upperLayer[2] != address(0)
        ) {
            accountInfoList[_account].matrix3Grade[_grade].isReVote = true;
            if (!accountInfoList[_account].isPauseAutoReVote[_grade]) {
                Token.mint(_account, currentPrice(_grade).mul(baseRewardRate).div(rate));
                perAutoTimes++;
                address recommender = accountInfoList[_account].referRecommender;
                if (accountInfoList[recommender].gradeExist[_grade]) {
                    _addLocations(_account, recommender, _grade);
                } else {
                    _addLocations(_account, address(0), _grade);
                }
                resetAccount3Matrix(_account, _grade);               
            } else {
                uint256 price = currentPrice(_grade);
                uint256 platformRate = price.mul(basePlatformRate).div(rate);
                USDToken.transfer(feePlatform, platformRate);
                USDToken.transfer(_account, price.sub(platformRate));
                accountInfoList[_account].gradeExist[_grade] = false;
                resetAccount3Matrix(_account, _grade);
            }
        }
    }

    function resetAccount6Matrix(address _account, uint256 _grade) internal {
        accountInfoList[_account].matrix6Grade[_grade].upperLayer[0] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].upperLayer[1] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].lowerLayer[0] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].lowerLayer[1] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].lowerLayer[2] = address(0);
        accountInfoList[_account].matrix6Grade[_grade].lowerLayer[3] = address(0);
    }

    function resetAccount3Matrix(address _account, uint256 _grade) internal {
        accountInfoList[_account].matrix3Grade[_grade].upperLayer[0] = address(0);
        accountInfoList[_account].matrix3Grade[_grade].upperLayer[1] = address(0);
        accountInfoList[_account].matrix3Grade[_grade].upperLayer[2] = address(0);
    }

    function matrixMember(uint256 _grade) internal pure returns (uint256) {
        require(_grade > 0 && _grade <= maxGrade, "error grade");
        if (_grade == 3 || _grade == 6 || _grade == 9 || _grade == maxGrade) {return 3;}
        return 6;
    }

    function currentPrice(uint256 _grade) public view returns (uint256) {
        return baseLocationPrice.mul(2 ** _grade.sub(1));
    }

    function accountGrade(address account, uint256 grade) public view returns (address[6] memory array) {
        require(account != address(0) && grade > 0 && grade <= maxGrade, "param error");
        uint256 member = matrixMember(grade);
        if (member == 3) {
            array[0] = accountInfoList[account].matrix3Grade[grade].upperLayer[0];
            array[1] = accountInfoList[account].matrix3Grade[grade].upperLayer[1];
            array[2] = accountInfoList[account].matrix3Grade[grade].upperLayer[2];
        }
        if (member == 6) {
            array[0] = accountInfoList[account].matrix6Grade[grade].upperLayer[0];
            array[1] = accountInfoList[account].matrix6Grade[grade].upperLayer[1];
            array[2] = accountInfoList[account].matrix6Grade[grade].lowerLayer[0];
            array[3] = accountInfoList[account].matrix6Grade[grade].lowerLayer[1];
            array[4] = accountInfoList[account].matrix6Grade[grade].lowerLayer[2];
            array[5] = accountInfoList[account].matrix6Grade[grade].lowerLayer[3];
        }
        return array;
    }

    function accInfo(address account, uint256 grade) public view returns (bool isPauseAutoNewGrant, bool isPauseAutoReVote) {
        return (accountInfoList[account].isPauseAutoNewGrant[grade], accountInfoList[account].isPauseAutoReVote[grade]);
    }

    function referRecommender(address account) public view returns (address) {
        return accountInfoList[account].referRecommender;
    }

    function latestGrade(address account) public view returns (uint256) {
        return accountInfoList[account].currentMaxGrade;
    }

    function accmatrixAmount(address account, uint256 grade) public view returns (uint256) {
        uint256 member = matrixMember(grade);
        if (member == 3) {
            return accountInfoList[account].matrix3Grade[grade].amount;
        } else {
            return accountInfoList[account].matrix6Grade[grade].amount;
        }   
    }

    function accmatrixReVote(address _account, uint256 _grade) public view returns (bool) {
        uint256 member = matrixMember(_grade);
        if (member == 3) {
            return accountInfoList[_account].matrix3Grade[_grade].isReVote;
        } else {
            return accountInfoList[_account].matrix6Grade[_grade].isReVote;
        }
    }

    function withdrawal(uint256 _grade) public {
        uint256 member = matrixMember(_grade);
        uint256 amount = 0;
        if (member == 3) {
            amount = accountInfoList[_msgSender()].matrix3Grade[_grade].amount;
            accountInfoList[_msgSender()].matrix3Grade[_grade].amount = 1;
        } else {
            amount = accountInfoList[_msgSender()].matrix6Grade[_grade].amount;
            accountInfoList[_msgSender()].matrix6Grade[_grade].amount = 1;
        }
        uint256 platformRate = amount.mul(basePlatformRate).div(rate);
        USDToken.transfer(feePlatform, platformRate);
        USDToken.transfer(_msgSender(), amount.sub(platformRate));
        accountInfoList[_msgSender()].isPauseAutoNewGrant[_grade] = true;
    }
}