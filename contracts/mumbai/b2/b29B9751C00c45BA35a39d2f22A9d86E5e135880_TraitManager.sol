// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* 
Hitchens Order Statistics Tree v0.99

A Solidity Red-Black Tree library to store and maintain a sorted data
structure in a Red-Black binary search tree, with O(log 2n) insert, remove
and search time (and gas, approximately)

https://github.com/rob-Hitchens/OrderStatisticsTree

Copyright (c) Rob Hitchens. the MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Significant portions from BokkyPooBahsRedBlackTreeLibrary, 
https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary

THIS SOFTWARE IS NOT TESTED OR AUDITED. DO NOT USE FOR PRODUCTION.
*/

library HitchensOrderStatisticsTreeLib {
  uint256 private constant EMPTY = 0;
  struct Node {
    uint256 parent;
    uint256 left;
    uint256 right;
    bool red;
    bytes32[] keys;
    mapping(bytes32 => uint256) keyMap;
    uint256 count;
  }
  struct Tree {
    uint256 root;
    mapping(uint256 => Node) nodes;
  }

  function first(Tree storage self) internal view returns (uint256 _value) {
    _value = self.root;
    if (_value == EMPTY) return 0;
    while (self.nodes[_value].left != EMPTY) {
      _value = self.nodes[_value].left;
    }
  }

  function last(Tree storage self) internal view returns (uint256 _value) {
    _value = self.root;
    if (_value == EMPTY) return 0;
    while (self.nodes[_value].right != EMPTY) {
      _value = self.nodes[_value].right;
    }
  }

  function next(Tree storage self, uint256 value)
    internal
    view
    returns (uint256 _cursor)
  {
    require(
      value != EMPTY,
      "OrderStatisticsTree(401) - Starting value cannot be zero"
    );
    if (self.nodes[value].right != EMPTY) {
      _cursor = treeMinimum(self, self.nodes[value].right);
    } else {
      _cursor = self.nodes[value].parent;
      while (_cursor != EMPTY && value == self.nodes[_cursor].right) {
        value = _cursor;
        _cursor = self.nodes[_cursor].parent;
      }
    }
  }

  function prev(Tree storage self, uint256 value)
    internal
    view
    returns (uint256 _cursor)
  {
    require(
      value != EMPTY,
      "OrderStatisticsTree(402) - Starting value cannot be zero"
    );
    if (self.nodes[value].left != EMPTY) {
      _cursor = treeMaximum(self, self.nodes[value].left);
    } else {
      _cursor = self.nodes[value].parent;
      while (_cursor != EMPTY && value == self.nodes[_cursor].left) {
        value = _cursor;
        _cursor = self.nodes[_cursor].parent;
      }
    }
  }

  function exists(Tree storage self, uint256 value)
    internal
    view
    returns (bool _exists)
  {
    if (value == EMPTY) return false;
    if (value == self.root) return true;
    if (self.nodes[value].parent != EMPTY) return true;
    return false;
  }

  function keyExists(
    Tree storage self,
    bytes32 key,
    uint256 value
  ) internal view returns (bool _exists) {
    if (!exists(self, value)) return false;
    return self.nodes[value].keys[self.nodes[value].keyMap[key]] == key;
  }

  function getNode(Tree storage self, uint256 value)
    internal
    view
    returns (
      uint256 _parent,
      uint256 _left,
      uint256 _right,
      bool _red,
      uint256 keyCount,
      uint256 count
    )
  {
    require(
      exists(self, value),
      "OrderStatisticsTree(403) - Value does not exist."
    );
    Node storage gn = self.nodes[value];
    return (
      gn.parent,
      gn.left,
      gn.right,
      gn.red,
      gn.keys.length,
      gn.keys.length + gn.count
    );
  }

  function getNodeCount(Tree storage self, uint256 value)
    internal
    view
    returns (uint256 count)
  {
    Node storage gn = self.nodes[value];
    return gn.keys.length + gn.count;
  }

  function valueKeyAtIndex(
    Tree storage self,
    uint256 value,
    uint256 index
  ) internal view returns (bytes32 _key) {
    require(
      exists(self, value),
      "OrderStatisticsTree(404) - Value does not exist."
    );
    return self.nodes[value].keys[index];
  }

  function count(Tree storage self) internal view returns (uint256 _count) {
    return getNodeCount(self, self.root);
  }

  function percentile(Tree storage self, uint256 value)
    internal
    view
    returns (uint256 _percentile)
  {
    uint256 denominator = count(self);
    uint256 numerator = rank(self, value);
    _percentile =
      ((uint256(1000) * numerator) / denominator + (uint256(5))) /
      uint256(10);
  }

  function permil(Tree storage self, uint256 value)
    internal
    view
    returns (uint256 _permil)
  {
    uint256 denominator = count(self);
    uint256 numerator = rank(self, value);
    _permil =
      ((uint256(10000) * numerator) / denominator + (uint256(5))) /
      uint256(10);
  }

  function atPercentile(Tree storage self, uint256 _percentile)
    internal
    view
    returns (uint256 _value)
  {
    uint256 findRank = (((_percentile * count(self)) / uint256(10)) +
      uint256(5)) / uint256(10);
    return atRank(self, findRank);
  }

  function atPermil(Tree storage self, uint256 _permil)
    internal
    view
    returns (uint256 _value)
  {
    uint256 findRank = (((_permil * count(self)) / uint256(100)) + uint256(5)) /
      uint256(10);
    return atRank(self, findRank);
  }

  function median(Tree storage self) internal view returns (uint256 value) {
    return atPercentile(self, 50);
  }

  function below(Tree storage self, uint256 value)
    public
    view
    returns (uint256 _below)
  {
    if (count(self) > 0 && value > 0) _below = rank(self, value) - uint256(1);
  }

  function above(Tree storage self, uint256 value)
    public
    view
    returns (uint256 _above)
  {
    if (count(self) > 0) _above = count(self) - rank(self, value);
  }

  function rank(Tree storage self, uint256 value)
    internal
    view
    returns (uint256 _rank)
  {
    if (count(self) > 0) {
      bool finished;
      uint256 cursor = self.root;
      Node storage c = self.nodes[cursor];
      uint256 smaller = getNodeCount(self, c.left);
      while (!finished) {
        uint256 keyCount = c.keys.length;
        if (cursor == value) {
          finished = true;
        } else {
          if (cursor < value) {
            cursor = c.right;
            c = self.nodes[cursor];
            smaller += keyCount + getNodeCount(self, c.left);
          } else {
            cursor = c.left;
            c = self.nodes[cursor];
            smaller -= (keyCount + getNodeCount(self, c.right));
          }
        }
        if (!exists(self, cursor)) {
          finished = true;
        }
      }
      return smaller + 1;
    }
  }

  function atRank(Tree storage self, uint256 _rank)
    internal
    view
    returns (uint256 _value)
  {
    bool finished;
    uint256 cursor = self.root;
    Node storage c = self.nodes[cursor];
    uint256 smaller = getNodeCount(self, c.left);
    while (!finished) {
      _value = cursor;
      c = self.nodes[cursor];
      uint256 keyCount = c.keys.length;
      if (smaller + 1 >= _rank && smaller + keyCount <= _rank) {
        _value = cursor;
        finished = true;
      } else {
        if (smaller + keyCount <= _rank) {
          cursor = c.right;
          c = self.nodes[cursor];
          smaller += keyCount + getNodeCount(self, c.left);
        } else {
          cursor = c.left;
          c = self.nodes[cursor];
          smaller -= (keyCount + getNodeCount(self, c.right));
        }
      }
      if (!exists(self, cursor)) {
        finished = true;
      }
    }
  }

  function insert(
    Tree storage self,
    bytes32 key,
    uint256 value
  ) internal {
    require(
      value != EMPTY,
      "OrderStatisticsTree(405) - Value to insert cannot be zero"
    );
    require(
      !keyExists(self, key, value),
      "OrderStatisticsTree(406) - Value and Key pair exists. Cannot be inserted again."
    );
    uint256 cursor;
    uint256 probe = self.root;
    while (probe != EMPTY) {
      cursor = probe;
      if (value < probe) {
        probe = self.nodes[probe].left;
      } else if (value > probe) {
        probe = self.nodes[probe].right;
      } else if (value == probe) {
        self.nodes[probe].keys.push(key);
        self.nodes[probe].keyMap[key] =
          self.nodes[probe].keys.length -
          uint256(1);
        return;
      }
      self.nodes[cursor].count++;
    }
    Node storage nValue = self.nodes[value];
    nValue.parent = cursor;
    nValue.left = EMPTY;
    nValue.right = EMPTY;
    nValue.red = true;
    nValue.keys.push(key);
    nValue.keyMap[key] = nValue.keys.length - uint256(1);
    if (cursor == EMPTY) {
      self.root = value;
    } else if (value < cursor) {
      self.nodes[cursor].left = value;
    } else {
      self.nodes[cursor].right = value;
    }
    insertFixup(self, value);
  }

  function remove(
    Tree storage self,
    bytes32 key,
    uint256 value
  ) internal {
    require(
      value != EMPTY,
      "OrderStatisticsTree(407) - Value to delete cannot be zero"
    );
    require(
      keyExists(self, key, value),
      "OrderStatisticsTree(408) - Value to delete does not exist."
    );
    Node storage nValue = self.nodes[value];
    uint256 rowToDelete = nValue.keyMap[key];
    nValue.keys[rowToDelete] = nValue.keys[nValue.keys.length - uint256(1)];
    nValue.keyMap[key] = rowToDelete;
    nValue.keys.pop();
    uint256 probe;
    uint256 cursor;
    if (nValue.keys.length == 0) {
      if (self.nodes[value].left == EMPTY || self.nodes[value].right == EMPTY) {
        cursor = value;
      } else {
        cursor = self.nodes[value].right;
        while (self.nodes[cursor].left != EMPTY) {
          cursor = self.nodes[cursor].left;
        }
      }
      if (self.nodes[cursor].left != EMPTY) {
        probe = self.nodes[cursor].left;
      } else {
        probe = self.nodes[cursor].right;
      }
      uint256 cursorParent = self.nodes[cursor].parent;
      self.nodes[probe].parent = cursorParent;
      if (cursorParent != EMPTY) {
        if (cursor == self.nodes[cursorParent].left) {
          self.nodes[cursorParent].left = probe;
        } else {
          self.nodes[cursorParent].right = probe;
        }
      } else {
        self.root = probe;
      }
      bool doFixup = !self.nodes[cursor].red;
      if (cursor != value) {
        replaceParent(self, cursor, value);
        self.nodes[cursor].left = self.nodes[value].left;
        self.nodes[self.nodes[cursor].left].parent = cursor;
        self.nodes[cursor].right = self.nodes[value].right;
        self.nodes[self.nodes[cursor].right].parent = cursor;
        self.nodes[cursor].red = self.nodes[value].red;
        (cursor, value) = (value, cursor);
        fixCountRecurse(self, value);
      }
      if (doFixup) {
        removeFixup(self, probe);
      }
      fixCountRecurse(self, cursorParent);
      delete self.nodes[cursor];
    }
  }

  function fixCountRecurse(Tree storage self, uint256 value) private {
    while (value != EMPTY) {
      self.nodes[value].count =
        getNodeCount(self, self.nodes[value].left) +
        getNodeCount(self, self.nodes[value].right);
      value = self.nodes[value].parent;
    }
  }

  function treeMinimum(Tree storage self, uint256 value)
    private
    view
    returns (uint256)
  {
    while (self.nodes[value].left != EMPTY) {
      value = self.nodes[value].left;
    }
    return value;
  }

  function treeMaximum(Tree storage self, uint256 value)
    private
    view
    returns (uint256)
  {
    while (self.nodes[value].right != EMPTY) {
      value = self.nodes[value].right;
    }
    return value;
  }

  function rotateLeft(Tree storage self, uint256 value) private {
    uint256 cursor = self.nodes[value].right;
    uint256 parent = self.nodes[value].parent;
    uint256 cursorLeft = self.nodes[cursor].left;
    self.nodes[value].right = cursorLeft;
    if (cursorLeft != EMPTY) {
      self.nodes[cursorLeft].parent = value;
    }
    self.nodes[cursor].parent = parent;
    if (parent == EMPTY) {
      self.root = cursor;
    } else if (value == self.nodes[parent].left) {
      self.nodes[parent].left = cursor;
    } else {
      self.nodes[parent].right = cursor;
    }
    self.nodes[cursor].left = value;
    self.nodes[value].parent = cursor;
    self.nodes[value].count =
      getNodeCount(self, self.nodes[value].left) +
      getNodeCount(self, self.nodes[value].right);
    self.nodes[cursor].count =
      getNodeCount(self, self.nodes[cursor].left) +
      getNodeCount(self, self.nodes[cursor].right);
  }

  function rotateRight(Tree storage self, uint256 value) private {
    uint256 cursor = self.nodes[value].left;
    uint256 parent = self.nodes[value].parent;
    uint256 cursorRight = self.nodes[cursor].right;
    self.nodes[value].left = cursorRight;
    if (cursorRight != EMPTY) {
      self.nodes[cursorRight].parent = value;
    }
    self.nodes[cursor].parent = parent;
    if (parent == EMPTY) {
      self.root = cursor;
    } else if (value == self.nodes[parent].right) {
      self.nodes[parent].right = cursor;
    } else {
      self.nodes[parent].left = cursor;
    }
    self.nodes[cursor].right = value;
    self.nodes[value].parent = cursor;
    self.nodes[value].count =
      getNodeCount(self, self.nodes[value].left) +
      getNodeCount(self, self.nodes[value].right);
    self.nodes[cursor].count =
      getNodeCount(self, self.nodes[cursor].left) +
      getNodeCount(self, self.nodes[cursor].right);
  }

  function insertFixup(Tree storage self, uint256 value) private {
    uint256 cursor;
    while (value != self.root && self.nodes[self.nodes[value].parent].red) {
      uint256 valueParent = self.nodes[value].parent;
      if (valueParent == self.nodes[self.nodes[valueParent].parent].left) {
        cursor = self.nodes[self.nodes[valueParent].parent].right;
        if (self.nodes[cursor].red) {
          self.nodes[valueParent].red = false;
          self.nodes[cursor].red = false;
          self.nodes[self.nodes[valueParent].parent].red = true;
          value = self.nodes[valueParent].parent;
        } else {
          if (value == self.nodes[valueParent].right) {
            value = valueParent;
            rotateLeft(self, value);
          }
          valueParent = self.nodes[value].parent;
          self.nodes[valueParent].red = false;
          self.nodes[self.nodes[valueParent].parent].red = true;
          rotateRight(self, self.nodes[valueParent].parent);
        }
      } else {
        cursor = self.nodes[self.nodes[valueParent].parent].left;
        if (self.nodes[cursor].red) {
          self.nodes[valueParent].red = false;
          self.nodes[cursor].red = false;
          self.nodes[self.nodes[valueParent].parent].red = true;
          value = self.nodes[valueParent].parent;
        } else {
          if (value == self.nodes[valueParent].left) {
            value = valueParent;
            rotateRight(self, value);
          }
          valueParent = self.nodes[value].parent;
          self.nodes[valueParent].red = false;
          self.nodes[self.nodes[valueParent].parent].red = true;
          rotateLeft(self, self.nodes[valueParent].parent);
        }
      }
    }
    self.nodes[self.root].red = false;
  }

  function replaceParent(
    Tree storage self,
    uint256 a,
    uint256 b
  ) private {
    uint256 bParent = self.nodes[b].parent;
    self.nodes[a].parent = bParent;
    if (bParent == EMPTY) {
      self.root = a;
    } else {
      if (b == self.nodes[bParent].left) {
        self.nodes[bParent].left = a;
      } else {
        self.nodes[bParent].right = a;
      }
    }
  }

  function removeFixup(Tree storage self, uint256 value) private {
    uint256 cursor;
    while (value != self.root && !self.nodes[value].red) {
      uint256 valueParent = self.nodes[value].parent;
      if (value == self.nodes[valueParent].left) {
        cursor = self.nodes[valueParent].right;
        if (self.nodes[cursor].red) {
          self.nodes[cursor].red = false;
          self.nodes[valueParent].red = true;
          rotateLeft(self, valueParent);
          cursor = self.nodes[valueParent].right;
        }
        if (
          !self.nodes[self.nodes[cursor].left].red &&
          !self.nodes[self.nodes[cursor].right].red
        ) {
          self.nodes[cursor].red = true;
          value = valueParent;
        } else {
          if (!self.nodes[self.nodes[cursor].right].red) {
            self.nodes[self.nodes[cursor].left].red = false;
            self.nodes[cursor].red = true;
            rotateRight(self, cursor);
            cursor = self.nodes[valueParent].right;
          }
          self.nodes[cursor].red = self.nodes[valueParent].red;
          self.nodes[valueParent].red = false;
          self.nodes[self.nodes[cursor].right].red = false;
          rotateLeft(self, valueParent);
          value = self.root;
        }
      } else {
        cursor = self.nodes[valueParent].left;
        if (self.nodes[cursor].red) {
          self.nodes[cursor].red = false;
          self.nodes[valueParent].red = true;
          rotateRight(self, valueParent);
          cursor = self.nodes[valueParent].left;
        }
        if (
          !self.nodes[self.nodes[cursor].right].red &&
          !self.nodes[self.nodes[cursor].left].red
        ) {
          self.nodes[cursor].red = true;
          value = valueParent;
        } else {
          if (!self.nodes[self.nodes[cursor].left].red) {
            self.nodes[self.nodes[cursor].right].red = false;
            self.nodes[cursor].red = true;
            rotateLeft(self, cursor);
            cursor = self.nodes[valueParent].left;
          }
          self.nodes[cursor].red = self.nodes[valueParent].red;
          self.nodes[valueParent].red = false;
          self.nodes[self.nodes[cursor].left].red = false;
          rotateRight(self, valueParent);
          value = self.root;
        }
      }
    }
    self.nodes[value].red = false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./HitchensOrderStatisticsTreeLib.sol";

contract Nearest {
  using HitchensOrderStatisticsTreeLib for HitchensOrderStatisticsTreeLib.Tree;
  HitchensOrderStatisticsTreeLib.Tree tree;

  /**
   * It sorts key/value pairs.
   * You may have duplicate keys or duplicate values,
   * but you cannot have dublicate key/value pairs.
   */

  function insert(uint256 value, bytes32 key) public {
    tree.insert(key, value);
  }

  function nearest(uint256 search) public view returns (uint256 value) {
    uint256 rank = tree.rank(search);
    value = tree.atRank(rank);

    /**
     * We have a match or the nearest higher number.
     * Will return the highest number if the search is out of range.
     * Quick hack to switch to next lower:
     */

    if (search != value && rank > 0) rank -= 1;
    value = tree.atRank(rank);

    /**
     * We have a match or the nearest lower number.
     * will return the lowest number if the search is out of range.
     */
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITraitManager {
  function traits(uint8 id) external view returns (string memory);

  function traitValues(uint8 traitId, uint8 id)
    external
    view
    returns (string memory);

  function addRandomness(uint256 tokenId, uint256 randomWord) external;

  function getTraits(uint256 tokenId)
    external
    view
    returns (uint8[] memory, uint8[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./data-structures/Nearest.sol";
import "./interfaces/ITraitManager.sol";

contract TraitManager is AccessControl, ITraitManager {
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  struct Trait {
    string name;
    string value;
  }

  mapping(uint8 => string) public override traits;
  mapping(uint8 => mapping(uint8 => string)) public override traitValues;
  mapping(uint256 => uint256) public randomness;
  uint8 public numTraits;
  mapping(uint8 => Nearest) public traitTrees;

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MANAGER_ROLE, msg.sender);
  }

  function addTrait(uint8 id, string memory name)
    external
    onlyRole(MANAGER_ROLE)
  {
    traitTrees[id] = new Nearest();
    traits[id] = name;
    numTraits++;
  }

  function addTraitValue(
    uint8 traitId,
    uint8 valueId,
    string memory value,
    uint8 raritySlot
  ) external onlyRole(MANAGER_ROLE) {
    traitValues[traitId][valueId] = value;
    traitTrees[traitId].insert(raritySlot, 0x0);
  }

  function addRandomness(uint256 tokenId, uint256 randomWord)
    external
    override
  {
    randomness[tokenId] = randomWord;
  }

  function getTraits(uint256 tokenId)
    external
    view
    override
    returns (uint8[] memory, uint8[] memory)
  {
    uint8[] memory traitNameResults = new uint8[](numTraits);
    uint8[] memory traitValueResults = new uint8[](numTraits);
    for (uint8 i = 0; i < numTraits; i++) {
      uint8 traitRandomNumber = uint8(randomness[tokenId] >> ((i + 1) * 8));
      uint8 traitValueRandomNumber = traitRandomNumber % 100;
      traitNameResults[i] = i;
      traitValueResults[i] = uint8(
        traitTrees[i].nearest(uint256(traitValueRandomNumber))
      );
    }
    return (traitNameResults, traitValueResults);
  }
}