/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

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


// File base64-sol/[email protected]


pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}


// File contracts/TicketSVGRenderer.sol

pragma solidity ^0.8.9;

// import {PockyCollections} from './PockyCollections.sol';

library TicketSVGRenderer {
  string public constant NBA_HEADER =
    '<svg width="848" height="848" viewBox="0 0 848 848" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><defs><style>@font-face { font-family: "NBA"; src: url("https://static.duckee.xyz/NBA-Pacers.woff2"); }.ta { font: bold 80px Arial; fill: white; letter-spacing: -0.03em; }.ta2 { font-size: 18px; fill: black; } .ta3 { font-size: 24px; fill: black; } .tn { font: 47px NBA, sans-serif; letter-spacing: -0.03em; fill: white; }.tn2 { fill: #828282; font-size: 24px; } .tn3 { fill: #646464; font-size: 24px; }</style><pattern id="nbalogo" patternContentUnits="objectBoundingBox" width="1" height="1"><use xlink:href="#inba" transform="scale(0.0026178 0.00152439)" /></pattern><clipPath id="cb"><rect width="848" height="848" fill="white" /></clipPath><image id="inba" width="382" height="656" xlink:href="https://static.duckee.xyz/nba.png" /></defs><g clip-path="url(#cb)"><path d="M24 0H535C535 17.6731 549.327 32 567 32V816C549.327 816 535 830.327 535 848H24V0Z" fill="#F3F3F3" /><path d="M16 0.5L239.5 0.5L239.5 847.5H16C7.43959 847.5 0.5 840.56 0.5 832L0.5 16C0.5 7.43957 7.43959 0.5 16 0.5Z" fill="black" stroke="#F5F5F5" /><rect x="24" y="494" width="191" height="328" fill="url(#nbalogo)" /><path d="M567 35L567 813" stroke="#CECECE" stroke-width="3" stroke-linecap="round" stroke-dasharray="40 40" /><path d="M599 -0.000976562C599 17.6721 584.673 31.999 567 31.999V815.999C584.673 815.999 599 830.326 599 847.999H832C840.837 847.999 848 840.836 848 831.999V15.999C848 7.16247 840.837 -0.000976562 832 -0.000976562H599Z" fill="#F5F5F5" /><line x1="567" y1="283.999" x2="848" y2="283.999" stroke="white" stroke-width="2" /><circle cx="708" cy="284.999" r="56" transform="rotate(-90 708 284.999)" stroke="white" stroke-width="2" /><circle cx="704" cy="455.999" r="50" transform="rotate(-90 704 455.999)" stroke="white" stroke-width="2" /><path d="M693.239 602.009L693.172 602H693.104H599L599 494C599 433.801 647.801 385 708 385C768.199 385 817 433.801 817 494V602H722.896H722.828L722.761 602.009C717.935 602.662 713.007 603 708 603C702.993 603 698.065 602.662 693.239 602.009Z" stroke="white" stroke-width="2" /><path d="M722.761 -32.009L722.828 -32L722.896 -32L817 -32L817 76C817 136.199 768.199 185 708 185C647.801 185 599 136.199 599 76L599 -32L693.104 -32L693.172 -32L693.239 -32.009C698.065 -32.6625 702.993 -33 708 -33C713.007 -33 717.935 -32.6625 722.761 -32.009Z" stroke="white" stroke-width="2" /><rect x="654" y="601.999" width="145" height="100" transform="rotate(-90 654 601.999)" stroke="white" stroke-width="2" /><rect x="654" y="118.999" width="118" height="100" transform="rotate(-90 654 118.999)" stroke="white" stroke-width="2" /><circle cx="704" cy="113.999" r="50" transform="rotate(90 704 113.999)" stroke="white" stroke-width="2" /><path d="M567 35L567 813" stroke="#CECECE" stroke-width="3" stroke-linecap="round" stroke-dasharray="40 40" /><rect x="771" width="46" height="240" fill="#E73325" /><rect x="714" width="46" height="198" fill="#E73325"/><text transform="translate(718 189) rotate(-90)" class="tn"><tspan x="0.430511" y="37.694">2023 NBA</tspan></text><text transform="translate(775 231) rotate(-90)" class="tn"><tspan x="0.565628" y="37.694">GAME TICKET</tspan></text>';
  string public constant NBA_FOOTER = '</g></svg>';

  function renderSVG(PockyCollections.Collection memory collection) public pure returns (string memory svg) {
    if (collection.updated) {
      return renderResultNbaTicket(collection);
    }
    return renderUpcomingNbaTicket(collection);
  }

  function renderUpcomingNbaTicket(
    PockyCollections.Collection memory collection
  ) internal pure returns (string memory svg) {
    return
      string(
        abi.encodePacked(
          NBA_HEADER,
          renderMatchScoreline(collection, 'Upcoming'),
          renderMatchInfo(collection),
          renderBackground(collection, false),
          NBA_FOOTER
        )
      );
  }

  function renderResultNbaTicket(
    PockyCollections.Collection memory collection
  ) internal pure returns (string memory svg) {
    return
      string(
        abi.encodePacked(
          NBA_HEADER,
          renderMatchScoreline(collection, 'Result'),
          renderMatchInfo(collection),
          renderBackground(collection, true),
          renderResultForm(56, collection.ticketSvgMetadata.homeTeamLogo, collection.ticketSvgMetadata.homeTeamName),
          renderResultForm(477, collection.ticketSvgMetadata.awayTeamLogo, collection.ticketSvgMetadata.awayTeamName),
          renderHomeStats(collection),
          renderAwayStats(collection),
          NBA_FOOTER
        )
      );
  }

  function renderMatchScoreline(
    PockyCollections.Collection memory collection,
    string memory matchStatus
  ) internal pure returns (string memory svg) {
    return
      string(
        abi.encodePacked(
          '<text transform="translate(24 60)" fill="#828282" font-family="NBA" font-size="36">',
          matchStatus,
          '</text><text transform="translate(20 80)" class="ta"><tspan x="0" y="73.7344">',
          collection.ticketSvgMetadata.homeTeamSymbol,
          '</tspan></text><text transform="translate(20 172)" class="ta"><tspan x="0" y="73.7344">',
          collection.eventResult.homeScore,
          '</tspan></text><text transform="translate(20 284)" class="ta"><tspan x="0" y="73.7344">',
          collection.ticketSvgMetadata.awayTeamSymbol,
          '</tspan></text><text transform="translate(20 376)" class="ta"><tspan x="0" y="73.7344">',
          collection.eventResult.awayScore,
          '</tspan></text>'
        )
      );
  }

  function renderMatchInfo(PockyCollections.Collection memory collection) internal pure returns (string memory svg) {
    return
      string(
        abi.encodePacked(
          '<text transform="translate(607 556) rotate(-90)" class="tn tn2"><tspan x="0" y="19.248">DATE</tspan></text><text transform="translate(775.5 556) rotate(-90)" class="ta ta2"><tspan x="0" y="16.7402">',
          collection.ticketSvgMetadata.locationLine1,
          '</tspan><tspan x="0" y="40">',
          collection.ticketSvgMetadata.locationLine2,
          '</tspan></text><text transform="translate(743 556) rotate(-90)" class="tn tn2"><tspan x="0" y="19.248">LOCATION</tspan></text><text transform="translate(639 556) rotate(-90)" class="ta ta2"><tspan x="0" y="16.7402">',
          collection.ticketSvgMetadata.dateLine1,
          '</tspan><tspan x="0" y="40">',
          collection.ticketSvgMetadata.dateLine2,
          '</tspan></text>',
          renderSquareImage('602', '592', '215', collection.ticketSvgMetadata.qrCodeUrl)
        )
      );
  }

  function renderBackground(
    PockyCollections.Collection memory collection,
    bool transparent
  ) internal pure returns (string memory svg) {
    string memory images = string(
      abi.encodePacked(
        renderSquareImage('256', '66', '295', collection.ticketSvgMetadata.homeTeamLogo),
        renderSquareImage('256', '487', '295', collection.ticketSvgMetadata.awayTeamLogo)
      )
    );
    if (transparent) {
      return string(abi.encodePacked('<g opacity="0.07">', images, '</g>'));
    }
    return images;
  }

  function renderResultForm(
    uint256 baseY,
    string memory logo,
    string memory name
  ) internal pure returns (string memory svg) {
    string memory nameY = Strings.toString(baseY + 9);
    string memory headingY = Strings.toString(baseY + 72);
    return
      string(
        abi.encodePacked(
          renderSquareImage('264', Strings.toString(baseY), '48', logo),
          '<text transform="translate(324 ',
          nameY,
          ')" class="ta ta3"><tspan x="0" y="22.3203">',
          name,
          '</tspan></text><text transform="translate(264 ',
          headingY,
          ')" class="tn tn3"><tspan x="0" y="19.248">FIELD GOALS MADE</tspan><tspan x="0" y="61.248">FIELD GOALS PCT</tspan><tspan x="0" y="103.248">3 POINTS MADE</tspan><tspan x="0" y="145.248">3 POINTS PCT</tspan><tspan x="0" y="187.248">FREE THROWS MADE</tspan><tspan x="0" y="229.248">FREE THROWS PCT</tspan></text>'
        )
      );
  }

  function renderHomeStats(PockyCollections.Collection memory collection) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<text transform="translate(453 126)" class="ta ta3"><tspan x="0" y="20">',
          collection.eventResult.homeFGM,
          '</tspan><tspan x="0" y="62">',
          collection.eventResult.homeFGP,
          '</tspan><tspan x="0" y="104">',
          collection.eventResult.homeTPM,
          '</tspan><tspan x="0" y="146">',
          collection.eventResult.homeTPP,
          '</tspan><tspan x="0" y="188">',
          collection.eventResult.homeFTM,
          '</tspan><tspan x="0" y="230">',
          collection.eventResult.homeFTP,
          '</tspan></text>'
        )
      );
  }

    function renderAwayStats(PockyCollections.Collection memory collection) internal pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          '<text transform="translate(453 549)" class="ta ta3"><tspan x="0" y="20">',
          collection.eventResult.awayFGM,
          '</tspan><tspan x="0" y="62">',
          collection.eventResult.awayFGP,
          '</tspan><tspan x="0" y="104">',
          collection.eventResult.awayTPM,
          '</tspan><tspan x="0" y="146">',
          collection.eventResult.awayTPP,
          '</tspan><tspan x="0" y="188">',
          collection.eventResult.awayFTM,
          '</tspan><tspan x="0" y="230">',
          collection.eventResult.awayFTP,
          '</tspan></text>'
        )
      );
  }

  function renderSquareImage(
    string memory x,
    string memory y,
    string memory size,
    string memory href
  ) internal pure returns (string memory svg) {
    return
      string(
        abi.encodePacked(
          '<image x="',
          x,
          '" y="',
          y,
          '" width="',
          size,
          '" height="',
          size,
          '" preserveAspectRatio="xMidYMid slice" href="',
          href,
          '"/>'
        )
      );
  }
}


// File contracts/PockyCollections.sol

pragma solidity ^0.8.9;



/**
 * @dev A module manages the collection data (i.e. metadata shared across tickets for an event),
 * and renders a OpenSea-compliant ERC721 metadata for each tokens.
 * A metadata can be updated by Chainlink oracle (API Consumer), for example, for updating the event result.
 *
 * The frontend app should use it for serving available drops/collections.
 */
contract PockyCollections is AccessControl {
  /** @dev REGISTRAR_ROLE is admin user, who can register a collection. */
  bytes32 public constant REGISTRAR_ROLE = keccak256('REGISTRAR_ROLE');

  /** @dev RESULT_ORACLE_ROLE is given to Chainlink Oracle, who can update the `eventResult` of a collection. */
  bytes32 public constant RESULT_ORACLE_ROLE = keccak256('RESULT_ORACLE_ROLE');

  struct Collection {
    // —————— basic information
    /** The event name. */
    string name;
    /** ticket price */
    uint256 priceInETH;
    /** the collection owner. only the owner can withdraw the revenue */
    address owner;
    /** the maximum count (mint cap) of tickets per a collection */
    uint256 maxSupply;
    // —————— date-related fields
    // NOTE: time-sensitive sections such as Now, Upcoming should be categorized in
    // the frontend by parsing startDate / endDate. Here are the cases:
    // - Now: startDate <= Date.now() < endDate
    // - Upcoming: Date.now() > startDate
    // - Past (hidden): Date.now() >= endDate

    /** start date, in POSIX time (millis) */
    uint256 startDate;
    /** end date, in POSIX time (millis) */
    uint256 endDate;
    /** YYYYMMDD */
    string matchDate;
    // —————— metadata

    TicketSVGMetadata ticketSvgMetadata;
    /** The summary of the location where the event held. shown in ticket image */
    string eventLocation;
    /** Multi-line description shown in the detail page */
    string description;
    /** Banner image URL. */
    string imageUrl;
    /** Should be listed in the top of the main page? */
    bool featured;
    // —————— result-related fields
    /** Whether the result is updated. */
    bool updated;
    /** The updated result (by Chainlink oracle) */
    OracleResult eventResult;
  }

  struct TicketSVGMetadata {
    // home team info
    string homeTeamName;
    string homeTeamSymbol;
    string homeTeamLogo;
    string homeTeamColor;
    // away team info
    string awayTeamName;
    string awayTeamSymbol;
    string awayTeamLogo;
    string awayTeamColor;
    /** QR Code URL. `https://pocky.deno.dev/api/qrcode/${collectionId}` */
    string qrCodeUrl;
    /** Only the day of week, in uppercase. e.g. `"WEDNESDAY,"` */
    string dateLine1;
    /** rest of the date, in uppercase. e.g. `"OCTOBER 20 PM 7:00"` */
    string dateLine2;
    /** Only the first comma, in uppercase. e.g. `"TD GARDEN,"` */
    string locationLine1;
    /** rest of the date, in uppercase. e.g. `"100 Legends Way, Boston, MA"` */
    string locationLine2;
  }

  struct OracleResult {
    string homeScore;
    string homeFGM;
    string homeFGP;
    string homeTPM;
    string homeTPP;
    string homeFTM;
    string homeFTP;
    string awayScore;
    string awayFGM;
    string awayFGP;
    string awayTPM;
    string awayTPP;
    string awayFTM;
    string awayFTP;
  }

  Collection[] private _collections;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(REGISTRAR_ROLE, msg.sender);
    _setupRole(RESULT_ORACLE_ROLE, msg.sender);
  }

  /**
   * @dev Registers a new collection. Should have {@link REGISTRAR_ROLE}.
   * @param collection The collection data.
   */
  function register(Collection calldata collection) external onlyRole(REGISTRAR_ROLE) {
    _collections.push(collection);
  }

  /** @dev returns whether the collectionId exists. */
  function exists(uint256 collectionId) public view returns (bool) {
    return bytes(_collections[collectionId].name).length > 0;
  }

  /** @dev returns the collection data for given ID. */
  function get(uint256 collectionId) external view returns (Collection memory) {
    require(exists(collectionId), 'collection does not exist');
    return _collections[collectionId];
  }

  /**
   * @dev The entire collection data.
   * The frontend app should use this method for listing collections in the main page.
   */
  function list() external view returns (Collection[] memory) {
    return _collections;
  }

  /**
   * @dev Updates a event result of a collection. Should have {@link RESULT_ORACLE_ROLE} (i.e. Oracle!)
   * @notice This function is called by Chainlink Oracle.
   * @param collectionId The collection you want to update
   * @param result The event result
   */
  function updateResult(uint256 collectionId, OracleResult calldata result) external onlyRole(RESULT_ORACLE_ROLE) {
    require(exists(collectionId), 'collection does not exist');
    _collections[collectionId].eventResult = result;
    _collections[collectionId].updated = true;
  }

  /**
   * @dev Generates a OpenSea-compliant ERC721 metadata for a token.
   *
   * @param collectionId the collection ID
   */
  function constructTokenURIOf(uint256 collectionId) external view returns (string memory) {
    Collection storage collection = _collections[collectionId];
    string memory image = Base64.encode(bytes(TicketSVGRenderer.renderSVG(collection)));
    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                collection.name,
                ' - Pocky dNFT Ticket", "description":"',
                collection.description,
                '", "animation_url": "https://pocky.deno.dev/render?svg=',
                image,
                '"}'
              )
            )
          )
        )
      );
  }

  function svgOf(uint256 collectionId) public view returns (string memory) {
    Collection storage collection = _collections[collectionId];
    return TicketSVGRenderer.renderSVG(collection);
  }
}