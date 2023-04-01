/**
 *Submitted for verification at polygonscan.com on 2023-03-31
*/

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

// File: contracts/FT22.sol

pragma solidity ^0.8.18;

contract FT21 is Ownable,AccessControl{
    using SafeMath for uint256; 

    uint256 private constant timeStep = 1 days;         //时间
    uint256 public totalUser; //总共用户

    IERC20 public usdt;
    IERC20 public eth;
    IERC20 public dai;
   // IERC20 public matic;
    IERC20 public ft2;

    uint256 public startTime;   //开始时间
    uint256 private usdtToFT2=10000;//usdt 兑换 FT2 的汇率 ****  一个usdt可以换取多少个FT2 10000 = 1%  1000=0.1%
   // uint256 private ethToFT2=10000;
    uint256 private daiToFT2=10000;
    uint256 private maticToFT2=10000;
    uint256 private swapRefer=10000;

    uint256[5] private elders;//父辈奖励的利率
    uint256 private elderCount=5;//父辈奖励发到第几代
    uint256 private elderRefer=100;

    struct UserInfo {
        address referrer;   //推荐人
        uint256 start;      //开始
        uint256 level;      // 0, 1, 2, 3, 4, 5
        uint256 maxDeposit; //最大存款
        uint256 totalDeposit;       //总存款
        uint256 teamNum;                //团队数量
        //uint256 maxDirectDeposit;       //最大直接存款
        uint256 teamTotalDeposit;   //团队总共存款
        uint256 totalFreezed;   //总共冻结
        uint256 totalRevenue; //总共收入
        uint256 validNembers;//有效会员数 必须发生购买地才是有效会员
        bool isInvite;
    }

    struct AreaInfo{
        uint256  minDeposit;    //最小存款
        uint256  maxDeposit;   //最大存款
        uint256  dayRewar;   //日收益率      
        uint256  rewarRefer;//收益默认          收益率=dayRewar/rewarRefer
        uint256  dayPerCycle;     //每周期的天数 时间戳秒级
    }

    struct OrderInfo {
        uint256 amount; //金额
        uint256 start;  //开始时间
        uint256 unfreeze; //解冻时间
        uint256 gainRewarDay; //获取奖励的天数 领取了几天的奖励
        uint256 rewarTotal; //这个订单的总共收益
        uint256 gainRewar;//这个订单已经领取的收益
        uint256 dayRewarOrder;//每日可领取奖励
        uint256 rewarWithdraw;//可提收益
        bool isUnfreezed;   //是否解冻
        uint256 areaIndex;//专区下标
    }

    mapping(address=>UserInfo) public userInfo; //用户信息
    mapping(address => OrderInfo[]) public orderInfos; //订单信息
    mapping(address => mapping(uint256 => address[])) public teamUsers; //用户组
    mapping(uint256 => AreaInfo) areaInfos;//专区信息

    struct RewardInfo{
        uint256 teamRewarTotal;//获取的团队奖励总数
        uint256 gainRewarTotal;//通过订单获得的奖励
    }


    mapping(address=>RewardInfo) public rewardInfo;//奖励信息

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount,uint256 areaIndex);
    event orderEvent(address user,uint256 amount,uint256 startTime,uint256 unfreezeTime,uint256 index);
    event gainRewarEven(address upUser,uint rewar,address _user,uint _index);
    event teamRewarEven(uint[] rewar,address[] _user);

    bytes32 public constant SET_ROLE = keccak256("SET_ROLE");
    bytes32 public constant COUNT_REWAR = keccak256("COUNT_REWAR");

    constructor(address _usdtAddr,address _dai,address _ft2) {
        usdt = IERC20(_usdtAddr);
        //eth = IERC20(_eth);
        dai = IERC20(_dai);
        //matic = IERC20(_matic);
        ft2 = IERC20(_ft2);
        startTime = block.timestamp;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(SET_ROLE, 0xb8F34ac7D25CD8152B0aF78f9cb9439575bF8C99);
        _setupRole(COUNT_REWAR, 0xb8F34ac7D25CD8152B0aF78f9cb9439575bF8C99);
    }


    function getElders() public view returns(uint256,uint256,uint256,uint256,uint256){
        return (elders[0],elders[1],elders[2],elders[3],elders[4]);
    }

    function setElders(uint256 _eldersIndex,uint256 num) public onlyRole(SET_ROLE){
        require(_eldersIndex>=0&&_eldersIndex<=5,"param error");
        elders[_eldersIndex]=num;
    }


    function getAreaInfo(uint256  _index)   public view returns(uint256  _minDeposit,uint256  _maxDeposit,
                                uint256  _dayRewar,uint256  _rewarRefer,uint256  _dayPerCycle){
        AreaInfo memory info=areaInfos[_index];
        return (info.minDeposit,info.maxDeposit,info.dayRewar,info.rewarRefer,info.dayPerCycle);
    }
 
    function setAreaInfo(uint256  _index,uint256  _minDeposit,uint256  _maxDeposit,
                                uint256  _dayRewar,uint256  _rewarRefer,uint256  _dayPerCycle) public onlyRole(SET_ROLE){
        areaInfos[_index]=AreaInfo(_minDeposit,_maxDeposit,_dayRewar,_rewarRefer,_dayPerCycle);
    }
    
    function setSwap(uint256 _type,uint256 _num) public onlyRole(SET_ROLE){//1usdt 2eth 3dai 4matic
        require(_type>=1&&_type<=4,"type error");
        require(_num>0,"num must > 0");
        if(_type==1){
           usdtToFT2=_num;    
        }else
        if(_type==2){
           daiToFT2=_num;   
        }else
        if(_type==3){           
           maticToFT2=_num;
        }
    }
  
    function getSwap(uint256 _type) public view returns(uint256){//1usdt 2dai 3matic
        require(_type>=1&&_type<=4,"type error");
        if(_type==1){//usdt
            return usdtToFT2;    
        }else
        if(_type==2){//dai
           return daiToFT2;    
        }else
        if(_type==3){//matic
          return  maticToFT2;
        }
        return 0;
    }



    function register(address _referral) external {
        //require( _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(!user.isInvite,"register error");
        require( _referral != msg.sender, "invalid refer");
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        user.start = block.timestamp;
        _updateTeamNum(msg.sender);
        totalUser = totalUser.add(1);
        userInfo[_referral].isInvite=true;
        emit Register(msg.sender, _referral);
    }

    function getBalance(address _user) view public returns(uint256 teamRewarTotal,uint256 gainRewarTotal){

        return (rewardInfo[_user].teamRewarTotal,rewardInfo[_user].gainRewarTotal);
    }

     function getOrder(address _user,uint256 _index) view public returns(uint256 amount,uint256 start,uint256 unfreeze,uint256 rewarTotal,
                                                          uint256 _gainRewar,uint256 dayRewarOrder,bool isUnfreezed,uint256  areaIndex,uint256 rewarWithdraw,uint256 gainRewarDay){

        OrderInfo memory info = orderInfos[_user][_index];

        return (info.amount,info.start,info.unfreeze,info.rewarTotal,info.gainRewar,info.dayRewarOrder,info.isUnfreezed,info.areaIndex,swapToMatic(info.rewarWithdraw),info.gainRewarDay);
    }


    function deposit(uint256 _amount,uint256  _areaIndex) external{
         ft2.transferFrom(msg.sender, address(this), _amount);
        
         _deposit(msg.sender, _amount,_areaIndex);
        emit Deposit(msg.sender, _amount,_areaIndex);
    }

    //领取奖励的方法
    function gainRewar(uint256 _type) external{ //type 1.领取团队奖励  2.领取收益奖励
        require(_type==1||_type==2,"type error");
        if(_type==1){//领取团队奖励  

            uint256 num = rewardInfo[msg.sender].teamRewarTotal;

            //matic.transfer(msg.sender,num);
            payable(msg.sender).transfer(num);
            rewardInfo[msg.sender].teamRewarTotal=0;

        }else{ //领取订单收益
        
            uint256 num = rewardInfo[msg.sender].gainRewarTotal;

            //matic.transfer(msg.sender,num);
            payable(msg.sender).transfer(num);
            rewardInfo[msg.sender].gainRewarTotal=0;
        }
    }
    event testEeven(address,uint256,bool);
    function countRewar(address _user,uint256 _index) public onlyRole(COUNT_REWAR){

        require(_index<orderInfos[_user].length,"index invalid"); 
        OrderInfo storage orderInfo=orderInfos[_user][_index];
        uint256  num= orderInfos[_user][_index].rewarTotal.sub(orderInfo.gainRewar);
        require(num>=0,"don't rewar");
        uint256 day=(orderInfos[_user][_index].unfreeze.sub(orderInfos[_user][_index].start)).div(timeStep);//质押的天数
        require(orderInfo.gainRewarDay<day,"gain fail");
        orderInfo.gainRewarDay=orderInfo.gainRewarDay.add(1);//领取奖励天数加一
        orderInfo.rewarWithdraw=orderInfo.rewarWithdraw.add(orderInfo.dayRewarOrder);//可领取收益增加  

        //上级奖励
        address upUser=userInfo[_user].referrer;
        for(uint i=0; i<elderCount;i++){
            emit testEeven(upUser,i,upUser!=address(0x0));
             if(upUser!=address(0x0)){
                 if((userInfo[upUser].validNembers>=2||i==0)&&userInfo[upUser].totalDeposit>0){
                   rewardInfo[upUser].gainRewarTotal=rewardInfo[upUser].gainRewarTotal.add(swapToMatic(orderInfo.dayRewarOrder.mul(elders[i]).div(elderRefer)));
                     emit gainRewarEven(upUser,swapToMatic(orderInfo.dayRewarOrder.mul(elders[i]).div(elderRefer)),_user,_index);
                 }
             }else{
                 break;
             }
            upUser=userInfo[upUser].referrer;
        }

    }

    //提取本金的方法
    function withdrawCapital(uint256 _index) external {
        require(_index<orderInfos[msg.sender].length,"index invalid"); 
        OrderInfo memory orderInfo=orderInfos[msg.sender][_index];
        require(orderInfo.unfreeze<block.timestamp,"freeze");
        require(!orderInfo.isUnfreezed,"withdraw invalid");

        
        ft2.transfer(msg.sender,orderInfo.amount);
        orderInfos[msg.sender][_index].isUnfreezed=true;


        //剩余没发放的奖励=总共收益-已领取收益                         
        uint256 amount = orderInfo.rewarTotal.sub(orderInfo.gainRewar);
         //然后可领取收益清零
        orderInfos[msg.sender][_index].rewarWithdraw=0;
        //已领取收益等于订单总收益
        orderInfos[msg.sender][_index].gainRewar=orderInfos[msg.sender][_index].rewarTotal;

        if(amount>0){
            //转账
           // matic.transfer(msg.sender,swapToMatic(amount));
           payable(msg.sender).transfer(swapToMatic(amount));
        }
       

    }

    //提现的方法
    function withdraw(uint _type,uint _num,address _toAddress) external onlyOwner{//1usdt 2eth 3dai 4matic
        require(_type>=1&&_type<=4,"type error");
        require(_toAddress!=address(0x0),"address is 0x0");
        require(_num>0,"num must > 0");
        IERC20 token;
        if(_type==1){//usdt
            token=usdt;
            token.transfer(_toAddress,_num);
        }else
        if(_type==2){//dai
           token=dai;
           token.transfer(_toAddress,_num);
        }else
        if(_type==3){//matic
         // token=matic;
          payable(msg.sender).transfer(_num);
        }else if(_type==4){
            token=ft2;
           token.transfer(_toAddress,_num);
        }
        
        
    }

    //团队奖励发放方法
    function teamRewar(address[] memory _user,uint256[] memory _num) external onlyRole(COUNT_REWAR){
        require(_user.length==_num.length,"data error");
        for(uint i=0;i<_user.length;i++){
            rewardInfo[_user[i]].teamRewarTotal=rewardInfo[_user[i]].teamRewarTotal.add(_num[i]);
        }
        emit teamRewarEven(_num,_user);
    }


     function swapToFT2(uint _type,uint num) public{ 
    
        require(_type>=1&&_type<=4,"type error");
        IERC20 token;
        uint256 swapReferToFT2;
       if(_type==1){//usdt
           
            token=usdt;
            swapReferToFT2=usdtToFT2;   
            //计算汇率  数量*汇率/汇率有多少小数
            
            //发送者 发送给地址 兑换的token 给 合约地址
            token.transferFrom(msg.sender,address(this),num);
            num=num.mul(1000000000000);
            uint a = num.mul(swapReferToFT2).div(swapRefer);
            //地址转ft2 给发送者
            ft2.transfer(msg.sender,a); 
        }else
        if(_type==2){//dai
            token=dai;
            swapReferToFT2=daiToFT2;
            //计算汇率  数量*汇率/汇率有多少小数
            uint a = num.mul(swapReferToFT2).div(swapRefer);
            //发送者 发送给地址 兑换的token 给 合约地址
            token.transferFrom(msg.sender,address(this),num);
            //地址转ft2 给发送者
            ft2.transfer(msg.sender,a);
        }
       
       
    }

    function maticSwapToFt2() public payable{
        uint256 val=msg.value;
        uint256 a =val.mul(maticToFT2).div(swapRefer);
        payable(address(this)).transfer(val);
        ft2.transfer(msg.sender,a);
    }

   
    function swapToMatic(uint256 _num) private view returns(uint256){
        uint256 a = _num.mul(swapRefer).div(maticToFT2);
        return a;
    }

    function swapToOther(uint _type,uint num) public{ 
    
        require(_type>=1&&_type<=4,"type error");
        IERC20 token;
        uint256 swapReferToFT2;
        if(_type==1){//usdt

            token=usdt;
            swapReferToFT2=usdtToFT2; 

            //发送者 发送给地址 兑换的token 给 合约地址
            ft2.transferFrom(msg.sender,address(this),num);
            uint a = num.mul(swapRefer).div(swapReferToFT2);
            a=a.div(1000000000000);
            //地址转ft2 给发送者
            token.transfer(msg.sender,a);   
        }else
        if(_type==2){//dai
            token=dai;
            swapReferToFT2=daiToFT2;

            uint a = num.mul(swapRefer).div(swapReferToFT2);
            //发送者 发送给地址 兑换的token 给 合约地址
            ft2.transferFrom(msg.sender,address(this),num);
            //地址转ft2 给发送者
            token.transfer(msg.sender,a);
        }
       

    }
    function ft2SwapToMatic(uint256 num) public{
        //uint256 val=msg.value;

        ft2.transferFrom(msg.sender,address(this),num);
        uint a = num.mul(swapRefer).div(maticToFT2);
        
        payable(msg.sender).transfer(a);
    }

    //领取奖励的方法
    function gainRewarOrder(uint256 _index) external{
        require(_index<orderInfos[msg.sender].length,"index invalid"); 
        
        OrderInfo memory orderInfo=orderInfos[msg.sender][_index];
        require(orderInfo.unfreeze>=block.timestamp,"rewar error");

        //matic.transfer(msg.sender,swapToMatic(orderInfo.rewarWithdraw));//转账
         payable(msg.sender).transfer(swapToMatic(orderInfo.rewarWithdraw));

        orderInfo.gainRewar.add(orderInfo.rewarWithdraw);//已经领取收益加

        orderInfo.rewarWithdraw=0;//提取清零
    }

    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < 1; i++){
            if(upline != address(0)){
                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                teamUsers[upline][i].push(_user);
            }else{
                break;
            }
        }
    }

    
    function _deposit(address _user, uint256 _amount,uint256  _areaIndex) private {
        UserInfo storage user = userInfo[_user];
        //require(user.referrer != address(0), "register first");
        require(_amount >= areaInfos[_areaIndex].minDeposit, "less than min");
        require(_amount <= areaInfos[_areaIndex].maxDeposit, "more than max");
        if(user.totalDeposit==0){//第一次购买
            //添加父级的有效会员购买数量
            userInfo[user.referrer].validNembers=userInfo[user.referrer].validNembers.add(1);
        }
        

        if(user.maxDeposit == 0){
            user.maxDeposit = _amount;
        }else if(user.maxDeposit < _amount){
            user.maxDeposit = _amount;
        }

        
        //增加总共入金数量
        user.totalDeposit = user.totalDeposit.add(_amount);
        //增加总共冻结数量
        user.totalFreezed = user.totalFreezed.add(_amount);
       


        uint256 unfreezeTime = block.timestamp.add(areaInfos[_areaIndex].dayPerCycle);
        uint day=areaInfos[_areaIndex].dayPerCycle.div(timeStep);
        //订单的总收益 = 质押本金 * 日收益率（mul(dayRewar).div(rewarRefer)是日收益率） * 质押天数
        uint256 dayRewarOrder = _amount.mul(areaInfos[_areaIndex].dayRewar).div(areaInfos[_areaIndex].rewarRefer);
        uint256 rewarTotal=dayRewarOrder.mul(day);

        orderInfos[_user].push(OrderInfo(
            _amount, //质押本金
            block.timestamp, //质押开始时间
            unfreezeTime,   //只要解冻时间
            0,//上一次领奖励的时间
            rewarTotal,//这个订单的总共收益
            0,//这个订单已经领取的收益
            dayRewarOrder,//每日可领取奖励
            0,//可提收益
            false,           //是否解冻
            _areaIndex
        ));
        emit orderEvent(_user,_amount,block.timestamp,unfreezeTime, orderInfos[_user].length-1);
       //修改上级团队的总入金经金额   
    }

    fallback() external payable{}
    receive() external payable {}
}