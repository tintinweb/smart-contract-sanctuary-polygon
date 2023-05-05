/**
 *Submitted for verification at polygonscan.com on 2023-05-04
*/

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/security/Pausable.sol


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

// File: CarbonWarUtils.sol


pragma solidity ^0.8.9;



interface ICWARNFT {
    // function _basePlans() external view returns (string memory);
    function safeTransferFrom(address from, address to, uint256 nftid, uint256 amount, bytes memory data) external;
    // function uri(uint256 tokenid) external view returns (string memory);
    function nftDatabyID(
        uint256 nftid
    )
        external
        view
        returns (
            uint256 basePLANid,
            string memory basePLANname,
            uint256 PLANseries
        );
}

interface ICWARTOKEN {
    function mint(address account, address amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IFRACTIONALTOKEN {
    function mint(address account, uint256 id, uint256 basePlanId, uint256 shares) external;
    function burn(address account, uint256 id, uint256 amount) external;
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
}

contract TestCarbonWarUtils is Pausable, AccessControl {
    string public name;
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");
    bytes32 public constant CONFIGURATION_UPDATE_ROLE = keccak256("CONFIGURATION_UPDATE_ROLE");

    event switchedToNoterm(address indexed user, bool isPlanchanged);

    event DebugEvent(address account, uint256 nftid, uint256 stakedTimestamp);

    // userfractiondatas
    // nftid => fractiondetails
    mapping(uint => fractionDetails) public _fractionData;
    struct fractionDetails {
        address fractionedUser;
        uint256 fTokenId;
        uint256 basenftPlan;
        uint256 fractionTimestamp;
        uint256 totalShares;
    }

    // userstakedatas
    // useraddress => nftid => stakedetails
    mapping(address => mapping(uint => stakeDetails)) public _userStakeData;
    mapping(uint => uint) public _stakePeriods;
    struct stakeDetails {
        bool is_fractionalized;
        uint256 amount;
        uint256 baseNFTplanid;
        uint256 stakedTimestamp;
        uint256 planId;
        uint256 lastClaimed;
        uint256 rewardTimestamp;
        uint256 rewards;
    }

    //_commissions
    //nftbaseplanid => stakeplanid => commission
    mapping(uint => mapping(uint => uint)) public _commissions;

    address _cwarTokenAddress;
    address _cwarNftAddress; // Only ERC-1155 NFT Supported!
    address _cwarTokenHoldingAddress;
    address _fractionalTokenAddress;

    uint256 public rewardVestingPeriod = 31536000; //1 year

    constructor(
        address cwarTokenAddress,
        address cwarNftAddress,
        address fractionalTokenAddress,
        address cwarTokenHoldingAddress
    ) {
        name = "CarbonWarUtils";
        _cwarTokenAddress = cwarTokenAddress;
        _cwarNftAddress = cwarNftAddress;
        _fractionalTokenAddress = fractionalTokenAddress;
        _cwarTokenHoldingAddress = cwarTokenHoldingAddress;

        _stakePeriods[1] = 0; //No Term
        _stakePeriods[2] = 31536000; //One Year
        _stakePeriods[3] = 31536000 * 3; //Three Year
        _stakePeriods[4] = 31536000 * 5; //Five Year

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(CLAIMER_ROLE, msg.sender);
        _grantRole(CONFIGURATION_UPDATE_ROLE, msg.sender);

        //NFT 1 - Friend
        _commissions[1][1] = 50000000000000000 * 250; //0.05 * 10**18 * 250;
        _commissions[1][2] = 100000000000000000 * 250; //0.1;
        _commissions[1][3] = 150000000000000000 * 250; //0.15;
        _commissions[1][4] = 200000000000000000 * 250; //0.2;

        //NFT 2 - Companion
        _commissions[2][1] = 125000000000000000 * 250; //0.125;
        _commissions[2][2] = 250000000000000000 * 250; //0.25;
        _commissions[2][3] = 375000000000000000 * 250; //0.375;
        _commissions[2][4] = 500000000000000000 * 250; //0.5;

        //NFT 3 - Explorer
        _commissions[3][1] = 500000000000000000 * 250; //0.5;
        _commissions[3][2] = 1050000000000000000 * 250; //1.05;
        _commissions[3][3] = 1575000000000000000 * 250; //1.575;
        _commissions[3][4] = 2100000000000000000 * 250; //2.1;

        //NFT 4 - Ranger
        _commissions[4][1] = 2500000000000000000 * 250; //2.5;
        _commissions[4][2] = 5500000000000000000 * 250; //5.5;
        _commissions[4][3] = 8250000000000000000 * 250; //8.25;
        _commissions[4][4] = 11000000000000000000 * 250; //11;

        //NFT 5 - Voyager
        _commissions[5][1] = 5000000000000000000 * 250; //5;
        _commissions[5][2] = 11500000000000000000 * 250; //11.5;
        _commissions[5][3] = 17250000000000000000 * 250; //17.25;
        _commissions[5][4] = 23000000000000000000 * 250; //23;

        //NFT 6 - Guide
        _commissions[6][1] = 12500000000000000000 * 250; //12.5;
        _commissions[6][2] = 30000000000000000000 * 250; //30;
        _commissions[6][3] = 45000000000000000000 * 250; //45;
        _commissions[6][4] = 60000000000000000000 * 250; //60;

        //NFT 7 - Master Guide
        _commissions[7][1] = 50000000000000000000 * 250; //50;
        _commissions[7][2] = 125000000000000000000 * 250; //125;
        _commissions[7][3] = 187500000000000000000 * 250; //187.5;
        _commissions[7][4] = 250000000000000000000 * 250; //250;

        //NFT 8 - Pioneer
        _commissions[8][1] = 125000000000000000000 * 250; //125;
        _commissions[8][2] = 375000000000000000000 * 250; //375;
        _commissions[8][3] = 562500000000000000000 * 250; //562.5;
        _commissions[8][4] = 750000000000000000000 * 250; //750;

        //NFT 9 - Legend
        _commissions[9][1] = 500000000000000000000 * 250; //500;
        _commissions[9][2] = 2000000000000000000000 * 250; //2000;
        _commissions[9][3] = 3000000000000000000000 * 250; //3000;
        _commissions[9][4] = 4000000000000000000000 * 250; //4000;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function fractionalizeNFT(uint256 nftid, uint256 totalshares) public {
        require(
            _fractionData[nftid].fractionTimestamp == 0,
            "This nft has already been fractionalized"
        );

        ICWARNFT(_cwarNftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            nftid,
            1,
            ""
        );

        (uint256 basePLANid, , ) = ICWARNFT(_cwarNftAddress).nftDatabyID(nftid);

        _fractionData[nftid] = fractionDetails(
            msg.sender,
            nftid, //id of fractionalised token
            basePLANid, //id of base nft plan
            block.timestamp, //fractionedtime
            totalshares //total no. of shares
        );

        IFRACTIONALTOKEN(_fractionalTokenAddress).mint(msg.sender, nftid, basePLANid, totalshares);
    }

    function defractionalizeNFT(uint256 nftid) public {
        require(
            _fractionData[nftid].fractionTimestamp != 0,
            "This nft has not been fractionalized"
        );
        uint256 sharesOwned = IFRACTIONALTOKEN(_fractionalTokenAddress).balanceOf(msg.sender, nftid);
        uint256 totalShares = _fractionData[nftid].totalShares;
        
        require(sharesOwned == totalShares, "You need all shares of the NFT to defractionalize it");

        IFRACTIONALTOKEN(_fractionalTokenAddress).burn(msg.sender, nftid, totalShares);

        ICWARNFT(_cwarNftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            nftid,
            1,
            ""
        );

        delete _fractionData[nftid];
    }

    function stakeFractionalNFT(uint256 id, uint256 amount, uint256 stakeplanid) public{
        require(
            _fractionData[id].fractionTimestamp != 0,
            "This is not a fractionalized NFT"
        );

        (uint256 basePLANid, , ) = ICWARNFT(_cwarNftAddress).nftDatabyID(id);
        IFRACTIONALTOKEN(_fractionalTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            id,
            amount,
            ""
        );
        uint256 currentTimestamp = block.timestamp;
        stakeDetails storage userData = _userStakeData[msg.sender][id];
        if (userData.stakedTimestamp == 0) {
            // First-time staking
            userData.is_fractionalized = true;
            userData.amount = amount;
            userData.baseNFTplanid = basePLANid;
            userData.stakedTimestamp = currentTimestamp;
            userData.planId = stakeplanid;
            userData.lastClaimed = currentTimestamp;
            userData.rewardTimestamp = currentTimestamp;
            userData.rewards = 0;
        } else {
            // Additional staking
            require(
                userData.planId == stakeplanid,
                "Staking plan should be the same for all stakes"
            );
            // Calculate rewards before updating the stake amount
            uint256 pendingRewards = accumulatedRewards(msg.sender, id);
            userData.amount += amount;
            userData.rewardTimestamp = currentTimestamp;
            userData.rewards += pendingRewards;
        }
    }

    function unstakeFractionalNFT(uint256 id) public {
        require(
            _fractionData[id].fractionTimestamp != 0,
            "This is not a fractionalized NFT"
        );
        require(
            _userStakeData[msg.sender][id].is_fractionalized == true,
            "This Fnft has not been staked"
        );
        uint256 stakedtime = _userStakeData[msg.sender][id].stakedTimestamp;
        uint256 stakedplan = _userStakeData[msg.sender][id].planId;
        uint256 stakedperiod = _stakePeriods[stakedplan];
        require(
            stakedperiod == 0 ||
                ((stakedtime + stakedperiod) < block.timestamp),
            "Stake Period hasn't completed"
        );
        uint256 amount = _userStakeData[msg.sender][id].amount;
        IFRACTIONALTOKEN(_fractionalTokenAddress).safeTransferFrom(
            address(this),
            msg.sender,
            id,
            amount,
            ""
        );
        //release pending rewards and delete
        uint256 rewards = accumulatedRewards(msg.sender, id);
        ICWARTOKEN(_cwarTokenAddress).transferFrom(
            _cwarTokenHoldingAddress,
            msg.sender,
            rewards
        );
        delete _userStakeData[msg.sender][id];
    }

    function forceunstakeFractionalNFT(
        address account,
        uint256 nftid
    ) public onlyRole(ADMIN_ROLE) {
        require(
            _fractionData[nftid].fractionTimestamp != 0,
            "This is not a fractionalized NFT"
        );
        require(
            _userStakeData[account][nftid].is_fractionalized == true,
            "This Fnft has not been staked"
        );
        uint256 amount = _userStakeData[account][nftid].amount;
        IFRACTIONALTOKEN(_fractionalTokenAddress).safeTransferFrom(
            address(this),
            account,
            nftid,
            amount,
            ""
        );
        //release pending rewards and delete
        uint256 rewards = accumulatedRewards(account, nftid);
        ICWARTOKEN(_cwarTokenAddress).transferFrom(
            _cwarTokenHoldingAddress,
            account,
            rewards
        );
        delete _userStakeData[account][nftid];
    }

    function stakeNFT(uint256 nftid, uint256 stakeplanid) public {
        require(
            _fractionData[nftid].fractionTimestamp == 0,
            "This is a fractionalized NFT. Call stakeFractionalNFT"
        );
        require(
            _userStakeData[msg.sender][nftid].stakedTimestamp == 0,
            "This nft has already been staked"
        );
        (uint256 basePLANid, , ) = ICWARNFT(_cwarNftAddress).nftDatabyID(nftid);
        ICWARNFT(_cwarNftAddress).safeTransferFrom(
            msg.sender,
            address(this),
            nftid,
            1,
            ""
        );
        _userStakeData[msg.sender][nftid] = stakeDetails(
            false,
            1,
            basePLANid, //id of base nft
            block.timestamp, //stakedtime
            stakeplanid, //id of staking plan
            block.timestamp, //last claimed time -
            block.timestamp, //lasr reward calculated time - initially setting to staked time
            0 //rewards
        );
    }

    function unstakeNFT(uint256 nftid) public {
        require(
            _fractionData[nftid].fractionTimestamp == 0,
            "This is a fractionalized NFT. Call unstakeFractionalNFT"
        );
        require(
            _userStakeData[msg.sender][nftid].stakedTimestamp != 0,
            "This nft has not been staked"
        );
        uint256 stakedtime = _userStakeData[msg.sender][nftid].stakedTimestamp;
        uint256 stakedplan = _userStakeData[msg.sender][nftid].planId;
        uint256 stakedperiod = _stakePeriods[stakedplan];
        require(
            stakedperiod == 0 ||
                ((stakedtime + stakedperiod) < block.timestamp),
            "Stake Period hasn't completed"
        );
        ICWARNFT(_cwarNftAddress).safeTransferFrom(
            address(this),
            msg.sender,
            nftid,
            1,
            ""
        );
        //release pending rewards and delete
        uint256 rewards = accumulatedRewards(msg.sender, nftid);
        ICWARTOKEN(_cwarTokenAddress).transferFrom(
            _cwarTokenHoldingAddress,
            msg.sender,
            rewards
        );
        delete _userStakeData[msg.sender][nftid];
    }

    function forceUnstakeNFT(
        address account,
        uint256 nftid
    ) public onlyRole(ADMIN_ROLE) {
        emit DebugEvent(account, nftid, _userStakeData[account][nftid].stakedTimestamp);
        require(
            _fractionData[nftid].fractionTimestamp == 0,
            "This is a fractionalized NFT. Call forceunstakeFractionalNFT"
        );
        require(
            _userStakeData[account][nftid].stakedTimestamp != 0,
            "This nft has not been staked"
        );
        ICWARNFT(_cwarNftAddress).safeTransferFrom(
            address(this),
            account,
            nftid,
            1,
            ""
        );
        //release pending rewards and delete
        uint256 rewards = accumulatedRewards(msg.sender, nftid);
        ICWARTOKEN(_cwarTokenAddress).transferFrom(
            _cwarTokenHoldingAddress,
            msg.sender,
            rewards
        );
        delete _userStakeData[account][nftid];
    }

    function changeStakedPlan(
        address account,
        uint256 nftid,
        uint256 newstakeplan
    ) public onlyRole(ADMIN_ROLE) {
        stakeDetails storage userData = _userStakeData[account][nftid];
        require(
            userData.stakedTimestamp != 0,
            "This nft has not been staked"
        );
        uint256 pendingRewards = accumulatedRewards(account, nftid);
        userData.rewardTimestamp = block.timestamp;
        userData.planId = newstakeplan;
        userData.rewards += pendingRewards;
    }

    function calculateReward(
        address account,
        uint256 nftid
    ) private view returns (uint) {
        stakeDetails storage userData = _userStakeData[account][nftid];

        uint256 rewardtimestamp = userData.rewardTimestamp;
        uint256 pendingrewards = userData.rewards;

        uint256 currentreward = (userData.lastClaimed + rewardVestingPeriod - rewardtimestamp) *
            (_commissions[userData.baseNFTplanid][userData.planId] / (365 * 24 * 60 * 60));

        if (userData.is_fractionalized) {
            uint256 totalShares = _fractionData[nftid].totalShares;
            currentreward = (currentreward * userData.amount) / totalShares;
        }

        return pendingrewards + currentreward;
    }

    function calculateRewardSpecial(
        address account,
        uint256 nftid,
        uint256 new_planid
    ) private view returns (uint) {
        stakeDetails storage userData = _userStakeData[account][nftid];
        uint256 rewardtimestamp = userData.rewardTimestamp;
        uint256 stakedtime = userData.stakedTimestamp;
        uint256 stakedperiod = _stakePeriods[userData.planId];
        uint256 pendingrewards = userData.rewards;

        uint256 orgreward = ((stakedtime + stakedperiod) - rewardtimestamp) *
            (_commissions[userData.baseNFTplanid][userData.planId] / (365 * 24 * 60 * 60));
        uint256 newreward = (block.timestamp - (stakedtime + stakedperiod)) *
            (_commissions[userData.baseNFTplanid][new_planid] / (365 * 24 * 60 * 60));

        uint256 totalRewards = orgreward + newreward;

        if (userData.is_fractionalized) {
            uint256 totalShares = _fractionData[nftid].totalShares;
            totalRewards = (totalRewards * userData.amount) / totalShares;
        }

        return pendingrewards + totalRewards;
    }

    function claimReward(address account, uint256 nftid) public {
        require(
            hasRole(CLAIMER_ROLE, msg.sender),
            "Caller does not have claim privilege"
        );
        stakeDetails storage userData = _userStakeData[account][nftid];
        require(
            userData.stakedTimestamp != 0,
            "This nft has not been staked"
        );

        uint256 stakedperiod = _stakePeriods[userData.planId];
        uint256 rewards;

        bool isSwitched;

        if (stakedperiod == 0) {
            rewards = accumulatedRewards(account, nftid);
            userData.rewardTimestamp = block.timestamp;
            userData.lastClaimed = block.timestamp;
            userData.rewards = 0;
        } else {
            uint256 vestingtime = userData.lastClaimed + rewardVestingPeriod;
            require(
                vestingtime < block.timestamp,
                "Rewards vesting period has not been completed."
            );
            if ((userData.stakedTimestamp + stakedperiod) < block.timestamp) {
                //staking period completed - switch to no term staking
                uint256 noterm_planid = 1;
                rewards = calculateRewardSpecial(account, nftid, noterm_planid);

                userData.planId = noterm_planid;
                isSwitched = true;
                userData.rewardTimestamp = block.timestamp;
                userData.lastClaimed = block.timestamp;
                userData.rewards = 0;
            } else {
                rewards = calculateReward(account, nftid);
                userData.rewardTimestamp = vestingtime;
                userData.lastClaimed = vestingtime;
                userData.rewards = 0;
            }
        }

        ICWARTOKEN(_cwarTokenAddress).transferFrom(
            _cwarTokenHoldingAddress,
            account,
            rewards
        );
        emit switchedToNoterm(account, isSwitched);
    }

    function accumulatedRewards(
        address account,
        uint256 nftid
    ) public view returns (uint) {
        stakeDetails storage userData = _userStakeData[account][nftid];
        require(
            userData.stakedTimestamp != 0,
            "This nft has not been staked"
        );

        uint256 rewardtimestamp = userData.rewardTimestamp;
        uint256 pendingrewards = userData.rewards;
        uint256 currentreward = (block.timestamp - rewardtimestamp) *
            (_commissions[userData.baseNFTplanid][userData.planId] / (365 * 24 * 60 * 60));

        if (userData.is_fractionalized) {
            uint256 totalShares = _fractionData[nftid].totalShares;
            currentreward = (currentreward * userData.amount) / totalShares;
        }

        return pendingrewards + currentreward;
    }

    function changeCWARtokenAddress(
        address newAddress
    ) public onlyRole(CONFIGURATION_UPDATE_ROLE) {
        _cwarTokenAddress = newAddress;
    }

    function changeCWARnftAddress(
        address newAddress
    ) public onlyRole(CONFIGURATION_UPDATE_ROLE) {
        _cwarNftAddress = newAddress;
    }

    function changeCWARtokenHoldingAddress(
        address newAddress
    ) public onlyRole(CONFIGURATION_UPDATE_ROLE) {
        _cwarTokenHoldingAddress = newAddress;
    }

    function changeVestingPeriod(
        uint256 newVestingPeriodinSec
    ) public onlyRole(CONFIGURATION_UPDATE_ROLE) {
        rewardVestingPeriod = newVestingPeriodinSec;
    }

    function changeOrAddStakePeriod(
        uint256 planId,
        uint256 newPlanPeriodinSec
    ) public onlyRole(CONFIGURATION_UPDATE_ROLE) {
        _stakePeriods[planId] = newPlanPeriodinSec;
    }

    function changeOrAddCommissions(
        uint256 nftBaseplanId,
        uint256 stakePlanId,
        uint256 newCommission
    ) public onlyRole(CONFIGURATION_UPDATE_ROLE) {
        _commissions[nftBaseplanId][stakePlanId] = newCommission;
    }

    // required function to allow receiving ERC-1155
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }
}