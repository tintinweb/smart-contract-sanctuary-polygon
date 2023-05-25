/**
 *Submitted for verification at polygonscan.com on 2023-05-24
*/

// SPDX-License-Identifier: MIT AND UNLICENSED
//
// OpenZeppelin and ERC-6956 are licensed under MIT
//   Note ERC-6956 is authored by us (authenticvision.com)
//
// All other contracts are UNLICENSED, visit metaanchor.io for licensing information
//
// Meta Anchor (TM), Authentic Vision (TM) and Digital Soul (TM) are Registered Trademarks 
// and will be denoted as MetaAnchor, AuthenticVision and DigitalSoul subsequently.

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/utils/math/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts (last updated v4.8.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}


// File contracts/DeployerContract.sol


pragma solidity ^0.8.18;

/**
 * @title Interface for contracts featuring cascade-verification of the deployment origination
 * @author [email protected] 
 * @notice Allows cascade-verification of a deployment origination across multiple DeployerContracts
 * @dev Contracts implementing this interface must take as the first constructor-parameter the address of the
 * `DeployerContract`
 */
interface IDeployedContract {
    /**
     * @notice Indicates whether addr has been directly or indirectly deployed by this contract
     * @dev Indirect deployment means e.g. by deploying through a contract that has been deployed by this contract
     * 
     * @param addr Address of the deployed contract requesting initArgs
     * @return hasDeployedAddr abi-encoded init args
     */
    function hasDeployed(address addr) external view returns (bool hasDeployedAddr);

    /**
     * Returns the deployer of a particular contract. Can be EOA or Contract Account 
     */
    function deployedBy() external view returns (address deployer);
}

/**
 * @title Predictable-Deployment contract of origin-verifyable contracts
 * @author [email protected]
 * @notice Deploys contracts implementing IDeployedContract based on passed bytecode and constructorArgs and allows to trace their origin
 * across multiple Deployercontracts
 * 
 * @dev Has a static deployment salt, which shall only be changed in absolute emergencies.
 * The root contract is typically deployed by the Nonce=0 of an account on different blockchains.
 * This ensures that all contracts can be cascade-verified to originate from one well-known and trusted
 * source, e.g. an AppHub for a company. 
 * 
 */
abstract contract DeployerContract is IDeployedContract {
    mapping (address => address) private _deployedContractsWithOperator;
    IDeployedContract[] public deployedContracts;

    address public deployedBy;
    bytes32 private _salt;

    /**
     * @notice Emits when a contract is deployed through `deploy()`
     * @param deployedAddress Address of the just deployed contract
     * @param operator The operator initiating the deployment
     */
    event ContractDeployed(address deployedAddress, address operator);

    /**
     * @notice Emits (in emergencies), when salt is updated.
     * @param newSalt The new salt used for new deployments
     * @param oldSalt The old salt, has been used for previous deployments
     * @param maintainer Initiator of the salt update
     */
    event DeploymentSaltUpdate(bytes32 newSalt, bytes32 oldSalt, address maintainer);

    /**
     * @notice Indicates whether `addr` can use the `deploy()` function.
     * @dev To be overwritten by extending contracts, typically by only authorizing a specific role.
     * @param addr The address in question
     */
    function canDeploy(address addr) public virtual returns (bool);

    modifier onlyDeployer() {
        require(canDeploy(msg.sender), "msg.sender must be deployer");
        _;
    }

    /**
     * Returns the predicted address (with the current `_salt`) for a provided bytecode and constructorArgs
     * @param bytecode The bytecode to be deployed
     * @param constructorArgs abi-encoded constructor args, accepted by the constructor of the contract in bytecode
     */
    function getAddress(
        bytes memory bytecode,
        bytes memory constructorArgs
    ) public view returns (address) {
        uint actualSalt = uint(_salt);
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), actualSalt, keccak256(_assembleByteCodeAndArgs(bytecode, constructorArgs)))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }

    /**
     * @notice Like `getAddress(bytes,bytes)`, but for constructors not taking additional arguments (additional to deployer address)
     * @param bytecode Bytecode to be deployed
     */
    function getAddress(
        bytes memory bytecode
    ) public view returns (address) {
        return getAddress(bytecode, abi.encode(address(this)));
    }

    /**
     * @notice Indicates whether a contract at `addr` directly or indirectly has been deployed through this contract
     * @param addr Address of the contract in question
     * @dev This function is typically cascade-called from parent DeployerContracts
     */
    function hasDeployed(address addr) public view returns (bool hasDeployedAddr) {
        if(_deployedContractsWithOperator[addr] != address(0)) {
            return true;
        }

        for(uint i=0; i<deployedContracts.length; i++) {
            if(deployedContracts[i].hasDeployed(addr)) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Internhal helper to pack bytecode and constructor args. Ensurs the first constructor argument is the deployer, i.e. address(this)
     * @param byteCode Bytecode excl constructor args
     * @param constructorArgs ABI-encoded, expected to have the address of this contract encoded as first argument
     */
    function _assembleByteCodeAndArgs(bytes memory byteCode, bytes memory constructorArgs) internal view returns (bytes memory bytecodeWithArgs) {
        (address deployerAddress) = abi.decode(constructorArgs, (address));
        require(deployerAddress == address(this), "First constructor arg must be address of this contract");
        return abi.encodePacked(byteCode, constructorArgs);
    }
    
    /**
     * @notice Deploys bytecode of IDeployedContract-implementing contract with constructor args
     * @param byteCode Bytecode of contract implementing IDeployedContract
     * @param constructorArgs ABI-encoded constructor args, first argument must be address of this contract
     * @dev Emits ContractDeployed
     *      Throws if bytecode does not implement IDeployedContract
     *      Throws if `deployedBy()` of the deployed contract does not indicate this contract as deployer, 
     *      hence `hasDeployed()` mechanism would fail
     */
    function deploy(bytes memory byteCode, bytes memory constructorArgs) public onlyDeployer() {
        // verify first argument of constructorArgs is address(this)
        address addr = _deployBinary(_assembleByteCodeAndArgs(byteCode, constructorArgs), _salt);

        // verify the contract implements IDeployedContract
        require(ERC165Checker.supportsInterface(addr, type(IDeployedContract).interfaceId), "Can only deploy contracts implementing IDeployedContract interface");

        // verify contract claims this contract as deployer
        require(IDeployedContract(addr).deployedBy() == address(this), "Deployed contract must return this contract in getDeployer()");

        emit ContractDeployed(addr, msg.sender);
        _deployedContractsWithOperator[addr] = msg.sender;
        deployedContracts.push(IDeployedContract(addr));
    }

    /**
     * @notice Like deploy(bytes,bytes), but adds address(this) as only constructor argument
     * @param byteCode Bytecode of contract implementing IDeployedContract
     */
    function deploy(bytes memory byteCode) public onlyDeployer() {
        deploy(byteCode, abi.encode(address(this)));        
    }
         
    /**
     * @notice Updates the deployment salt - do only use in absolut emergencies!
     * @dev This shall not be used at all and is just for emergencies and major fuckups. As soon 
     * as the salt is updated, it can happen that the same contract / same version / same constructorArgs
     * can be re-deployed to a different address. 
     */
    function updateDeploymentSalt(bytes32 newSalt) public onlyDeployer()  {
        emit DeploymentSaltUpdate(_salt, newSalt, msg.sender);
        _salt = newSalt;
    }

    /**
     * @param bytecode Bytecode + packed constructorArgs of contract implementing IDeployedContract
     * @param salt The deployment salt.
     * @dev Isolated function to actually deploy contracts (can be used by extending contracts)
     *      inspired by https://solidity-by-example.org/app/create2/
     *      Salt is taken as parameter to also allow deploying contracts with an "old" salt in case of
     *      emergency salt-upgrade.
     */
    function _deployBinary(bytes memory bytecode, bytes32 salt) internal virtual onlyDeployer() returns (address) {
        address addr;

        uint actualSalt = uint(salt);
        /*
        NOTE: How to call create2

        create2(v, p, n, s)
        create new contract with code at memory p to p + n
        and send v wei
        and return the new address
        where new address = first 20 bytes of keccak256(0xff + address(this) + s + keccak256(mem[p…(p+n)))
              s = big-endian 256-bit value
        */
        assembly {
            addr := create2(
                callvalue(), // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(bytecode, 0x20),
                mload(bytecode), // Load the size of code contained in the first 32 bytes
                actualSalt // Salt from function arguments
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        return addr;
    }

    constructor() {
        deployedBy = msg.sender;
    }
}


// File contracts/AppHub.sol


pragma solidity ^0.8.18;
/**
 * @title AuthenticVision MetaAnchor AppHub
 * @author [email protected]
 * @notice Used to manage roles and verify a deployed contract originates directly or indirectly from this AppHub.
 * @dev This can be seen as the "AuthenticVision root certificate". All contracts deployed by Authentic Vision
 *      will have `hasDeployed(address)==true`. Only these contracts originate from Authentic Vision.
 *      
 *      This AppHub will be deployed at the same address in all Blockchains we support. 
 * 
 *      Visit authenticvision.com for contact and further information
 */
contract AppHub is AccessControl, DeployerContract {

  /**
   * @notice DEPLOYER_ROLE can deploy new MetaAnchor-Contracts from MetaAnchorFactory
   * @return Role hash, as should be passed to hasRole(), grantRole()
   */
  bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
  
  /**
   * @notice FACTORY_DEPLOYER_ROLE can deploy factories (via AppHub)
   */
  bytes32 public constant FACTORY_DEPLOYER_ROLE = keccak256("FACTORY_DEPLOYER_ROLE");

  /**
   * @notice FACTORY_MAINTAINER_ROLE can maintain factories, e.g. add providers, remove registrations, ..
   */
  bytes32 public constant FACTORY_MAINTAINER_ROLE = keccak256("FACTORY_MAINTAINER_ROLE");

  /**
   * @notice MAINTAINER_ROLE can maintain MetaAnchor-Contracts, e.g. updateValidAnchors(), configurations, owners, etc.
   */
  bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

  /**
   * @notice Signatures for ORACLE_ROLE will be accepted for ERC-6956 attestations
   */
  bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

  /**
   * @notice PAUSER_ROLE has permission to pause contracts
   */
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /**
   * @notice REGISTRAR_ROLE can register (and unregister their own) contracts for deployment
   */
  bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

  /**
   * @notice Overrides authorization functionality from `DeployerContract` to allow only FACTORY_DEPLOYER_ROLE accounts
   * @param addr Account address in equestion
   * @return addrIsDeployer true indicates this account can deploy contracts via `deploy()` method
   */
  function canDeploy(address addr) public view override(DeployerContract) returns (bool addrIsDeployer) {
    return hasRole(FACTORY_DEPLOYER_ROLE, addr);
  }  

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }
}


// File contracts/AppContract.sol


pragma solidity ^0.8.18;
/**
 * @title AppContract for access control. Base-class for actual contracts controlled by AppHub
 * @author [email protected]
 */
contract AppContract is AccessControl {
  AppHub internal _hub;

 constructor(address hub) {
    _hub = AppHub(hub);
  }

  /**
    * @dev Returns `true` if `account` has been granted `role`.
    * @notice Check whether a specific account has a certain role. This role is also set in all linked contracts.
    */
  function hasRole(bytes32 role, address account) public view virtual override(AccessControl) returns (bool) {
      return (super.hasRole(role, account) || _hub.hasRole(role, account));
  }

  /**
   * @dev Updates the address of app_hub.
   * @param hub Address of the app-hub
   */
  function updateAppHub(address hub) public onlyRole(DEFAULT_ADMIN_ROLE) {
    address prevHubAddr = address(_hub);
    _hub = AppHub(hub);
    // after update, I still need to have the default admin role from appHub
    require(ERC165Checker.supportsInterface(hub, type(IDeployedContract).interfaceId), "AppHub must implement IDeployedContract");
    require(_hub.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Account has no admin role in AppHub");
    emit AppHubUpdate(hub, prevHubAddr, msg.sender);
  }

  event AppHubUpdate(address hub, address oldHub, address maintainer);


  // The following functions are overrides required by Solidity, EIP-165.
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File contracts/eip-6956/IERC6956.sol



pragma solidity ^0.8.18;

/**
 * @title IERC6956 Asset-Bound Non-Fungible Tokens 
 * @notice Asset-bound Non-Fungible Tokens anchor a token 1:1 to a (physical or digital) asset and token transfers are authorized through attestation of control over the asset
 * @dev See https://eips.ethereum.org/EIPS/eip-6956
 *      Note: The ERC-165 identifier for this interface is 0xa9cf7635
 */
interface IERC6956 {
   
    /** @dev Authorization, typically mapped to authorizationMaps, where each bit indicates whether a particular ERC6956Role is authorized 
     *      Typically used in constructor (hardcoded or params) to set burnAuthorization and approveAuthorization
     *      Also used in optional updateBurnAuthorization, updateApproveAuthorization, I
     */ 
    enum Authorization {
        NONE,               // = 0,      // None of the above
        OWNER,              // = (1<<OWNER), // The owner of the token, i.e. the digital representation
        ISSUER,             // = (1<<ISSUER), // The issuer of the tokens, i.e. this smart contract
        ASSET,              // = (1<<ASSET), // The asset, i.e. via attestation
        OWNER_AND_ISSUER,   // = (1<<OWNER) | (1<<ISSUER),
        OWNER_AND_ASSET,    // = (1<<OWNER) | (1<<ASSET),
        ASSET_AND_ISSUER,   // = (1<<ASSET) | (1<<ISSUER),
        ALL                 // = (1<<OWNER) | (1<<ISSUER) | (1<<ASSET) // Owner + Issuer + Asset
    }
    
    /**
     * @notice This emits when approved address for an anchored tokenId is changed or reaffirmed via attestation
     * @dev This emits when approveAnchor() is called and corresponds to ERC-721 behavior
     * @param owner The owner of the anchored tokenId
     * @param approved The approved address, address(0) indicates there is no approved address
     * @param anchor The anchor, for which approval has been chagned
     * @param tokenId ID (>0) of the anchored token
     */
    event AnchorApproval(address indexed owner, address approved, bytes32 indexed anchor, uint256 tokenId);

    /**
     * @notice This emits when the ownership of any anchored NFT changes by any mechanism
     * @dev This emits together with tokenId-based ERC-721.Transfer and provides an anchor-perspective on transfers
     * @param from The previous owner, address(0) indicate there was none.
     * @param to The new owner, address(0) indicates the token is burned
     * @param anchor The anchor which is bound to tokenId
     * @param tokenId ID (>0) of the anchored token
     */
    event AnchorTransfer(address indexed from, address indexed to, bytes32 indexed anchor, uint256 tokenId);
    /**
     * @notice This emits when an attestation has been used indicating no second attestation with the same attestationHash will be accepted
     * @param to The to address specified in the attestation
     * @param anchor The anchor specificed in the attestation
     * @param attestationHash The hash of the attestation, see ERC-6956 for details
     * @param totalUsedAttestationsForAnchor The total number of attestations already used for the particular anchor
     */
    event AttestationUse(address indexed to, bytes32 indexed anchor, bytes32 indexed attestationHash, uint256 totalUsedAttestationsForAnchor);

    /**
     * @notice This emits when the trust-status of an oracle changes. 
     * @dev Trusted oracles must explicitely be specified. 
     *      If the last event for a particular oracle-address indicates it's trusted, attestations from this oracle are valid.
     * @param oracle Address of the oracle signing attestations
     * @param trusted indicating whether this address is trusted (true). Use (false) to no longer trust from an oracle.
     */
    event OracleUpdate(address indexed oracle, bool indexed trusted);

    /**
     * @notice Returns the 1:1 mapped anchor for a tokenId
     * @param tokenId ID (>0) of the anchored token
     * @return anchor The anchor bound to tokenId, 0x0 if tokenId does not represent an anchor
     */
    function anchorByToken(uint256 tokenId) external view returns (bytes32 anchor);
    /**
     * @notice Returns the ID of the 1:1 mapped token of an anchor.
     * @param anchor The anchor (>0x0)
     * @return tokenId ID of the anchored token, 0 if no anchored token exists
     */
    function tokenByAnchor(bytes32 anchor) external view returns (uint256 tokenId);

    /**
     * @notice The number of attestations already used to modify the state of an anchor or its bound tokens
     * @param anchor The anchor(>0)
     * @return attestationUses The number of attestation uses for a particular anchor, 0 if anchor is invalid.
     */
    function attestationsUsedByAnchor(bytes32 anchor) view external returns (uint256 attestationUses);
    /**
     * @notice Decodes and returns to-address, anchor and the attestation hash, if the attestation is valid
     * @dev MUST throw when
     *  - Attestation has already been used (an AttestationUse-Event with matching attestationHash was emitted)
     *  - Attestation is not signed by trusted oracle (the last OracleUpdate-Event for the signer-address does not indicate trust)
     *  - Attestation is not valid yet or expired
     *  - [if IERC6956AttestationLimited is implemented] attestationUsagesLeft(attestation.anchor) <= 0
     *  - [if IERC6956ValidAnchors is implemented] validAnchors(data) does not return true. 
     * @param attestation The attestation subject to the format specified in ERC-6956
     * @param data Optional additional data, may contain proof as the first abi-encoded argument when IERC6956ValidAnchors is implemented
     * @return to Address where the ownership of an anchored token or approval shall be changed to
     * @return anchor The anchor (>0)
     * @return attestationHash The attestation hash computed on-chain as `keccak256(attestation)`
     */
    function decodeAttestationIfValid(bytes memory attestation, bytes memory data) external view returns (address to, bytes32 anchor, bytes32 attestationHash);

    /**
     * @notice Indicates whether any of ASSET, OWNER, ISSUER is authorized to burn
     */
    function burnAuthorization() external view returns(Authorization burnAuth);

    /**
     * @notice Indicates whether any of ASSET, OWNER, ISSUER is authorized to approve
     */
    function approveAuthorization() external view returns(Authorization approveAuth);

    /**
     * @notice Corresponds to transferAnchor(bytes,bytes) without additional data
     * @param attestation Attestation, refer ERC-6956 for details
     */
    function transferAnchor(bytes memory attestation) external;

    /**
     * @notice Changes the ownership of an NFT mapped to attestation.anchor to attestation.to address.
     * @dev Permissionless, i.e. anybody invoke and sign a transaction. The transfer is authorized through the oracle-signed attestation.
     *  - Uses decodeAttestationIfValid()
     *  - When using a centralized "gas-payer" recommended to implement IERC6956AttestationLimited.
     *  - Matches the behavior of ERC-721.safeTransferFrom(ownerOf[tokenByAnchor(attestation.anchor)], attestation.to, tokenByAnchor(attestation.anchor), ..) and mint an NFT if `tokenByAnchor(anchor)==0`.
     *  - Throws when attestation.to == ownerOf(tokenByAnchor(attestation.anchor))
     *  - Emits AnchorTransfer  
     *  
     * @param attestation Attestation, refer EIP-6956 for details
     * @param data Additional data, may be used for additional transfer-conditions, may be sent partly or in full in a call to safeTransferFrom
     * 
     */
    function transferAnchor(bytes memory attestation, bytes memory data) external;

     /**
     * @notice Corresponds to approveAnchor(bytes,bytes) without additional data
     * @param attestation Attestation, refer ERC-6956 for details
     */
    function approveAnchor(bytes memory attestation) external;

     /**
     * @notice Approves attestation.to the token bound to attestation.anchor. .
     * @dev Permissionless, i.e. anybody invoke and sign a transaction. The transfer is authorized through the oracle-signed attestation.
     *  - Uses decodeAttestationIfValid()
     *  - When using a centralized "gas-payer" recommended to implement IERC6956AttestationLimited.
     *  - Matches the behavior of ERC-721.approve(attestation.to, tokenByAnchor(attestation.anchor)).
     *  - Throws when ASSET is not authorized to approve.
     * 
     * @param attestation Attestation, refer EIP-6956 for details 
     */
    function approveAnchor(bytes memory attestation, bytes memory data) external;

    /**
     * @notice Corresponds to burnAnchor(bytes,bytes) without additional data
     * @param attestation Attestation, refer ERC-6956 for details
     */
    function burnAnchor(bytes memory attestation) external;
   
    /**
     * @notice Burns the token mapped to attestation.anchor. Uses ERC-721._burn.
     * @dev Permissionless, i.e. anybody invoke and sign a transaction. The transfer is authorized through the oracle-signed attestation.
     *  - Uses decodeAttestationIfValid()
     *  - When using a centralized "gas-payer" recommended to implement IERC6956AttestationLimited.
     *  - Throws when ASSET is not authorized to burn
     * 
     * @param attestation Attestation, refer EIP-6956 for details
     */
    function burnAnchor(bytes memory attestation, bytes memory data) external;
}


// File contracts/eip-6956/ERC6956.sol



pragma solidity ^0.8.18;






/** Used for several authorization mechansims, e.g. who can burn, who can set approval, ... 
 * @dev Specifying the role in the ecosystem. Used in conjunction with IERC6956.Authorization
 */
enum Role {
    OWNER,  // =0, The owner of the digital token
    ISSUER, // =1, The issuer (contract) of the tokens, typically represented through a MAINTAINER_ROLE, the contract owner etc.
    ASSET,  // =2, The asset identified by the anchor
    INVALID // =3, Reserved, do not use.
}

/**
 * @title ASSET-BOUND NFT minimal reference implementation 
 * @author Thomas Bergmueller (@tbergmueller)
 * 
 * @dev Error messages
 * ```
 * ERROR | Message
 * ------|-------------------------------------------------------------------
 * E1    | Only maintainer allowed
 * E2    | No permission to burn
 * E3    | Token does not exist, call transferAnchor first to mint
 * E4    | batchSize must be 1
 * E5    | Token not transferable
 * E6    | Token already owned
 * E7    | Not authorized based on ERC6956Authorization
 * E8    | Attestation not signed by trusted oracle
 * E9    | Attestation already used
 * E10   | Attestation not valid yet
 * E11   | Attestation expired 
 * E12   | Attestation expired (contract limit)
 * E13   | Invalid signature length
 * E14-20| Reserved for future use
 * ```
 */
contract ERC6956 is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    IERC6956 
{
    using Counters for Counters.Counter;

    mapping(bytes32 => bool) internal _anchorIsReleased; // currently released anchors. Per default, all anchors are dropped, i.e. 1:1 bound
    
    mapping(address => bool) public maintainers;

    /// @notice Resolves tokenID to anchor. Inverse of tokenByAnchor
    mapping(uint256 => bytes32) public anchorByToken;

    /// @notice Resolves Anchor to tokenID. Inverse of anchorByToken
    mapping(bytes32 => uint256) public tokenByAnchor;

    mapping(address => bool) private _trustedOracles;

    /// @dev stores the anchors for each attestation
    mapping(bytes32 => bytes32) private _anchorByUsedAttestation;

    /// @dev stores handed-back tokens (via burn)
    mapping (bytes32 => uint256) private _burnedTokensByAnchor;


     /**
     * @dev Counter to keep track of issued tokens
     */
    Counters.Counter private _tokenIdCounter;

    /// @dev Default validity timespan of attestation. In validateAttestation the attestationTime is checked for MIN(defaultAttestationvalidity, attestation.expiry)
    uint256 public maxAttestationExpireTime = 5*60; // 5min valid per default

    Authorization public burnAuthorization;
    Authorization public approveAuthorization;


    /// @dev Records the number of transfers done for each attestation
    mapping(bytes32 => uint256) public attestationsUsedByAnchor;

    modifier onlyMaintainer() {
        require(isMaintainer(msg.sender), "ERC6956-E1");
        _;
    }

    /**
     * @notice Behaves like ERC721 burn() for wallet-cleaning purposes. Note only the tokenId (as a wrapper) is burned, not the ASSET represented by the ANCHOR.
     * @dev 
     * - tokenId is remembered for the anchor, to ensure a later transferAnchor(), which would mint, assigns the same tokenId. This ensures strict 1:1 relation
     * - For burning, the anchor needs to be released. This forced release FOR BURNING ONLY is allowed for owner() or approvedOwner().
     * 
     * @param tokenId The token that shall be burned
     */
    function burn(uint256 tokenId) public override
    {
        // remember the tokenId of burned tokens, s.t. one can issue the token with the same number again
        bytes32 anchor = anchorByToken[tokenId];
        require(_roleBasedAuthorization(anchor, createAuthorizationMap(burnAuthorization)), "ERC6956-E2");
        _burn(tokenId);
    }

    function burnAnchor(bytes memory attestation, bytes memory data) public virtual
        authorized(Role.ASSET, createAuthorizationMap(burnAuthorization))
     {
        address to;
        bytes32 anchor;
        bytes32 attestationHash;
        (to, anchor, attestationHash) = decodeAttestationIfValid(attestation, data);
        _commitAttestation(to, anchor, attestationHash);
        uint256 tokenId = tokenByAnchor[anchor];
        // remember the tokenId of burned tokens, s.t. one can issue the token with the same number again
        _burn(tokenId);
    }

    function burnAnchor(bytes memory attestation) public virtual {
        return burnAnchor(attestation, "");
    }

    function approveAnchor(bytes memory attestation, bytes memory data) public virtual 
        authorized(Role.ASSET, createAuthorizationMap(approveAuthorization))
    {
        address to;
        bytes32 anchor;
        bytes32 attestationHash;
        (to, anchor, attestationHash) = decodeAttestationIfValid(attestation, data);
        _commitAttestation(to, anchor, attestationHash);
        require(tokenByAnchor[anchor]>0, "ERC6956-E3");
        _approve(to, tokenByAnchor[anchor]);
    }

    // approveAuth == ISSUER does not really make sense.. so no separate implementation, since ERC-721.approve already implies owner...

    function approve(address to, uint256 tokenId) public virtual override(ERC721,IERC721)
        authorized(Role.OWNER, createAuthorizationMap(approveAuthorization))
    {
        super.approve(to, tokenId);
    }

    function approveAnchor(bytes memory attestation) public virtual {
        return approveAnchor(attestation, "");
    }
    
    /**
     * @notice Adds or removes a trusted oracle, used when verifying signatures in `decodeAttestationIfValid()`
     * @dev Emits OracleUpdate
     * @param oracle address of oracle
     * @param doTrust true to add, false to remove
     */
    function updateOracle(address oracle, bool doTrust) public
        onlyMaintainer() 
    {
        _trustedOracles[oracle] = doTrust;
        emit OracleUpdate(oracle, doTrust);
    }

    /**
     * @dev A very simple function wich MUST return false, when `a` is not a maintainer
     *      When derived contracts extend ERC6956 contract, this function may be overridden
     *      e.g. by using AccessControl, onlyOwner or other common mechanisms
     * 
     *      Having this simple mechanism in the reference implementation ensures that the reference
     *      implementation is fully ERC-6956 compatible 
     */
    function isMaintainer(address a) public virtual view returns (bool) {
        return maintainers[a];
    } 
      

    function createAuthorizationMap(Authorization _auth) public pure returns (uint256)  {
       uint256 authMap = 0;
       if(_auth == Authorization.OWNER 
            || _auth == Authorization.OWNER_AND_ASSET 
            || _auth == Authorization.OWNER_AND_ISSUER 
            || _auth == Authorization.ALL) {
        authMap |= uint256(1<<uint256(Role.OWNER));
       } 
       
       if(_auth == Authorization.ISSUER 
            || _auth == Authorization.ASSET_AND_ISSUER 
            || _auth == Authorization.OWNER_AND_ISSUER 
            || _auth == Authorization.ALL) {
        authMap |= uint256(1<<uint256(Role.ISSUER));
       }

       if(_auth == Authorization.ASSET 
            || _auth == Authorization.ASSET_AND_ISSUER 
            || _auth == Authorization.OWNER_AND_ASSET 
            || _auth == Authorization.ALL) {
        authMap |= uint256(1<<uint256(Role.ASSET));
       }

       return authMap;
    }

    function _roleBasedAuthorization(bytes32 anchor, uint256 authorizationMap) internal view returns (bool) {
        uint256 tokenId = tokenByAnchor[anchor];        
        Role myRole = Role.INVALID;
        Role alternateRole = Role.INVALID;
        
        if(_isApprovedOrOwner(_msgSender(), tokenId)) {
            myRole = Role.OWNER;
        }

        if(isMaintainer(msg.sender)) {
            alternateRole = Role.ISSUER;
        }

        return hasAuthorization(myRole, authorizationMap) 
                    || hasAuthorization(alternateRole, authorizationMap);
    }
   
    ///@dev Hook executed before decodeAttestationIfValid returns. Override in derived contracts
    function _beforeAttestationUse(bytes32 anchor, address to, bytes memory data) internal view virtual {}
    

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal virtual
        override(ERC721, ERC721Enumerable)
    {
        require(batchSize == 1, "ERC6956-E4");
        bytes32 anchor = anchorByToken[tokenId];
        emit AnchorTransfer(from, to, anchor, tokenId);

        if(to == address(0)) {
            // we are burning, ensure the mapping is deleted BEFORE the transfer
            // to avoid reentrant-attacks
            _burnedTokensByAnchor[anchor] = tokenId; // Remember tokenId for a potential re-mint
            delete tokenByAnchor[anchor];
            delete anchorByToken[tokenId]; 
        }        
        else {
            require(_anchorIsReleased[anchor], "ERC6956-E5");
        }

        delete _anchorIsReleased[anchor]; // make sure anchor is non-released after the transfer again
   }

    /// @dev hook called after an anchor is minted
    function _afterAnchorMint(address to, bytes32 anchor, uint256 tokenId) internal virtual {}

    /**
     * @notice Add (_add=true) or remove (_add=false) a maintainer
     * @dev Note this is a trivial implementation, which can leave the contract without a maintainer.
     * Since the function is access-controlled via onlyMaintainer, this results in the contract
     * becoming unmaintainable. 
     * This may be desired behavior, for example if the contract shall become immutable until 
     * all eternity, therefore making a project truly trustless. 
     */
    function updateMaintainer(address _maintainer, bool _add) public onlyMaintainer() {
        maintainers[_maintainer] = _add;
    }

    /// @dev Verifies a anchor is valid and mints a token to the target address.
    /// Internal function to be called whenever minting is needed.
    /// Parameters:
    /// @param to Beneficiary account address
    /// @param anchor The anchor (from Merkle tree)
    function _safeMint(address to, bytes32 anchor) internal virtual {
        assert(tokenByAnchor[anchor] <= 0); // saftey for contract-internal errors
        uint256 tokenId = _burnedTokensByAnchor[anchor];

        if(tokenId < 1) {
            _tokenIdCounter.increment();
            tokenId = _tokenIdCounter.current();
        }

        assert(anchorByToken[tokenId] <= 0); // saftey for contract-internal errors
        anchorByToken[tokenId] = anchor;
        tokenByAnchor[anchor] = tokenId;
        super._safeMint(to, tokenId);

        _afterAnchorMint(to, anchor, tokenId);
    }

    function _commitAttestation(address to, bytes32 anchor, bytes32 attestationHash) internal {
        _anchorByUsedAttestation[attestationHash] = anchor;
        uint256 totalAttestationsByAnchor = attestationsUsedByAnchor[anchor] +1;
        attestationsUsedByAnchor[anchor] = totalAttestationsByAnchor;
        emit AttestationUse(to, anchor, attestationHash, totalAttestationsByAnchor );
    }

    function transferAnchor(bytes memory attestation, bytes memory data) public virtual
    {      
        bytes32 anchor;
        address to;
        bytes32 attestationHash;
        (to, anchor, attestationHash) = decodeAttestationIfValid(attestation, data);
        _commitAttestation(to, anchor, attestationHash); // commit already here, will be reverted in error case anyway

        uint256 fromToken = tokenByAnchor[anchor]; // tokenID, null if not exists
        address from = address(0); // owneraddress or 0x00, if not exists
        
        _anchorIsReleased[anchor] = true; // Attestation always temporarily releases the anchor       

        if(fromToken > 0) {
            from = ownerOf(fromToken);
            require(from != to, "ERC6956-E6");
            _safeTransfer(from, to, fromToken, "");
        } else {
            _safeMint(to, anchor);
        }
    }

    function transferAnchor(bytes memory attestation) public virtual {
        return transferAnchor(attestation, "");
    }
    

    function hasAuthorization(Role _role, uint256 _auth ) public pure returns (bool) {
        uint256 result = uint256(_auth & (1 << uint256(_role)));
        return result > 0;
    }

    modifier authorized(Role _role, uint256 _authMap) {
        require(hasAuthorization(_role, _authMap), "ERC6956-E7");
        _;
    }

    // The following functions are overrides required by Solidity, EIP-165.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC6956).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns whether a certain address is registered as trusted oracle, i.e. attestations signed by this address are accepted in `decodeAttestationIfValid`
     * @dev This function may be overwritten when extending ERC-6956, e.g. when other oracle-registration mechanics are used
     * @param oracleAddress Address of the oracle in question
     * @return isTrusted True, if oracle is trusted
     */
    function isTrustedOracle(address oracleAddress) public virtual view returns (bool isTrusted) {
        return _trustedOracles[oracleAddress];
    }
    

    function decodeAttestationIfValid(bytes memory attestation, bytes memory data) public view returns (address to, bytes32 anchor, bytes32 attestationHash) {
        uint256 attestationTime;
        uint256 validStartTime;
        uint256 validEndTime;
        bytes memory signature;
        bytes32[] memory proof;

        attestationHash = keccak256(attestation);
        (to, anchor, attestationTime, validStartTime, validEndTime, signature) = abi.decode(attestation, (address, bytes32, uint256, uint256, uint256, bytes));
                
        bytes32 messageHash = keccak256(abi.encodePacked(to, anchor, attestationTime, validStartTime, validEndTime, proof));
        address signer = _extractSigner(messageHash, signature);

        // Check if from trusted oracle
        require(isTrustedOracle(signer), "ERC6956-E8");
        require(_anchorByUsedAttestation[attestationHash] <= 0, "ERC6956-E9");

        // Check expiry
        uint256 timestamp = block.timestamp;
        require(timestamp > validStartTime, "ERC6956-E10");
        require(attestationTime + maxAttestationExpireTime > block.timestamp, "ERC6956-E11");
        require(validEndTime > block.timestamp, "ERC6956-E112");

        
        // Calling hook!
        _beforeAttestationUse(anchor, to, data);
        return(to,  anchor, attestationHash);
    }

    /// @notice Compatible with ERC721.tokenURI(). Returns {baseURI}{anchor}
    /// @dev Returns when called for tokenId=5, baseURI=https://myurl.com/collection/ and anchorByToken[5] =  0x12345
    /// Example:  https://myurl.com/collection/0x12345
    /// Works for non-burned tokens / active-Anchors only.
    /// Anchor-based tokenURIs are needed as an anchor's corresponding tokenId is only known after mint. 
    /// @param tokenId TokenID
    /// @return tokenURI Returns the Uniform Resource Identifier (URI) for `tokenId` token.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {        
        bytes32 anchor = anchorByToken[tokenId];
        string memory anchorString = Strings.toHexString(uint256(anchor));
        return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), anchorString)) : "";
    }

    function _baseURI() internal view virtual override(ERC721) returns (string memory) {
        return _baseUri;
    }

    /**
    * @dev Base URI, MUST end with a slash. Will be used as `{baseURI}{tokenId}` in tokenURI() function
    */
    string internal _baseUri = ""; // needs to end with '/'

    /// @notice Set a new BaseURI. Can be used with dynamic NFTs that have server APIs, IPFS-buckets
    /// or any other suitable system. Refer tokenURI(tokenId) for anchor-based or tokenId-based format.
    /// @param tokenBaseURI The token base-URI. Must end with slash '/'.
    function updateBaseURI(string calldata tokenBaseURI) public onlyMaintainer() {
        _baseUri = tokenBaseURI;
    }
    event BurnAuthorizationChange(Authorization burnAuth, address indexed maintainer);

    function updateBurnAuthorization(Authorization burnAuth) public onlyMaintainer() {
        burnAuthorization = burnAuth;
        emit BurnAuthorizationChange(burnAuth, msg.sender);
        // TODO event
    }
    
    event ApproveAuthorizationChange(Authorization approveAuth, address indexed maintainer);

    function updateApproveAuthorization(Authorization approveAuth) public onlyMaintainer() {
        approveAuthorization = approveAuth;
        emit ApproveAuthorizationChange(approveAuth, msg.sender);

        // TODO event
    }

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol) {            
            maintainers[msg.sender] = true; // deployer is automatically maintainer
            // Indicates general float-ability, i.e. whether anchors can be digitally dropped and released

            // OWNER and ASSET shall normally be in sync anyway, so this is reasonable default 
            // authorization for approve and burn, as it mimicks ERC-721 behavior
            burnAuthorization = Authorization.OWNER_AND_ASSET;
            approveAuthorization = Authorization.OWNER_AND_ASSET;
    }
  
    /*
     ########################## SIGNATURE MAGIC, 
     ########################## adapted from https://solidity-by-example.org/signature/
    */
   /**
    * Returns the signer of a message.
    *  
    *   OFF-CHAIN: 
    *   const [alice] = ethers.getSigners(); // = 0x3c44...
    *   const messageHash = ethers.utils.solidityKeccak256(["address", "bytes32"], [a, b]);
        const sig = await alice.signMessage(ethers.utils.arrayify(messageHash));

        ONCHAIN In this contract, call from 
        ```
        function (address a, bytes32 b, bytes memory sig) {
            messageHash = keccak256(abi.encodePacked(to, b));
            signer = extractSigner(messageHash, sig); // signer will be 0x3c44...
        }
        ```    * 
    * @param messageHash A keccak25(abi.encodePacked(...)) hash
    * @param sig Signature (length 65 bytes)
    * 
    * @return The signer
    */
   function _extractSigner(bytes32 messageHash, bytes memory sig) internal pure returns (address) {
        require(sig.length == 65, "ERC6956-E13");
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Extract the r, s, and v parameters from the signature
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Ensure the v parameter is either 27 or 28
        // TODO is this needed?
        if (v < 27) {
            v += 27;
        }

        // Recover the public key from the signature and message hash
        // and convert it to an address
        address signer = ecrecover(ethSignedMessageHash, v, r, s);       
        return signer;
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}


// File contracts/eip-6956/IERC6956AttestationLimited.sol



pragma solidity ^0.8.18;

/**
 * @title Attestation-limited Asset-Bound NFT
 * @dev See https://eips.ethereum.org/EIPS/eip-6956
 *      Note: The ERC-165 identifier for this interface is 0x75a2e933
 */
interface IERC6956AttestationLimited is IERC6956 {
    enum AttestationLimitPolicy {
        IMMUTABLE,
        INCREASE_ONLY,
        DECREASE_ONLY,
        FLEXIBLE
    }
        
    /// @notice Returns the attestation limit for a particular anchor
    /// @dev MUST return the global attestation limit per default
    ///      and override the global attestation limit in case an anchor-based limit is set
    function attestationLimit(bytes32 anchor) external view returns (uint256 limit);

    /// @notice Returns number of attestations left for a particular anchor
    /// @dev Is computed by comparing the attestationsUsedByAnchor(anchor) and the current attestation limit 
    ///      (current limited emitted via GlobalAttestationLimitUpdate or AttestationLimt events)
    function attestationUsagesLeft(bytes32 anchor) external view returns (uint256 nrTransfersLeft);

    /// @notice Indicates the policy, in which direction attestation limits can be updated (globally or per anchor)
    function attestationLimitPolicy() external view returns (AttestationLimitPolicy policy);

    /// @notice This emits when the global attestation limt is updated
    event GlobalAttestationLimitUpdate(uint256 indexed transferLimit, address updatedBy);

    /// @notice This emits when an anchor-specific attestation limit is updated
    event AttestationLimitUpdate(bytes32 indexed anchor, uint256 indexed tokenId, uint256 indexed transferLimit, address updatedBy);

    /// @dev This emits in the transaction, where attestationUsagesLeft becomes 0
    event AttestationLimitReached(bytes32 indexed anchor, uint256 indexed tokenId, uint256 indexed transferLimit);
}


// File contracts/eip-6956/IERC6956Floatable.sol



pragma solidity ^0.8.18;

/**
 * @title Floatable Asset-Bound NFT
 * @notice A floatable Asset-Bound NFT can (temporarily) be transferred without attestation
 * @dev See https://eips.ethereum.org/EIPS/eip-6956
 *      Note: The ERC-165 identifier for this interface is 0xf82773f7
 */
interface IERC6956Floatable is IERC6956 {
    enum FloatState {
        Default, // 0, inherits from floatAll
        Floating, // 1
        Anchored // 2
    }

    /// @notice Indicates that an anchor-specific floating state changed
    event FloatingStateChange(bytes32 indexed anchor, uint256 indexed tokenId, FloatState isFloating, address operator);
    /// @notice Emits when FloatingAuthorization is changed.
    event FloatingAuthorizationChange(Authorization startAuthorization, Authorization stopAuthorization, address maintainer);
    /// @notice Emits, when the default floating state is changed
    event FloatingAllStateChange(bool areFloating, address operator);

    /// @notice Indicates whether an anchored token is floating, namely can be transferred without attestation
    function floating(bytes32 anchor) external view returns (bool);
    
    /// @notice Indicates whether any of OWNER, ISSUER, (ASSET) is allowed to start floating
    function floatStartAuthorization() external view returns (Authorization canStartFloating);
    
    /// @notice Indicates whether any of OWNER, ISSUER, (ASSET) is allowed to stop floating
    function floatStopAuthorization() external view returns (Authorization canStartFloating);

    /**
     * @notice Allows to override or reset to floatAll-behavior per anchor
     * @dev Must throw when newState == Floating and floatStartAuthorization does not authorize msg.sender
     * @dev Must throw when newState == Anchored and floatStopAuthorization does not authorize msg.sender
     * @param anchor The anchor, whose anchored token shall override default behavior
     * @param newState Override-State. If set to Default, the anchor will behave like floatAll
     */
    function float(bytes32 anchor, FloatState newState) external;    
}


// File contracts/eip-6956/IERC6956ValidAnchors.sol



pragma solidity ^0.8.18;

/**
 * @title Anchor-validating Asset-Bound NFT
 * @dev See https://eips.ethereum.org/EIPS/eip-6956
 *      Note: The ERC-165 identifier for this interface is 0x051c9bd8
 */
interface IERC6956ValidAnchors is IERC6956 {
    /**
     * @notice Emits when the valid anchors for the contract are updated.
     * @param validAnchorHash Hash representing all valid anchors. Typically Root of MerkleTree
     * @param maintainer msg.sender updating the hash
     */
    event ValidAnchorsUpdate(bytes32 indexed validAnchorHash, address indexed maintainer);

    /**
     * @notice Indicates whether an anchor is valid in the present contract
     * @dev Typically implemented via MerkleTrees, where proof is used to verify anchor is part of the MerkleTree 
     *      MUST return false when no ValidAnchorsUpdate-event has been emitted yet
     * @param anchor The anchor in question
     * @param proof Proof that the anchor is valid, typically MerkleProof
     * @return isValid True, when anchor and proof can be verified against validAnchorHash (emitted via ValidAnchorsUpdate-event)
     */
    function anchorValid(bytes32 anchor, bytes32[] memory proof) external view returns (bool isValid);        
}


// File contracts/eip-6956/ERC6956Full.sol



pragma solidity ^0.8.18;









/**
 * @title ASSET-BOUND NFT implementation with all interfaces
 * @author Thomas Bergmueller (@tbergmueller)
 * @notice Extends ERC6956.sol with additional interfaces and functionality
 * 
 * @dev Error-codes
 * ERROR | Message
 * ------|-------------------------------------------------------------------
 * E1-20 | See ERC6956.sol
 * E21   | No permission to start floating
 * E22   | No permission to stop floating
 * E23   | allowFloating can only be called when changing floating state
 * E24   | No attested transfers left
 * E25   | data must contain merkle-proof
 * E26   | Anchor not valid
 * E27   | Updating attestedTransferLimit violates policy
 */
contract ERC6956Full is ERC6956, IERC6956AttestationLimited, IERC6956Floatable, IERC6956ValidAnchors {
    Authorization public floatStartAuthorization;
    Authorization public floatStopAuthorization;

    /// ###############################################################################################################################
    /// ##############################################################################################  IERC6956AttestedTransferLimited
    /// ###############################################################################################################################
    
    mapping(bytes32 => uint256) public attestedTransferLimitByAnchor;
    mapping(bytes32 => FloatState) public floatingStateByAnchor;

    uint256 public globalAttestedTransferLimitByAnchor;
    AttestationLimitPolicy public attestationLimitPolicy;

    bool public allFloating;

    /// @dev The merkle-tree root node, where proof is validated against. Update via updateValidAnchors(). Use salt-leafs in merkle-trees!
    bytes32 private _validAnchorsMerkleRoot;

    function _requireValidLimitUpdate(uint256 oldValue, uint256 newValue) internal view {
        if(newValue > oldValue) {
            require(attestationLimitPolicy == AttestationLimitPolicy.FLEXIBLE || attestationLimitPolicy == AttestationLimitPolicy.INCREASE_ONLY, "ERC6956-E27");
        } else {
            require(attestationLimitPolicy == AttestationLimitPolicy.FLEXIBLE || attestationLimitPolicy == AttestationLimitPolicy.DECREASE_ONLY, "ERC6956-E27");
        }
    }

    function updateGlobalAttestationLimit(uint256 _nrTransfers) 
        public 
        onlyMaintainer() 
    {
       _requireValidLimitUpdate(globalAttestedTransferLimitByAnchor, _nrTransfers);
       globalAttestedTransferLimitByAnchor = _nrTransfers;
       emit GlobalAttestationLimitUpdate(_nrTransfers, msg.sender);
    }

    function updateAttestationLimit(bytes32 anchor, uint256 _nrTransfers) 
        public 
        onlyMaintainer() 
    {
       uint256 currentLimit = attestationLimit(anchor);
       _requireValidLimitUpdate(currentLimit, _nrTransfers);
       attestedTransferLimitByAnchor[anchor] = _nrTransfers;
       emit AttestationLimitUpdate(anchor, tokenByAnchor[anchor], _nrTransfers, msg.sender);
    }

    function attestationLimit(bytes32 anchor) public view returns (uint256 limit) {
        if(attestedTransferLimitByAnchor[anchor] > 0) { // Per anchor overwrites always, even if smaller than globalAttestedTransferLimit
            return attestedTransferLimitByAnchor[anchor];
        } 
        return globalAttestedTransferLimitByAnchor;
    }

    function attestationUsagesLeft(bytes32 anchor) public view returns (uint256 nrTransfersLeft) {
        // FIXME panics when attestationsUsedByAnchor > attestedTransferLimit 
        // since this should never happen, maybe ok?
        return attestationLimit(anchor) - attestationsUsedByAnchor[anchor];
    }

    /// ###############################################################################################################################
    /// ##############################################################################################  FLOATABILITY
    /// ###############################################################################################################################
    
    function updateFloatingAuthorization(Authorization startAuthorization, Authorization stopAuthorization) public
        onlyMaintainer() {
            floatStartAuthorization = startAuthorization;
            floatStopAuthorization = stopAuthorization;
            emit FloatingAuthorizationChange(startAuthorization, stopAuthorization, msg.sender);
    }

    function floatAll(bool doFloatAll) public onlyMaintainer() {
        require(doFloatAll != allFloating, "ERC6956-E23");
        allFloating = doFloatAll;
        emit FloatingAllStateChange(doFloatAll, msg.sender);
    }


    function _floating(bool defaultFloatState, FloatState anchorFloatState) internal pure returns (bool floats) {
        if(anchorFloatState == FloatState.Default) {
            return defaultFloatState;
        }
        return anchorFloatState == FloatState.Floating; 
    }

    function float(bytes32 anchor, FloatState newFloatState) public 
    {
        bool currentFloatState = floating(anchor);
        bool willFloat = _floating(allFloating, newFloatState);

        require(willFloat != currentFloatState, "ERC6956-E23");

        if(willFloat) {
            require(_roleBasedAuthorization(anchor, createAuthorizationMap(floatStartAuthorization)), "ERC6956-E21");
        } else {
            require(_roleBasedAuthorization(anchor, createAuthorizationMap(floatStopAuthorization)), "ERC6956-E22");
        }

        floatingStateByAnchor[anchor] = newFloatState;
        emit FloatingStateChange(anchor, tokenByAnchor[anchor], newFloatState, msg.sender);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal virtual
        override(ERC6956)  {
            bytes32 anchor = anchorByToken[tokenId];
                    
            if(!_anchorIsReleased[anchor]) {
                // Only write when not already released - this saves gas, as memory-write is quite expensive compared to IF
                if(floating(anchor)) {
                    _anchorIsReleased[anchor] = true; // FIXME OPTIMIZATION, we do not need 
                }
            }
             
            super._beforeTokenTransfer(from, to, tokenId, batchSize);
        }
    function _beforeAttestationUse(bytes32 anchor, address to, bytes memory data) internal view virtual override(ERC6956) {
        // empty, can be overwritten by derived conctracts.
        require(attestationUsagesLeft(anchor) > 0, "ERC6956-E24");

        // IERC6956ValidAnchors check anchor is indeed valid in contract
        require(data.length > 0, "ERC6956-E25");
        bytes32[] memory proof;
        (proof) = abi.decode(data, (bytes32[])); // Decode it with potentially more data following. If there is more data, this may be passed on to safeTransfer
        require(anchorValid(anchor, proof), "ERC6956-E26");

        super._beforeAttestationUse(anchor, to, data);
    }


    /// @notice Update the Merkle root containing the valid anchors. Consider salt-leaves!
    /// @dev Proof (transferAnchor) needs to be provided from this tree. 
    /// @dev The merkle-tree needs to contain at least one "salt leaf" in order to not publish the complete merkle-tree when all anchors should have been dropped at least once. 
    /// @param merkleRootNode The root, containing all anchors we want validated.
    function updateValidAnchors(bytes32 merkleRootNode) public onlyMaintainer() {
        _validAnchorsMerkleRoot = merkleRootNode;
        emit ValidAnchorsUpdate(merkleRootNode, msg.sender);
    }

    function anchorValid(bytes32 anchor, bytes32[] memory proof) public virtual view returns (bool) {
        return MerkleProof.verify(
            proof,
            _validAnchorsMerkleRoot,
            keccak256(bytes.concat(keccak256(abi.encode(anchor)))));
    }

    function floating(bytes32 anchor) public view returns (bool){
        return _floating(allFloating, floatingStateByAnchor[anchor]);
    }    

    constructor(
        string memory _name, 
        string memory _symbol, 
        AttestationLimitPolicy _limitUpdatePolicy)
        ERC6956(_name, _symbol) {          
            attestationLimitPolicy = _limitUpdatePolicy;

        // Note per default no-one change floatability. canStartFloating and canStopFloating needs to be configured first!        
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC6956)
        returns (bool)
    {
        return
            interfaceId == type(IERC6956AttestationLimited).interfaceId ||
            interfaceId == type(IERC6956Floatable).interfaceId ||
            interfaceId == type(IERC6956ValidAnchors).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}


// File contracts/factory/BaseProvider.sol


pragma solidity ^0.8.18;

/**
 * @title InitArgsProvider, typically implemented by factories
 * @author 
 * @notice  
 */
interface IInitArgsProvider {
    /**
     * @notice Provides initArgs (typically from a factory) for a particular deployed smart-contract address.
     * @dev is called from `ProvidableContract`-constructor at deploy-time. Main reason for this implementation
     *   is that Contracts are deployed via create2, so any constructor-parameter is address defining. This allows 
     *   at deploy time to set additional parameters, which are not address-defining.
     * @param deployedContract Address of the deployed contract requesting initArgs
     * @return initArgs abi-encoded init args
     */
    function getInitArgs(address deployedContract) external view returns (bytes memory initArgs);
}

/**
 * @title ProvidableContract (to be extended by actual contracts)
 * @author [email protected]
 * @notice Abstract ProvidableContract defining the `initialize()` function, which is called at deploy-time, if the deployer implements IInitArgsProvider
 * @dev Any contract deployed through SlimFactory must extend `ProvidableContract`.
 */
abstract contract ProvidableContract {
    /**
     * @notice 
     */
    address public deployedBy;
    /**
     * Returns the Version of X.Y.Z
     * Needs to match `BaseProvider.getVersion()`
     */
    function getVersion() public virtual pure returns (string memory);
    /**
     * @notice Initializer called at deploytime or manually afterwards.
     * @dev MUST ensure it can only be executed once, typically by setting a notInitialized bool and saying require(notInitialized)
     * @param initArgs abi-encoded init args provided by `IInitArgsProvider`
     */
    function initialize(bytes memory initArgs) public virtual;

    /**
     * Stores the deployer-address and - if the deployer supports the IInitArgsProvider interface - requests initArgs and calls `initialize()`
     */
    constructor() {
        // saftey feature, lets people easily verifiy it has been deployed through a trusted factory
        deployedBy = msg.sender; 

        // Callback to the factory
        if(ERC165Checker.supportsInterface(deployedBy, type(IInitArgsProvider).interfaceId)) {
            IInitArgsProvider factory = IInitArgsProvider(msg.sender);
            initialize(factory.getInitArgs(address(this)));  
        }  
    }
}

/**
 * @title BaseProvider (to be extended by actual providers)
 * @author [email protected] 
 * @notice Abstract BaseProvider contract to deliver a `ProvidableContract`, must be extended by actual SlimFactory-Providers 
 * @dev A provider is a contract, which provides the bytecode of a particular `ProvidableContract`, a function to encode deployArgs (constructorArgs) and a function to encode initArgs
 */
abstract contract BaseProvider {
    /**
     * Returns bytecode with constructor args. Needs to be implemented by actual provider contract.abi
     * Typical implementation:
     * ```
     *  bytes memory bytecode = type(DemoContract).creationCode; // DemoContract is ProvidableContract        
     *  return abi.encodePacked(bytecode, args);
     * ```
     */
    function getBytecode(bytes memory args) public virtual pure returns (bytes memory);

    /**
     * Returns the version as string in format X.Y.Z
     * Needs to match `BaseProvider.getVersion()`
     */
    function getVersion() public virtual pure returns (string memory);

    function getVersionHash() public pure returns (bytes32) {
        return keccak256(abi.encode(getVersion()));
    }

    function getDefaultInitArgs() public virtual view returns (bytes memory);

    function getDefaultArgs(address appHub, string memory name, string memory symbol) public virtual view returns (bytes memory);

    // ############################### NOT sure whether to keep the below (currently not used)
    // TODO or remove
    function getBytecodeHash(bytes memory bytecode) public pure returns (bytes32) {
        return keccak256(abi.encode(bytecode, getVersionHash()));
    }

    /**
     * @dev Verifies via hashing that the bytecode is indeed suitable to be deployed with this contract
     * @param byteCode The bytecode, typically the creationCode + args
     * @param byteCodeHash The bytecode hash, computed typically by calling getBytecodeHash() at some point
     */
    function verifyByteCode(bytes memory byteCode, bytes32 byteCodeHash) public virtual pure returns (bool) {
        return byteCodeHash == getBytecodeHash(byteCode);
    }
  }


// File contracts/factory/SlimFactory.sol


pragma solidity ^0.8.18;


/**
 * @title A slim Register+Deploy factory for arbitrary, `ProvidableContract`-extending contracts using create2 deploy mechanism
 * @author [email protected]
 * @notice Two-step factory with create2 requesting bytecode from deployed `BaseProvider`-extending, versioned and potentially incompatible contract templates. 
 * @dev In order to deploy a contract follow these steps
 *    1. Write the `MyContract is ProvidableContract`, lets say with version 1.2.3
 *    2. Write a `MyContractProvider is BaseProvider`, which serves the bytecode of `MyContract` and offers getDeployArgs / getInitArgs functions
 *    3. Deploy `MyContractProvider` with any arbitrary wallet and to any arbitrary address. Note its deployed `providerAddr`
 *    4. Call `SlimFactory.updateProvider(providerAddr)`. The version will be requested from `providerAddr` onchain.
 *    5. Register
 *       5.1. [OPTIONAL] Obtain from MyContractProvider optionally deployArgs = getDeployArgs() and initArgs = getInitArgs()
 *       5.2. Call SlimFactory.register("1.2.3", deployArgs, initArgs). If deployArgs and/or initArgs are not needed, pass empty `bytes memory`. 
 *       5.3. Record the registeredAddress, which is returned from register() as well as emitted via ContractRegistered event.
 *    6. Deploy a previously registered contract via SlimFactory.deploy(registeredAddress)
 */
contract SlimFactory is ERC165, IInitArgsProvider {
    event ContractDeployed(address indexed addr, string version, address deployer);
    event ContractRegistered(address indexed addr, string version, address registrar);
    event ContractUnregistered(address indexed addr, address maintainer);
    event ProviderUpdate(address indexed addr, string indexed version, address maintainer);
    event RegistrarUpdate(address to, bool added, address maintainer);
    event MaintainerUpdate(address to, bool added, address maintainer);
    event DeployerUpdate(address to, bool added, address maintainer);
    event DeploymentSaltUpdate(bytes32 newSalt, bytes32 oldSalt, address maintainer);

    mapping (address => bytes) public deployArgs;
    mapping (address => address) public providerForAddress; // provider by deployment!
    mapping (address => bytes32) public bytecodeHash;
    mapping (bytes32 => address) public addressByBytecodeHash;
    mapping (address => address) public registrarByContract;
    mapping (address => bytes) public initArgsByAddress;
    mapping (string => address) public providerByVersion;
    mapping (bytes32 => string) public versionByVersionHash;
    address public appHubAddress;

    /**
     * Keeps a list of all deployed contracts (in deployment order)
     */
    address[] public deployedContracts;
    /**
     * @notice Backlog of contracts that have been registered but not deployed yet
     */
    mapping (address => bool) public pendingDeployments;
    mapping (address => bool) private _authorizedDeployer;
    mapping (address => bool) private _authorizedMaintainer;
    mapping (address => bool) private _authorizedRegistrar;

    bytes32 private _staticSalt = keccak256("slimFactory");
    
    // https://solidity-by-example.org/app/create2/
    // 2. Compute the address of the contract to be deployed
    // NOTE: _salt is a random number used to create an address
    function getAddress(
        bytes memory bytecode,
        bytes32 _salt
    ) public view returns (address) {
        uint actualSalt = uint(_salt);

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), actualSalt, keccak256(bytecode))
        );

        // NOTE: cast last 20 bytes of hash to address
        return address(uint160(uint(hash)));
    }

    /**
     * @param bytecode Bytecode + packed constructorArgs of contract implementing IDeployedContract
     * @param salt The deployment salt.
     * @dev Isolated function to actually deploy contracts (can be used by extending contracts)
     *      inspired by https://solidity-by-example.org/app/create2/
     *      Salt is taken as parameter to also allow deploying contracts with an "old" salt in case of
     *      emergency salt-upgrade.
     */
    function _deployBinary(bytes memory bytecode, bytes32 salt) internal whenOperational() returns (address) {
        address addr;
        uint actualSalt = uint(salt);
        /*
        NOTE: How to call create2

        create2(v, p, n, s)
        create new contract with code at memory p to p + n
        and send v wei
        and return the new address
        where new address = first 20 bytes of keccak256(0xff + address(this) + s + keccak256(mem[p…(p+n)))
              s = big-endian 256-bit value
        */
        assembly {
            addr := create2(
                callvalue(), // wei sent with current call
                // Actual code starts after skipping the first 32 bytes
                add(bytecode, 0x20),
                mload(bytecode), // Load the size of code contained in the first 32 bytes
                actualSalt // Salt from function arguments
            )

            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }

    /**
     * @notice Updates the deployment salt - do only use in absolut emergencies!
     * @dev This shall not be used at all and is just for emergencies and major fuckups. As soon 
     * as the salt is updated, it can happen that the same contract / same version / same constructorArgs
     * can be re-deployed to a different address. 
     */
    function updateDeploymentSalt(bytes32 newSalt) public onlyMaintainer() whenOperational() {
        emit DeploymentSaltUpdate(_staticSalt, newSalt, msg.sender);
        _staticSalt = newSalt;
    }

    /**
     * @dev Hook called after registration of a new contract. Typically overwritten in extending implementations
     * @param addr Address of the just registered contract
     * @param contractVersion Version of the just registered contract as indicated by provider in format X.Y.Z
     */
    function _afterRegistration(address addr, string memory contractVersion) internal virtual {}

    /**
     * @dev Hook called after deployment of of a registered contract. Typically overwritten in extending implementations
     * @param addr Address of the just registered contract
     * @param contractVersion Version of the just registered contract as indicated by provider in format X.Y.Z
     */
    function _afterDeployment(address addr, string memory contractVersion) internal virtual {}


    /**
     * @notice Unregisters undeployed contracts (undo register(), as long as not deployed)
     * @param toUnregister The address of the contract to unregister
     * @dev Can be called by maintainer or the registrar who registered the particular contract at `toUnregister`-address
     */
    function unregister(address toUnregister) public maintainerOrRegistrar() {

        require(pendingDeployments[toUnregister], "Only registered, not-deployed contracts can be unregistered");
        if(!isAuthorizedMaintainer(msg.sender)) {
            require(registrarByContract[toUnregister] == msg.sender, "Can only unregister own registered contracts");
        }

        _beforeUnregister(toUnregister);

        delete addressByBytecodeHash[bytecodeHash[toUnregister]];
        delete bytecodeHash[toUnregister];
        delete deployArgs[toUnregister];
        delete initArgsByAddress[toUnregister];
        delete pendingDeployments[toUnregister];
        delete registrarByContract[toUnregister];

        emit ContractUnregistered(toUnregister, msg.sender);
    }

    /**
     * @dev Hook called before unregistering a contract - permission to unregister has been verified before calling this function
     */
    function _beforeUnregister(address addrToUnregister) internal virtual {}

    /**
     * @notice Registers a new Contract deployment of contract with version X.Y.Z. Can only be executed by authorized registrars.
     * @dev The returned address is then typically passed into `deploy()` to execute the deployment
     * @param _version The version in format X.Y.Z which should be deployed
     * @param _deployArgs DeployArgs, typically obtained from the BaseProvider-extending contract getDeployArgs(...arbitraryParams ...) 
     * @param _initArgs InitArgs requestable through getInitArgs(), typically obtained from BaseProvider-extending contract getInitArgs(...) or getDefaultInitArgs(...)
     * @return registeredAddress The predicted address, where the contract will be deployed to via `deploy(registeredAddress)`
     */
    function register(string memory _version, bytes memory _deployArgs, bytes memory _initArgs) public onlyRegistrar() whenOperational() returns (address registeredAddress) {    
        address _provider = providerByVersion[_version];

        require(_provider != address(0), "No provider found");
        BaseProvider p = BaseProvider(_provider);
        registeredAddress = getAddress(p.getBytecode(_deployArgs), _staticSalt);

        require(providerForAddress[registeredAddress] == address(0), "Contract already registered");
        registrarByContract[registeredAddress] = msg.sender;

        providerForAddress[registeredAddress] = _provider;

        _beforeRegister(registeredAddress, _version, _deployArgs, _initArgs);

        bytes memory deployArgsWithAppHub =  _deployArgs;

        deployArgs[registeredAddress] = deployArgsWithAppHub;
    
        bytes memory byteCodeForDeployment = p.getBytecode(deployArgsWithAppHub); 
        bytes32 bcHash = p.getBytecodeHash(byteCodeForDeployment);

        require(addressByBytecodeHash[bcHash] == address(0), "Identical bytecode already registered");

        bytecodeHash[registeredAddress] = bcHash;
        addressByBytecodeHash[bcHash] = registeredAddress;

        initArgsByAddress[registeredAddress] = _initArgs;

        pendingDeployments[registeredAddress] = true;        
        emit ContractRegistered(registeredAddress, _version, msg.sender);
        _afterRegistration(registeredAddress,_version);
        return registeredAddress;
    }

    /**
     * @notice Hook called before registering a contract, typically overridden by extending contracts
     */
    function _beforeRegister(address /*_deployment*/, string memory /*_version*/, bytes memory /*_deployArgs*/, bytes memory /*_initArgs*/) internal virtual {}
   
    /**
     * @notice Actually deploys the previously registered contract. Can only be executed by authorized deployers.
     * @dev Note that if you get an "Error: Transaction reverted without a reason string", 
     *      the most likely reason is corrupt init data. Verify init-data is correct!
     *      Also a common error is that the factory is lacking permissions to run initialize()
     *      on the just deployed contract.
     *      Verifies bytecode-integrity to account for potential corroptions between registration and deployment.
     *      This also accounts for cases, where the _staticSalt has changed between registration and deployment.
     *      Further does regression-testing by verifying deployed address matches registered address
     * @param registeredAddress The address as returned from `register()` 
     */
    function deploy(address registeredAddress) public virtual 
        onlyDeployer()
        returns (address)
    {
        BaseProvider p = BaseProvider(providerForAddress[registeredAddress]);
        
        bytes memory argsForDeployment = deployArgs[registeredAddress]; // TODO get from registered Deployments
        bytes memory byteCodeForDeployment = p.getBytecode(argsForDeployment); 

        require(p.verifyByteCode(byteCodeForDeployment, bytecodeHash[registeredAddress]), "Bytecode verification failed, version mismatch?");

        address deployedAddress = _deployBinary(byteCodeForDeployment, _staticSalt);

        require(deployedAddress == registeredAddress, "Predicted and deployed address mismatch");

        ProvidableContract pc = ProvidableContract(deployedAddress);
        delete pendingDeployments[registeredAddress];

        emit ContractDeployed(deployedAddress, pc.getVersion(), msg.sender);
        _afterDeployment(deployedAddress, pc.getVersion());
        return deployedAddress;    
    }

    /**
     * @notice Adds or updates a provider contract. Can only be used by authorized maintainers.
     * @dev Note updating should be avoided, rather increase the the Revision Z in X.Y.Z versioning.
     * @dev The version is determined by calling BaseProvider(_providerAddress).getVersion()
     * @param providerAddress Address of the deployed ProviderContract (which extends BaseProvider)
     */
    function updateProvider(address providerAddress) public onlyMaintainer() {
        BaseProvider bp = BaseProvider(providerAddress);
        string memory _version = bp.getVersion();
        require(providerByVersion[_version] != providerAddress, "No change required");
        emit ProviderUpdate(providerAddress, _version, msg.sender );
        providerByVersion[_version] = providerAddress;
    }

    /**
     * @notice Removes the provider of `version`, i.e. stop supporting this version
     */
    function removeVersion(string memory version) public onlyMaintainer() {
        address provider = providerByVersion[version];
        require(provider != address(0), "Version unknown");
        emit ProviderUpdate(address(0), version, msg.sender);
        delete providerByVersion[version];
    }

    /**
     * @notice Indicates whether a certain version is supported / can be registered and deployed
     * @param version in Format x.y.z
     */
    function versionSupported(string memory version) public view returns (bool) {
        return providerByVersion[version] != address(0);
    }

    /**
     * @notice Returns the init args stored for a contract deployed to `deployedAddress`
     * @dev Typically called (exactly once) from the deployedContract's constructor via BaseProvider-Constructor.
     */
    function getInitArgs(address deployedAddress) public view returns (bytes memory) {
        return initArgsByAddress[deployedAddress];
    }

    // ####################################################### SIMPLE ACCESS CONTROL
    // Overwrite isAuthorized* in extending contracts, e.g. if you want to use 
    // Role-based AccessControl etc.

    /**
     * @notice Indicates that `àccount` is authorized to deploy.
     * @dev Typically overridden in extending contracts when role-based access control shall be used
     */
    function isAuthorizedDeployer(address account) public virtual view returns (bool) {
        return _authorizedDeployer[account];
    }
   
    /**
     * @notice Indicates that `account` is authorized to register and unregister (own) contracts.
     * @dev Typically overridden in extending contracts when role-based access control shall be used
     */
    function isAuthorizedRegistrar(address account) public virtual view returns (bool) {
        return _authorizedRegistrar[account];
    }

    /**
     * @notice Indicates that `account` is authorized to maintain this factory.
     * @dev Typically overridden in extending contracts when role-based access control shall be used
     */
    function isAuthorizedMaintainer(address account) public virtual view returns (bool) {
        return _authorizedMaintainer[account];
    }


    modifier onlyRegistrar() {
        require(isAuthorizedRegistrar(msg.sender), "Authorized Registrar only");
        _;
    }

     modifier onlyDeployer() {
        require(isAuthorizedDeployer(msg.sender), "Authorized Deployer only");
        _;
    }

    modifier onlyMaintainer() {
        require(isAuthorizedMaintainer(msg.sender), "Authorized Maintainer only");
        _;
    }

    modifier maintainerOrRegistrar() {
        require(isAuthorizedMaintainer(msg.sender) || isAuthorizedRegistrar(msg.sender), "msg.sender must be maintainer or registrar");
        _;
    }

    /**
     * This function is typically overwritten when e.g. implementing pausable interface
     */
    function isOperational() public virtual view returns (bool) {
        return true; 
    }

    /**
     * @notice Allows to `add` or remove an `account` as an authorized registrar.
     */
    function updateAuthorizedRegistrar(address account, bool add) public onlyMaintainer() {
        require(_authorizedRegistrar[account] != add, "No change required");
        emit RegistrarUpdate(account, add, msg.sender);
        _authorizedRegistrar[account] = add;
    }

    /**
     * @notice Allows to `add` or remove an `account` as an authorized deployer.
     */
    function updateAuthorizedDeployer(address account, bool add) public onlyMaintainer() {
        require(_authorizedDeployer[account] != add, "No change required");
        emit DeployerUpdate(account, add, msg.sender);
        _authorizedDeployer[account] = add;
    }

    /**
     * @notice Allows to `add` or remove an `account` as an authorized maintainer.
     */
    function updateAuthorizedMaintainer(address account, bool add) public onlyMaintainer() {
        require(_authorizedMaintainer[account] != add, "No change required");
        emit MaintainerUpdate(account, add, msg.sender);
        _authorizedMaintainer[account] = add;
    }   

    modifier whenOperational() {
        require(isOperational(), "Not operational");
        _;
    }

    // ####################################################### ERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IInitArgsProvider).interfaceId
            || super.supportsInterface(interfaceId);
    }

    constructor(address _appHub) {
        _authorizedMaintainer[msg.sender] = true;
        emit MaintainerUpdate(msg.sender, true, msg.sender);
        appHubAddress = _appHub;
    }
  }


// File contracts/MetaAnchor.sol


pragma solidity ^0.8.18;









/// @notice Method, how returned tokenURI() is generated. Either baseURI/tokenId or baseURI/anchor
enum TokenURIMethod {
    /// @dev baseURI/tokenID is used
    TokenId,
    /// @dev baseURI/anchor is used
    Anchor
}


/// @title Meta Anchor (TM) Digital Soul (TM) contract
/// @author [email protected], lm
/// @custom:website https://metaanchor.io
/// @notice A token of this contract anchors digital metadata of a Physical Object to an account.
/// This is achieved by equipping the Physical Object with a Meta Anchor (TM) security tag paired with issuing an ERC-6956 Asset-Bound NFT (ERC-6956). 
/// The token wraps the anchor, with the anchor being a digital representation of the physical Meta Anchor (TM) Security Tag.
/// This makes the digital metadata inseperable from the Physical Object, hence making it its Digital Soul (TM). 
/// The Digital Soul (TM) can only be transferred by transferring the Physical Object.
/// 
/// [Meta Anchor (TM) and Digital Soul (TM) will subsequently be denoted as MetaAnchor and DigitalSoul]
///
/// System description:
/// A user may use a scanning device (smartphone) to trigger the authentication of the MetaAnchor security tag and specify the beneficiary account, where the DigitalSoul shall be anchored.
/// Upon the authenticated presence of the Physical Object through the MetaAnchor technology stack, `dropAnchor` is invoked through the trusted MetaAnchor backend. 
/// An anchor-drop technically issues a token of this contract to a beneficiary account. The token can be resolved to the anchor (representing the physical object) through this contract, i.e. through `anchorByToken`. 
/// Using the well-known `tokenURI()`, the DigitalSoul (metadata) of the Physical Object can be resolved. Note that this contract ensures that each anchor can be dropped (in form of a token) at most once simultanously.
/// In case of a second anchor-drop, the anchor is atomically released from a current holder account and dropped to a beneficiary account in a permissionless manner. Neither the current holder nor the beneficiary need to sign.
/// Such "AnchorTransfer" transactions are authorized by proofing physical presence of the Physical Object comprising a Meta Anchor (TM) security tag at the device defining the beneficiary. This revokes "physical access" of the previous holder to the Physical Object.
/// Metadata is defined via tokenURI() and stored off-chain by the producer/issuer of the Physical Objects. Metadata shall be linked to the anchor (NOT the tokenID!). This can be done by resolving token to anchor either onChain (TokenURI-method "Anchor" or off chain (TokenURI-method "TokenID").
///
/// Contract TLDR;
/// Having the DigitalSoul anchored to an account proves this account has (had) access to the Physical Object.
/// Use dropAnchor() to drop a token representing essentially the Physical Object (or its digital metadata) at a beneficiary account.
/// Subscribe AnchorTransfer Event to track an anchors voyage (as TokenIds change, hence ERC721 Transfer event is of limited use).
/// Use anchorByToken() and tokenByAnchor() to resolve token-ID to anchor and vice versa. Already released anchors can no longer be resolved on-chain.
/// Due to the permissionless nature, gas for transactions is paid through this contract respectively invoking account. Neither current holder nor beneficiary need any funds.
/// Meta Anchor (TM) tokens are technically Consensual Soulbound Tokens according to ERC5484.
/// 
/// Visit https://metaanchor.io for more details
contract MetaAnchor is ERC6956Full, Pausable, Ownable, AppContract, ProvidableContract{
    /// @notice ORACLE_ROLE is an accepted signer for attestations.
    /// @return Role hash, as should be passed to hasRole(), grantRole()
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    /// @notice MINTER_ROLE can call dropAnchor and safeMint(), the latter is not recommended to use directly
    /// @return Role hash, as should be passed to hasRole(), grantRole()
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @notice MINTER_ROLE can call dropAnchor and safeMint(), the latter is not recommended to use directly
    /// @return Role hash, as should be passed to hasRole(), grantRole()
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
   
    string internal _contractUri = "";


    /// @notice Contract version string
    function getVersion() public virtual pure override returns (string memory) {
        return "0.3.0";
    }

    /// @notice Takes identifiying _name and _symbol parameters. updateBaseURI() and maxDropsPerAnchor() shall directly after deployment. 
    /// @dev Typically used via MetaAnchorFactory, which ensures to set default parameters.
    /// @param _hub The address of the AppHub for role management
    /// @param _name The Name of the Contract, usually also the Collection-Name
    /// @param _symbol The symbol for tokens of this contract. In MetaAnchor-language often referred to as CSN (contract short name)
    constructor(address _hub, string memory _name, string memory _symbol, IERC6956AttestationLimited.AttestationLimitPolicy _limitUpdatePolicy)
                ERC6956Full(_name, _symbol, _limitUpdatePolicy) AppContract(_hub) {
        // Better safe than sorry - remove the Deployer (factory) from ERC6956.
        // This is possible, because this constructor is run after all dependent constructors, so also
        // after ERC6956Full-constructor as well as the ProvidableContract-constructor (calling initialize)
        delete maintainers[msg.sender];
    }

    function decodeArgs(bytes memory initArgs) public pure returns 
        (
            IERC6956.Authorization _burnAuthorization,
            IERC6956.Authorization _approveAuthorizaion,
            // IERC6956Floatable
            IERC6956.Authorization _canStartFloatingAuthorization,
            IERC6956.Authorization _canStopFloatingAuthorization,
            // IERC6956AttestationLimited
            uint256 _attestationLimit
        )  {
        (_burnAuthorization, _approveAuthorizaion,
            _canStartFloatingAuthorization, _canStopFloatingAuthorization,
            _attestationLimit
        ) = abi.decode(
            initArgs, (
                IERC6956.Authorization, IERC6956.Authorization,
                IERC6956.Authorization, IERC6956.Authorization,
                uint256
            )
        );

        // implicitely return values
    }


    bool public isInitialized;
    // Will be called with init args received from factory... or can be called manually..
    // Recommended to use the provider and encodeInitArgs (or however i will call the method)
    function initialize(bytes memory initArgs) public virtual override onlyMaintainer() {
        require(!isInitialized, "initialize() can only be called once");
        isInitialized = true;       
        //console.log("Decoding...");

        (
            IERC6956.Authorization _burnAuthorization,
            IERC6956.Authorization _approveAuthorizaion,
            // IERC6956Floatable
            IERC6956.Authorization _canStartFloatingAuthorization,
            IERC6956.Authorization _canStopFloatingAuthorization,
            // IERC6956AttestationLimited
            uint256 _attestationLimit
        ) = decodeArgs(initArgs);

        //console.log("Decoded");


        updateBurnAuthorization(_burnAuthorization);
        updateApproveAuthorization(_approveAuthorizaion);
    
        updateFloatingAuthorization(_canStartFloatingAuthorization, _canStopFloatingAuthorization);
        updateGlobalAttestationLimit(_attestationLimit);
    }

    // ####################################### ERC6956-Overrides for permissions
    function isMaintainer(address a) public virtual view override(ERC6956) returns (bool) {
        // explicitly override the permission system of ERC6956 with AppHub
        return hasRole(MAINTAINER_ROLE, a) || super.isMaintainer(a); 
    }

    /**
     * @notice Declares `oracleAddress` trusted, if it has the `ORACLE_ROLE`
     * @dev Overrides ERC6956 oracle logic, does NOT emit OracleUpdate events, when ORACLE_ROLE is granted via grantRole()
     * 
     * @param oracleAddress Oracle address in question
     * @return isTrusted true, if oracleAddress has ORACLE_ROLE
     */
    function isTrustedOracle(address oracleAddress) public view override(ERC6956) returns (bool isTrusted) {
        return hasRole(ORACLE_ROLE, oracleAddress);
    }

    /**
     * @notice When calling ContractURI, typically json-metadata is returned. Refer e.g. the OpenSea format suggestion
     * @return ContractURI. 
     */
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    /**
     * @notice Pauses the contract. This means among other things that drops/releases are no longer possible.
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * Unpauses the contract / reverts pause().
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // The following functions are overrides required by Solidity, EIP-165.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC6956Full, AppContract)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId);
    }
   
    /// @notice Set a new contractURI. Refer `contractURI` for details.
    /// @param contractUri The token base-URI. Must end with slash '/'.
    function updateContractURI(string calldata contractUri) public onlyRole(MAINTAINER_ROLE) whenNotPaused() {
        _contractUri = contractUri;
    }

    /// @notice Transfers ownership over the contract. The owner has no updating power in this contract, but is returned when calling owner(). 
    /// This allows the owner to act/sign accordinlgy external software applications / marketplaces etc.
    /// The owner can be changed by MAINTAINER_ROLE or the current owner.
    /// @dev Overrides Ownable's function. For MetaAnchor, the MAINTAINER_ROLE can also change ownership. 
    /// Do NOT use onlyOwner modifier in this contract, as this would give power to the owner, which is not desired in our use-case.
    /// @param newOwner The new owner
    function transferOwnership(address newOwner) override public virtual 
        ownerOrMaintainer() whenNotPaused() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner); // Calls the Ownable implementation
    }

    modifier ownerOrMaintainer() {
         require(hasRole(MAINTAINER_ROLE, msg.sender) || msg.sender == owner(), "Caller must be maintainer or owner");
         _;
    }

    // ################################## PAUSABLE
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal virtual
        override(ERC6956Full)
        whenNotPaused()
    {
        // just wrap the function in order to apply whenNotPaused via hook to all transfers 
        // this includes attestation-transfers and normal transfers
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function anchorValid(bytes32 anchor, bytes32[] memory proof) public virtual view override(ERC6956Full) whenNotPaused() returns (bool isValid) {
        return super.anchorValid(anchor, proof);
    }

    function _beforeAttestationUse(bytes32 anchor, address to, bytes memory data) internal view virtual override(ERC6956Full) whenNotPaused() {
        super._beforeAttestationUse(anchor, to, data);
    }

    // Also do not allow to tamper with approval states..
    function _approve(address to, uint256 tokenId) internal virtual override(ERC721) whenNotPaused(){
        super.approve(to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual override(ERC721) whenNotPaused() {
        super._setApprovalForAll(owner, operator, approved);
    }
}


// File contracts/MetaAnchorFactory.sol


pragma solidity ^0.8.18;
/**
 * @title MetaAnchor Factory
 * @author [email protected]
 * @notice Registers and deploys MetaAnchor contracts and lets you verify via `hasDeployed()` 
 * whether contract is an original MetaAnchor contract. Corresponding deployed contracts will have the same address on all EVM-blockchains.
 * @dev A Meta Anchor (TM) contract is identified solely by its symbol. This factory ensures max. one contract per symbol exists.
 * Contracts will deploy to a deterministic address on all EVM-chains, depending solely on (version, deployArgs). 
 * Each MetaAnchor-contract needs to have the following mandatory constructor arguments (in that order): 
 *  (address appHub, string name, string symbol)
 *      - The latter two are passed to ERC-721. 
 *      - The factory ensures at most one registered (and consequently deployed) contract per symbol exists
 * In order to ensure deterministic deployment cross-chain
 *      - The provider registered for a version needs to return the same byteCode on all chains
 *      - deployArgs when registering deployment of a certain version need to be identical
 *      - This factory needs to be deployed to the same address on all chains
 * Also features a mechanism to grant finite numbers of registrations and deployments to arbitrary accounts
 * 
 * Refer documentation of `SlimFactory` or details on the registration/deployment process
 */
contract MetaAnchorFactory is AppContract, SlimFactory, Pausable, IDeployedContract {

    /**
     * Emits when new registrations are granted to an `account`
     * @param account Account, which has been granted `nrAdded` additional registrations
     * @param nrAdded Indicates how many additional registrations have been added to the account
     * @param registrationsLeft Registrations left for the account
     * @param registrationLimit New registration limit for account after adding `nrAdded`
     */
    event RegistrationsGranted(address indexed account, uint256 nrAdded, uint256 registrationsLeft, uint256 registrationLimit);

     /**
     * Emits when new deployments are granted to an `account`
     * @param account Account, which has been granted `nrAdded` additional deployments
     * @param nrAdded Indicates how many additional deployments have been added to the account
     * @param deploymentsLeft Deployments left for the account
     * @param deploymentLimit New deployment limit for account after adding `nrAdded`
     */
    event DeploymentsGranted(address indexed account, uint256 nrAdded, uint256 deploymentsLeft, uint256 deploymentLimit);

    /**
     * @notice DEPLOYER_ROLE is permitted to deploy new contracts
     */
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
    /**
     * @notice MAINTAINER_ROLE corresponds to the permissions of SlimFactory.isMaintainer(), 
     * which can maintain the factory and unregister contracts
     */
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    /**
     * @notice Can add providers, remove registrations etc
     */
    bytes32 public constant FACTORY_MAINTAINER_ROLE = keccak256("FACTORY_MAINTAINER_ROLE");
    /**
     * @notice Can pause the contract
     */
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    /**
     * @notice REGISTRAR_ROLE can register new contracts and unregister own earlier registrations
     */
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    /**
     * @notice Version of this contract
     */
    string public constant version = "0.3.0";

    /**
     * @notice Registration limits per account. Applies only to accounts not granted the REGISTRAR_ROLE
     */
    mapping (address => uint256) public registrationLimit;
    /**
     * @notice Deployment limits per account. Applies only to accounts not granted the DEPLOYER_ROLE
     */
    mapping (address => uint256) public deploymentLimit;
    /**
     * @notice Records the number of active registrations per contract
     */
    mapping (address => uint256) public registrationsByAccount;
    /**
     * @notice Records the number of active deployments per contract
     */
    mapping (address => uint256) public deploymentsByAccount;
    /**
     * @notice Records the deployer account of a specific deployment.
     */
    mapping (address => address) public deployerOf;
    /**
     * @notice Resolves a symbol to the registered contract address 1:1
     */
    mapping (string => address) public contractBySymbol;
    /**
     * @notice Resolves a contract address to the symbol 1:1
     */
    mapping (address => string) public symbolByContract;

    /**
     * @notice IDeployedContract interface, indicates the deployer of this contract
     */
    address public deployedBy;

    /**
     * @notice IDeployedContract interface, indicates whether a contract at `addr` was deployed through this factory
     * @param addr Address of contract in question, typically a MetaAnchor-contract
     */
    function hasDeployed(address addr) public view returns (bool hasDeployedAddr) {
        return deployerOf[addr] != address(0);
    }

    // ################################  Use AppHub-Permissions to overwrite SlimFactory-Authorization mechanics
    /**
     * Indicates that accounts with `FACTORY_MAINTAINER_ROLE` are the only maintainers
     * @param addr Account in question
     */
    function isAuthorizedMaintainer(address addr) public view override returns (bool) {
        return hasRole(FACTORY_MAINTAINER_ROLE, addr);
    }

    /**
     * @notice Indicates whether an account `addr` currently has permissions/capacity to register a contract
     * @param addr Account-address
     */
    function isAuthorizedRegistrar(address addr) public view override returns (bool) {
        return hasRole(REGISTRAR_ROLE, addr) || (registrationsLeft(addr) > 0);
    }

    /**
     * @notice Indicates whether an account `addr` currently has permissions/capacity to deploy a contract
     * @param addr Account-address
     */
    function isAuthorizedDeployer(address addr) public view override returns (bool) {
        return hasRole(DEPLOYER_ROLE, addr) || (deploymentsLeft(addr) > 0);
    }

    /**
     * @dev Hook from Slimfactory. Verifies before registration that the symbol is still available and if App-Hub address matches the one of this factory
     * @param deploymentAddress Address of the registered contract
     * @param _deployArgs ABI-encoded deployment arguments, where the first 3 parameters are (appHubAddress, contractName, contractSymbol)
     */
    function _beforeRegister(address deploymentAddress, string memory /*_version*/, bytes memory _deployArgs, bytes memory /*_initArgs*/) internal virtual override(SlimFactory) {
        (address appHub, , string memory symbol ) = abi.decode(_deployArgs, (address, string, string));
        require(contractBySymbol[symbol] == address(0), "Symbol already taken");
        require(appHub == appHubAddress, "AppHubAddress mismatch");
        
        registrationsByAccount[msg.sender] += 1;
        symbolByContract[deploymentAddress] = symbol;
        contractBySymbol[symbol] = deploymentAddress;
    }

    /**
     * @dev Hook from SlimFactory. Rollback of state-changes made in `_beforeRegister`
     * @param toUnregister Contract that will be unregistered
     */
    function _beforeUnregister(address toUnregister) internal override(SlimFactory) {
        registrationsByAccount[registrarByContract[toUnregister]] -= 1;
        delete contractBySymbol[symbolByContract[toUnregister]];
        delete symbolByContract[toUnregister];
        super._beforeUnregister(toUnregister);
    }

    // ################################## UTILITY for finite-time deployments of foreign accounts
    /**
     * @notice Allows FACTORY_MAINTAINER_ROLEs to grant additional `nrRegistrations` to `account` 
     */
    function grantRegistrations(address account, uint256 nrRegistrations) public onlyRole(FACTORY_MAINTAINER_ROLE) {
        registrationLimit[account] += nrRegistrations;        
        emit RegistrationsGranted(account, nrRegistrations, registrationsLeft(account), registrationLimit[account]);
    }
    
    /**
     * @notice Allows FACTORY_MAINTAINER_ROLEs to grant additional `nrDeployments` to `account` 
     */
    function grantDeployments(address account, uint256 nrDeployments) public onlyRole(FACTORY_MAINTAINER_ROLE) {
        deploymentLimit[account] += nrDeployments;
        emit DeploymentsGranted(account, nrDeployments, deploymentsLeft(account), deploymentLimit[account]);
    }

    /**
     * @notice Indicates how many deployments are left for `account`.
     * @dev Note if account has DEPLOYER_ROLE, it can even deploy registered contracts if this method returns 0
     */
    function deploymentsLeft(address account) public view returns(uint256 nrDeploymentsLeft) {
        uint256 limit = deploymentLimit[account];
        uint256 used = deploymentsByAccount[account];
        if(used > limit) {
            return 0;
        }
        return  limit - used;    }

    /**
     * @notice Indicates how many registrations are left for `account`.
     * @dev Note if account has REGISTRAR_ROLE, it can even register new contracts if this method returns 0
     */
    function registrationsLeft(address account) public view returns(uint256 nrRegistrationsLeft) {
        uint256 limit = registrationLimit[account];
        uint256 used = registrationsByAccount[account];
        if(used > limit) {
            return 0;
        }
        return  limit - used;
    }

    /**
     * @dev Tracks deployment details for stats and deployment permissions
     * @param _deploymentAddr Address of the just-deployed contract
     */
    function _afterDeployment(address _deploymentAddr, string memory /*version*/) internal override(SlimFactory) {
        deploymentsByAccount[msg.sender] += 1;
        deployerOf[_deploymentAddr] = msg.sender;
    }

    /**
     * @notice Registers a new MetaAnchor contract with `version` using default settings. Refer `SlimFactory.deploy()` for further details.
     * @param name Name of the contract (immutable)
     * @param symbol Symbol of the contract (immutable), identifying the MetaAnchor-contract unambigiously
     * @param contractVersion The contract version, which shall be deployed in format X.Y.Z
     */
    function registerWithDefaults(string memory name, string memory symbol, string memory contractVersion) public {
        require(versionSupported(contractVersion), "Requested version not supported");
        BaseProvider bp = BaseProvider(providerByVersion[version]);
        bytes memory constructorArgs = bp.getDefaultArgs(appHubAddress, name, symbol);
        bytes memory initArgs = bp.getDefaultInitArgs();
        register(version, constructorArgs, initArgs);        
    }

    // ################################### ERC-165
    function supportsInterface(bytes4 interfaceId) public view virtual override(AppContract, SlimFactory) returns (bool) {
        return interfaceId == type(IDeployedContract).interfaceId
            || super.supportsInterface(interfaceId);
    }

    // ########################### PAUSABLE
    /**
     * @notice Pauses the contract. 
     * @dev This means among other things that deployments and registrations are no longer possible (via `isOperational`).
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * Unpauses the contract / reverts pause().
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * Only operational, when contract is not paused
     */
    function isOperational() public virtual view override(SlimFactory) returns (bool) {
        return !paused(); 
    }

    constructor(address _hub) AppContract(_hub) SlimFactory(_hub) {
        // Set default parameters for a higher chance that behavior across chains is equal!
        deployedBy = msg.sender;
    }
}