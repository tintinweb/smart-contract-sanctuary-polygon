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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
pragma solidity 0.8.17;
import "../interfaces/IFactory.sol";
import "./utils/Access.sol";

/**
* @title Master Registry for easy project deployment
* @author Szabolcs Egri
* @dev The Master Registry is the only access point for users to interract with the system.
* @dev It stores the state of all the projects that were deployed using the master registry.
* @dev Currently the create project only works with admin priviledges, we are going to realease a payable version for all users.
* @dev The contract inherits functionality from Access.
*/
contract MasterRegistry is Access {
    /**
    * @dev Struct to store project details.
    * @param projectId Id of project.
    * @param factoryId Id of factory that was used to deploy the project.
    * @param tokenAddress Address of the token contract that was deployed.
    * @param projectOwner Current owner of troject (deployed token).
    * @param projectName Name of the project.
    * @param projectBannerUrl Banner url of the project.
    * @param visible Allowing the option for admins to hide inapropiate projects from the application users. Has no effect on-chain.
    */
    struct Project{
        uint256 projectId;
        uint256 factoryId;
        address tokenAddress;
        address projectOwner;
        string projectName;
        string projectBannerUrl;
        bool visible;
    }
    /**
    * @dev Struct to store factory details.
    * @param factoryAddress Address of factory contract.
    * @param factoryName Factory name for easier identification of factories.
    */
    struct Factory{
        address factoryAddress;
        string factoryName;
    }
    /// @dev Mapping of factoryId to Factory.
    mapping (uint256 => Factory) public factories;
    /// @dev Mapping of projectId to Project.
    mapping (uint256 => Project) public projects;
    /// @dev project counter that auto increments on project creation, used to make sure every project has a different Id.
    uint256 public projectCounter;

    /**
    * @dev Emitted when the owner of a prject changes.
    * @dev Only happens when the owner of a token contract that corresponds to a project changes.
    * @param projectId Project ID.
    * @param newProjectOwner The new project owner.
    */
    event ProjectOwnerChanged(uint256 projectId, address newProjectOwner);
    /**
    * @dev Emitted when a new factory is added to the factories mapping.
    * @param factoryId Id of the new factory.
    * @param factoryAddress Address of the new factory.
    */
    event FactoryAdded(uint256 factoryId, address factoryAddress, string factoryName);
    /**
    * @dev Emitted when a new project is created.
    * @param projectId Id of the project.
    * @param factoryId Id of the factory used to deploy the project.
    * @param tokenAddress Address of the deployed token contract.
    * @param owner Owner of the project and token contract.
    * @param projectName Name of the project.
    * @param projectBannerUrl Banner url of the project.
    */
    event ProjectCreated(
        uint256 projectId,
        uint256 factoryId,
        address tokenAddress,
        address owner,
        string projectName,
        string projectBannerUrl
    );
    /**
    * @dev Emitted when the visibility of a project changes.
    * @param projectId Id of the project
    * @param newVisibility New visibility of the project
    */
    event VisibilityChanged(uint256 projectId, bool newVisibility);
    /**
    * @dev Emitted when the name or the banner url of a project changes.
    * @param projectId Id of the project
    * @param newProjectName New name of the project
    * @param newProjectBennerUrl New banner url of the project
    */
    event ProjectInformationChanged(uint256 projectId, string newProjectName, string newProjectBennerUrl);
    /**
    * @dev Initializes the contract graning admin priviledges to the deployer.
    */
    constructor(){
        grantAdminRole(msg.sender);
    }

    /**
    * @dev Modifier that checks if a project exists.
    * @dev Reverts with `MasterRegistry: project does not exist`.
    * @param _projectId ID of the project to check.
    */
    modifier projectExists(uint256 _projectId){
        Project memory projectToCheck = projects[_projectId];
        require(projectToCheck.tokenAddress != address(0), "MasterRegistry: project does not exist");
        _;
    }

    /** 
    * @dev Modifier that checks if the caller is the token contract associated with the project.
    * @dev Reverts with `MasterRegistry: msg.sender does not match token address`.
    * @param _projectId ID of the project to check
    */
    modifier onlyProject(uint256 _projectId){
        Project memory projectToCheck = projects[_projectId];
        address tokenAddress = projectToCheck.tokenAddress;
        require(msg.sender == tokenAddress, "MasterRegistry: msg.sender does not match token address");
        _;
    }

    /** 
    * @dev Modifier that checks if the caller is the factory associated with the project.
    * @dev Reverts with `MasterRegistry: msg.sender does not match factory address`.
    * @param _projectId ID of the project to check
    */
    modifier onlyFactory(uint256 _projectId){
        uint256 factoryId = projects[_projectId].factoryId;
        address factoryAddress = factories[factoryId].factoryAddress;
        require(msg.sender == factoryAddress, "MasterRegistry: msg.sender does not match factory address");
        _;
    }

    /** 
    * @dev Saves factory details into the factories mapping.
    * @dev Factory ID must be new, meaning that is not present in the factories mapping.
    * @param _factoryId Id of the factory.
    * @param _factoryAddress Address of the deployed factory.
    * @param _factoryName Factory name for easier identification.
    */
    function addFactory(uint256 _factoryId, address _factoryAddress, string memory _factoryName)
        external
        onlyAdmin
    {
        require(factories[_factoryId].factoryAddress == address(0), "MasterRegistry: factory ID already in use");
        factories[_factoryId] = Factory(_factoryAddress,_factoryName);
        emit FactoryAdded(_factoryId, _factoryAddress, _factoryName);
    }
    
    /**
    * @dev The factory Id must be a valid id that is present in the factories mapping.
    * @dev Project details are saved in the projects mapping.
    * @dev A token contract will be deployed using the designated factory and ownersip of that contract will be transfered to the owner stated.
    * @dev Project counter is incremented to ensure that every project has a unique project id.
    * @dev The token address for the project is being set by the factory during the deployment, for more details see `{ERC721Factory}`.
    * @param _factoryId Id of the factory.
    * @param _tokenName Name that will be used for the deployed token.
    * @param _tokenSymbol Symbol that will be used for the deploed token.
    * @param _projectName Name of the project.
    * @param _projectBannerUrl Banner URL of the project.
    * @param _owner Owner of the project, ownership of the token contract will be transfered to this address.
    */
    function createProject(
        uint256 _factoryId,
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _projectName,
        string memory _projectBannerUrl,
        address _owner
    )
        external
        onlyAdmin
    { 
        address factoryAddress = factories[_factoryId].factoryAddress;
        require(factoryAddress != address(0), "MasterRegistry: factory does not exist");

        _presetProjectDetails(projectCounter,_factoryId,_projectName,_projectBannerUrl,_owner,true);
        DeployConfiguration memory deployConfig = DeployConfiguration(_tokenName,_tokenSymbol, projectCounter, address(this));
        IFactory projectFactory = IFactory(factoryAddress);
        address tokenAddress = projectFactory.deploy(deployConfig,_owner);
        emit ProjectCreated(projectCounter,_factoryId,tokenAddress,_owner,_projectName,_projectBannerUrl);
        projectCounter += 1;
    }

    /** 
    * @dev Internal function to save the project details into the projects mapping
    * @dev Address of the deployed token will be saved later (after deployment)
    * @dev This early inicialization is needed to allow communication between the factory and the master registry.
    * @param _projectId Id of the project.
    * @param _factoryId Id of the factory.
    * @param _projectName Symbol that will be used for the deploed token.
    * @param _projectBannerUrl Banner URL of the project.
    * @param _owner Owner of the project
    * @param _state State for `visibility` parameter fo the project (set to true by the function calling this)
    */
    function _presetProjectDetails(
        uint256 _projectId,
        uint256 _factoryId,
        string memory _projectName,
        string memory _projectBannerUrl,
        address _owner,
        bool _state
    )
        internal
    {
        projects[_projectId] = Project(_projectId,_factoryId,address(0),_owner,_projectName,_projectBannerUrl,_state);
    }

    /**
    * @dev Sets the token address for a project.
    * @dev Can only be called by the factory that is deploying the token contract for the given project.
    * @dev The factory calls this method right after deploying the token contract and determening its address.
    * @param _projectId Id of the project.
    * @param _tokenAddress Address where the token cotnract was deployed.
    */
    function setTokenAddressForProject(uint256 _projectId, address _tokenAddress)
        external
        onlyFactory(_projectId)
    {
        Project storage projectToUpdate = projects[_projectId];
        projectToUpdate.tokenAddress = _tokenAddress;
    }

    /**
    * @dev Function to set the visbility of a project.
    * @dev The visibility field of projects can be used to filter inapropiate projects for off-chain applications.
    * @dev Can only be called by users with admin priviledges.
    * @param _projectId Id of the project.
    * @param _state State of visibility.
    */
    function setProjectVisibility(uint256 _projectId, bool _state)
        external
        onlyAdmin
        projectExists(_projectId)
    {
        Project storage projectToUpdate = projects[_projectId];
        projectToUpdate.visible = _state;
        emit VisibilityChanged(_projectId,_state);
    }
    /**
    * @dev Fucntion to user to update the name or the banner URL of a project that owns.
    * @dev Can only be called by the owner of the project (owner of the token contract associated with the project).
    * @param _projectId Id of the project that will be updated.
    * @param _newProjectName New name of the project (can be same as befroe).
    * @param _newProjectBannerUrl Banner URL of the project (can be same as befroe).
    */
    function updateProjectInformation(
        uint256 _projectId,
        string memory _newProjectName,
        string memory _newProjectBannerUrl
    )
        external
        projectExists(_projectId)

    {
        Project storage projectToUpdate = projects[_projectId];
        require(msg.sender == projectToUpdate.projectOwner, "MasterRegistry: msg.sender is not project owner");
        projectToUpdate.projectName= _newProjectName;
        projectToUpdate.projectBannerUrl = _newProjectBannerUrl;
        emit ProjectInformationChanged(_projectId, _newProjectName, _newProjectBannerUrl);
    }
    /**
    * @dev This is a function that gets called automatically by the deployed token contracts when an ownership transfer happens.
    * @dev Updates the owner of the project in the projects mapping.
    * @dev Can only be called by projects that were deployed by the master registry.
    * @param _projectId Id of the project that got a new owner.
    * @param _newProjectOwnerAddress Address of the new owner.
    */
    function updateProjectOwner(uint256 _projectId, address _newProjectOwnerAddress)
        external
        onlyProject(_projectId)
    {
        Project storage projectToUpdate = projects[_projectId];
        projectToUpdate.projectOwner = _newProjectOwnerAddress;
        emit ProjectOwnerChanged(_projectId, _newProjectOwnerAddress);
    }
    /**
    * @dev Function to transfer owenership of the master registry.
    * @dev Grants admin role to the new owner.
    * @dev Revokes admin role from the former owner.
    * @dev Can only be called by the owner of the master registry.
    * @param _newOwner Address of the target where the owner would like to transfer ownership to.
    */
    function transferOwnership(address _newOwner) override public onlyOwner {
        grantAdminRole(_newOwner);
        revokeAdminRole(owner());
        _transferOwnership(_newOwner);
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
* @title A customised version of openZeppelin's AccessControl
* @author Anna Anghel
* @dev Contract module that provides an access control mechanism using
* @dev modules {OpenZeppelin-AccessControl} and {OpenZeppelin-Ownable}.
* @dev There are 4 roles: owner, default admin, admin and minter. For owner
* @dev and default admin rights see {AccessControl} and {Ownable}
* @dev documentation.
*/
abstract contract Access is AccessControl, Ownable {
    /**
    * @dev See {OpenZeppelin-AccessControl}.
    */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    /**
    * @dev Initializes the contract setting the deployer as the owner.
    * @dev Grants ADMIN_ROLE to the owner. See {AccessControl-grantRole}
    */
    constructor () Ownable() {
        _grantRole(ADMIN_ROLE, msg.sender);
    }
    
    /**
    * @dev Modifier that checks if caller has minter role. 
    * @dev Reverts with `Access: caller is not a minter`
    */
    modifier onlyMinter(){
        require(hasMinterRole(msg.sender), "Access: caller is not a minter");
        _;
    }

    /**
    * @dev Modifier that checks if caller has admin role.
    * @dev Reverts with `Access: caller is not an admin`
    */
    modifier onlyAdmin(){
        require(hasAdminRole(msg.sender), "Access: caller is not an admin");
        _;
    }


    /**
    * @dev Grants minter role to `_address`. Only with ADMIN_ROLE.
    * @dev See {AccessControl-grantRole}
    */
    function grantMinterRole (address _address) public onlyAdmin {
        _grantRole(MINTER_ROLE, _address);
    }

    /**
    * @dev Revokes minter role from `_address`. Only with ADMIN_ROLE.
    * @dev See {AccessControl-revokeRole}
    */
    function revokeMinterRole (address _address) public onlyAdmin {
        _revokeRole(MINTER_ROLE, _address);
    }

    /**
    * @dev Revokes admin role from `_address`. Only the owner can use this functionality.
    * @dev See {AccessControl-revokeRole}
    */
    function revokeAdminRole (address _address) public onlyOwner {
        _revokeRole(ADMIN_ROLE, _address);
    }

    /**
    * @dev Grants admin role to `_address`. Only the owner can use this functionality.
    * @dev See {AccessControl-grantRole}
    */
    function grantAdminRole (address _address) public onlyOwner {
        _grantRole(ADMIN_ROLE, _address);
    }

    /**
    * @notice Transfers ownership of contract
    * @dev Callable only by owner. See {Ownable-onlyOwner}.
    * @dev It grants the ADMIN_ROLE to the new owner
    * @dev It revokes the ADMIN_ROLE from the current owner
    * @dev See {Ownable-__transferOwnership}.
    * @param _newOwner Address of the new owner
    */
    function transferOwnership(address _newOwner) public virtual override onlyOwner {
        grantAdminRole(_newOwner);
        revokeAdminRole(owner());
        _transferOwnership(_newOwner);
    }

        /**
    * @dev Returns `true` if `_address` has been granted ADMIN_ROLE. 
    * @dev See {AccessControl-hasRole}.
    */
    function hasAdminRole (address _address) public view returns (bool) {
        return hasRole(ADMIN_ROLE, _address);
    }

    /**
    * @dev Returns `true` if `_address` has been granted MINTER_ROLE. 
    * @dev See {AccessControl-hasRole}
    */
    function hasMinterRole (address _address) public view returns (bool) {
        return hasRole(MINTER_ROLE, _address);
    }
    
    /**
    * @dev See {IERC165-supportsInterface}.
    */
    function supportsInterface(bytes4 _interfaceId) 
        public
        view 
        virtual
        override (AccessControl) 
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


struct DeployConfiguration{
    string name;
    string symbol;
    uint256 projectId;
    address masterRegistryAddress;
}

interface IFactory {
    function deploy(DeployConfiguration memory, address) external returns (address);
}