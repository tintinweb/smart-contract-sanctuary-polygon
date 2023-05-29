// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./CourseFactory.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CourseContract {

    bool public courseStatus; //Is determined by the teacher. Can be used with signup status to give 4 states: pending, open, in progress and closed.
    bool public paymentStatus; //Once payment is set by teacher, enrollment can begin
    uint public payment; //Amount requested by the teacher, also the amount that needs to be sponsored to start the course
    uint public studentStake; //Amount student needs to stake to enroll in the course, possible platform rewards for staking in future versions?
    uint public sponsorshipTotal; //Total Sponsorship amount
    uint public paymentTimestamp; //Timestamp of payment of Teacher.
    uint internal div = 15; // payment/div = studentStake
    address public teacher;
    address[] public sponsors;
    address[] public students;
    address public peaceAntzCouncil = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148; //address that will be sent stake of students who dropout
//This address is basically the address that gets further funding to develop the Dapp :)


//Events for pretty much each function
    event GrantRole(bytes32 role, address account);
    event RevokeRole(bytes32 role, address account);
    event DropOut(address indexed account);
    event CourseStatus(bool courseStatus);
    event PaymentStatus(bool paymentStatus);
    event StudentEnrolled(address account);
    event Sponsored(uint indexed sponsorDeposit, address account);
    event CourseCompleted(address indexed account);
    event ClaimPayment(uint paymentTimestamp);

    //role => account = bool to keep track of roles of addresses
    mapping(bytes32 => mapping(address => bool)) public roles;

    //Need to track each address that deposits as a sponsor or student
    mapping (address => uint) public studentDeposit;
    mapping (address => uint) public sponsorDeposit;
    //track pass/fail for each student
    mapping (address => bool) public courseCompleted;

//Different Roles stored as bytes32 NOTE: ADMIN will be set to the multisig address.
    //0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42
    bytes32 private constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    //0x534b5b9fe29299d99ea2855da6940643d68ed225db268dc8d86c1f38df5de794
    bytes32 private constant TEACHER = keccak256(abi.encodePacked("TEACHER"));
    //0xc951d7098b66ba0b8b77265b6e9cf0e187d73125a42bcd0061b09a68be421810
    bytes32 private constant STUDENT = keccak256(abi.encodePacked("STUDENT"));
    //0x5f0a5f78118b6e0b700e0357ae3909aaafe8fa706a075935688657cf4135f9a9
    bytes32 private constant SPONSOR = keccak256(abi.encodePacked("SPONSOR"));

//Access control modifier
    modifier onlyRole(bytes32 _role){
        require(roles[_role][msg.sender], "not authorized");
        _;
    }

//CourseFactory Contract address to update Teacher, Student, Sponsor and Academy info.
    address public factoryAddress;
    CourseFactory factory;


//Sets the contract creator as the TEACHER and the multisig wallet as the ADMIN
    constructor(address _teacher, address _factoryAddress) payable{
        teacher = _teacher;
        factoryAddress = _factoryAddress;
        factory = CourseFactory(factoryAddress);
        _grantRole(ADMIN, 0x6bE3d955Cb6cF9A52Bc3c92F453309931012D386); //set address to multisig address upon deployment
        _grantRole(TEACHER, _teacher);
    }

//Admin Functions
    function _grantRole(bytes32 _role, address _account) internal{
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }

    function grantRole(bytes32 _role, address _account) external onlyRole(ADMIN){
        _grantRole(_role,_account);
    }

    function revokeRole(bytes32 _role, address _account) external onlyRole(ADMIN){
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }

//Teacher Functions
    //"Start Course" Button, locks in enrollments and sponsorship payments
    function updateCourseStatus() external onlyRole(TEACHER){
        require(courseStatus==false);
        require(paymentStatus==true);
        require(payment == sponsorshipTotal, "Course is has not been fully sponsored yet :(");
        courseStatus=true;
        paymentStatus=false;
        factory.updateTeacherProgress(msg.sender,payment);
        factory.updateSponsorsProgress(sponsors);
        emit CourseStatus(true);
        emit PaymentStatus(false);
    }
    //Teacher sets how much they want to be paid, allows enrollment to start, cannot be changed.
    function setAmount(uint _payment) external onlyRole(TEACHER){
        require(paymentStatus==false, "You cannot change change payment after it has been set, please create another course.");
        require(courseStatus==false, "You cannot change the payment.");
        payment = _payment;
        unchecked {
            studentStake= _payment/div;
        }
        paymentStatus=true;
        emit PaymentStatus(true);
    }
    //Teacher passes student which completes the course and pays back each student that passes.
    function passStudent(address _account) external onlyRole(TEACHER){
        require(roles[STUDENT][_account],"Not a student!");
        require(courseStatus==true);
        courseCompleted[_account]=true;
        paymentStatus = true;
        //send money to student
        (bool success, ) = _account.call{value: studentStake}("");
        require(success, "Failed to send stake back to student");
        factory.updateStudentCourses(msg.sender, _account, studentStake);
        emit PaymentStatus(true);
        emit CourseCompleted(_account);
    }
    //Teacher can also boot student which sends student's stake to multisig.
    function bootStudent(address _account) external onlyRole(TEACHER){
        require(roles[STUDENT][_account] = true,"Address is not enrolled :/");
        roles[STUDENT][_account] = false;
        (bool success, ) = peaceAntzCouncil.call{value: studentStake}("");
        require(success, "Failed to boot >:(");
        factory.updateBoot(_account, studentStake);
        emit DropOut(_account);
    }
    //After the first student is passed the teacher can claim the sponsored payment at will.
    function claimPayment() external onlyRole(TEACHER){
        require(courseStatus == true,"You have to start and complete the course to collect sponsor payment.");
        require(paymentStatus == true,"Please pass a student to complete the course.");
        (bool success, ) = msg.sender.call{value: payment}("");
        require(success, "Failed to claim :(");
        factory.updatePaymentRank(msg.sender, sponsors, address(this), payment);
        emit ClaimPayment(block.timestamp);
    }

//Student Functions
    //Student enroll by staking the studentStake amount, they can withdraw if they want but stake is locked once the course starts.
    function enroll()external payable{
        require(!roles[TEACHER][msg.sender],"Teachers cannot enroll in their own course!");
        require(courseStatus == false, "Course has already started :("); 
        require(!roles[STUDENT][msg.sender],"You are enrolled already!");
        require(msg.value == studentStake, "Please Stake the Correct Amount");
        require(paymentStatus == true, "Enrollment Closed");
        studentStake = msg.value;
        roles[STUDENT][msg.sender] = true;
        studentDeposit[msg.sender] = studentStake;
        factory.updateStudentStake(msg.sender, studentStake);
        emit StudentEnrolled(msg.sender);
    }
    //Students can withdraw before the course starts, once the course starts, the student has to pass the course to get stake back.
    function withdraw () external payable {
        require(roles[STUDENT][msg.sender],"You are not enrolled!");
        require(address(this).balance >0, "No balance available");
        require(courseStatus == false, "You have to dropout because the course has started.");
        require(msg.value == 0,"Leave value empty.");
        studentDeposit[msg.sender] = 0;
        roles[STUDENT][msg.sender] = false;
        (bool success, ) = msg.sender.call{value: studentStake}("");
        require(success, "Failed to withdraw :(");
        factory.updateWithdraw(msg.sender, studentStake);
        emit RevokeRole(STUDENT, msg.sender);

    }
    //Students can dropout after the course starts but it will get logged and stake will be sent to Peace Antz Council multisig.
    function dropOut() external payable onlyRole(STUDENT){
        require(courseStatus == true, "Course has not started yet, feel free to simply withdraw :)");
        require(courseCompleted[msg.sender] == false, "You have completed the course already!");
        (bool success, ) = peaceAntzCouncil.call{value: studentStake}("");
        require(success, "Failed to drop course :(");
        roles[STUDENT][msg.sender] = false;
        factory.updateDropout(msg.sender, studentStake);
        emit DropOut(msg.sender);
    }


//Sponsor Functions
    //Allows sponsor to send ETH to contract and sill remember the amount of each sponsor and total amount.
    function sponsor() external payable {
        require(courseStatus == false, "Course has already begun.");
        require(payment>sponsorshipTotal,"This course is fully sponsored :)");
        require(msg.value >0, "Please input amount you wish to sponsor");
        require(msg.value<=(payment-sponsorshipTotal), "Please input the Sponsorship amount needed or less");
        roles[SPONSOR][msg.sender] = true;
        sponsors.push(msg.sender);
        uint currentDeposit = sponsorDeposit[msg.sender] + msg.value;
        uint _sponsorshipTotal = sponsorshipTotal + msg.value;
        assert(_sponsorshipTotal >= sponsorshipTotal);
        sponsorshipTotal = _sponsorshipTotal;
        sponsorDeposit[msg.sender] = currentDeposit;
        factory.updateSponsorship(msg.sender, msg.value);
        emit Sponsored(currentDeposit, msg.sender);
    }
    //Allows user to withdraw whatever they sponsored before the course begins
    function unsponsor(address payable _to, uint _amount) external payable onlyRole(SPONSOR){
        require(courseStatus == false, "Course has already begun.");
        require(_amount>0,"Please input an amount to unsponsor");
        require(_amount<=sponsorDeposit[_to], "That is more than you have sponsored");
        require(_to == msg.sender,"You are not the owner of this address.");

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to withdraw :(");

        uint currentDeposit = sponsorDeposit[_to] - _amount;
        assert(currentDeposit <= sponsorDeposit[_to]);
        uint _sponsorshipTotal = sponsorshipTotal - _amount;
        assert(_sponsorshipTotal <= sponsorshipTotal);
        sponsorshipTotal = _sponsorshipTotal;
        sponsorDeposit[_to]=currentDeposit;
        if (sponsorDeposit[_to] == 0){
        roles[SPONSOR][_to] = false;
        factory.updateUnsponsor(msg.sender, _amount);
        emit RevokeRole(SPONSOR, _to);
        }
    }
}

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "./CourseContract.sol";

//This is a factory contract to deploy course contracts. 
//This contract also keeps track of rankings of the teachers, students and sponsors
//It also keeps track of the TVL, Total Sponsored and Total Staked in Peace Antz Academy.
contract CourseFactory{

    struct AcademyInfo{
        uint tvl;
        uint totalSponsored;
        uint totalStaked;
        uint totalPayout;
        uint failFund;
    }

    struct TeacherRank{
        uint totalEarned;
        uint pendingPayouts;
        uint coursesTaught;
        uint coursesInProgress;
        uint studentsPassed;
        }
    struct StudentRank{
        uint totalStaked;
        uint totalLocked;
        uint coursesTaken;
        uint coursesEnrolled;
        uint coursesDropped;
    }
    struct SponsorRank{
        uint totalSponsored;
        uint pendingPayouts;
        uint coursesSponsored;
        uint inProgressSponsored;
        uint selfSponsored;
    }

    //Need mapings to remember each account's info
    //Also a mapping to keep track of all deployed Course Contracts.
    mapping(address => TeacherRank) public teacherRank;
    mapping(address => StudentRank) public studentRank;
    mapping(address => SponsorRank) public sponsorRank;
    mapping(address => bool) public deployedContracts;
    AcademyInfo public academyInfo;
    //Not sure why I keep making events, I think they will be useful on the front end later.
    event CourseCreated(address courseId, address account);
    //Course ID basically a works like a nonce for deployed courses with an array of the deployed addresses.
    CourseContract[] public courseId;

    constructor() {
        // Just put this in as something for the contructor to do
        academyInfo = AcademyInfo(0, 0, 0, 0, 0);
    }

    //This is a main function that allows a teacher to deploy a course contract and sets the msg.sender as the teacher
    function createCourse() public{
        CourseContract courseContract = new CourseContract(msg.sender, address(this));
        courseId.push(courseContract);
        deployedContracts[address(courseContract)] = true;
        emit CourseCreated(address(courseContract), msg.sender);
    }
   
    modifier isValid() {
    require(deployedContracts[msg.sender], "Caller is not a Peace Antz Academy CourseContract");
    _;
    }


            // This function will update the student's rank and the academy's info 
    // when a student enrolls in a course.
    function updateStudentStake(address student, uint256 amount) external isValid {
        // We first get a reference to the student's rank using their address.
        StudentRank storage rank = studentRank[student];

        // We then update the total amount the student has staked.
        // This is the sum of all amounts the student has ever staked.
        rank.totalStaked += amount;

        // We also update the total amount currently locked in courses.
        // This is the sum of all amounts the student has staked in ongoing courses.
        rank.totalLocked += amount;

        // We increment the number of courses the student is currently enrolled in.
        rank.coursesEnrolled += 1;

        // We then update the academy's info.
        // The total value locked (TVL) in the academy is the sum of all staked amounts.
        academyInfo.tvl += amount;

        // The total staked in the academy is also the sum of all staked amounts.
        academyInfo.totalStaked += amount;
    }

    //This updates the student from locked amount back to normals because the student had passed the course.
    function updateStudentCourses(address teacher, address student, uint stake) external isValid{
        StudentRank storage rank = studentRank[student];
        TeacherRank storage trank = teacherRank[teacher];
        rank.totalLocked -= stake;
        rank.coursesEnrolled -=1;
        rank.coursesTaken +=1;
        trank.studentsPassed += 1;
        academyInfo.totalStaked -= stake;
        academyInfo.tvl -= stake;
    }

    //if a student gets booted their funds stay locked, they are un-enrolled and it goes on their record for courses dropped.
    function updateBoot(address student, uint stake) external isValid{
        StudentRank storage rank = studentRank[student];
        rank.coursesDropped += 1;
        rank.coursesEnrolled -= 1;
        rank.totalLocked -= stake;
        academyInfo.totalStaked -= stake;
        academyInfo.tvl -= stake;
    }

    function updateWithdraw(address student, uint stake) external isValid{
        StudentRank storage rank = studentRank[student];
        rank.totalStaked -= stake;
        rank.totalLocked -= stake;
        rank.coursesEnrolled -= 1;
        academyInfo.totalStaked -= stake;
        academyInfo.tvl -= stake;
    }

    function updateDropout(address student, uint stake) external isValid{
        StudentRank storage rank = studentRank[student];
        rank.coursesDropped += 1;
        rank.totalStaked -= stake;
        rank.totalLocked -= stake;
        rank.coursesEnrolled -= 1;
        academyInfo.totalStaked -= stake;
        academyInfo.tvl -= stake;
    }

    
    //function is triggered when the teacher updates the course status, which officially starts the course.
    function updateTeacherProgress(address teacher, uint payout) external isValid {
        TeacherRank storage rank = teacherRank[teacher];
        // We then update the Teacher Rank Struct
        // The total value locked (TVL) in the academy is the sum of all staked amounts.
        rank.coursesInProgress += 1;
        rank.pendingPayouts += payout;
    }

    function updatePaymentRank(address teacher, address[] memory sponsors, address courseContract, uint payment) external isValid {
        TeacherRank storage trank = teacherRank[teacher];
        trank.coursesInProgress -= 1;
        trank.coursesTaught += 1;
        trank.pendingPayouts -= payment;
        trank.totalEarned += payment;

        CourseContract cContract = CourseContract(courseContract); // Create instance of the CourseContract

        for (uint i = 0; i < sponsors.length; i++) {
            SponsorRank storage srank = sponsorRank[sponsors[i]];
            srank.inProgressSponsored -= 1;
            uint sponsorPayment = cContract.sponsorDeposit(sponsors[i]); // Fetch the deposit made by this sponsor
            srank.pendingPayouts -= sponsorPayment; // Subtract the actual deposit made by the sponsor
        }
    academyInfo.tvl -= payment;
    academyInfo.totalSponsored -= payment;
    academyInfo.totalPayout += payment;
    }


    function updateSponsorsProgress(address[] memory sponsors) external isValid {
        for (uint i = 0; i < sponsors.length; i++) {
        SponsorRank storage rank = sponsorRank[sponsors[i]];
        rank.inProgressSponsored += 1;
        }
    }

    function updateSponsorship(address sponsor, uint value) external isValid{
        SponsorRank storage rank = sponsorRank[sponsor];
        rank.totalSponsored += value;
        rank.pendingPayouts += value;
        rank.coursesSponsored += 1;
        academyInfo.tvl += value;
        academyInfo.totalSponsored += value;
    }

    function updateUnsponsor(address sponsor, uint value) external isValid{
        SponsorRank storage rank = sponsorRank[sponsor];
        rank.totalSponsored -= value;
        rank.pendingPayouts -= value;
        if (value == rank.totalSponsored) {
            rank.coursesSponsored -= 1;
        }
        academyInfo.tvl -= value;
        academyInfo.totalSponsored -= value;
    }
    
}