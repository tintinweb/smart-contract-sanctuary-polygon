// SPDX-License-Identifier: ALGPL-3.0-or-later-or-later
// from https://github.com/makerdao/dss/blob/master/src/jug.sol
pragma solidity ^0.8.4;

library DSMath {
    /**
     * @dev github.com/makerdao/dss implementation of exponentiation by squaring
     * @dev nth power of x where x is decimal number with b precision
     */
    function rpow(uint256 x, uint256 n, uint256 b) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := b
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := b
                }
                default {
                    z := x
                }
                let half := div(b, 2) // for rounding.
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, b)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, b)
                    }
                }
            }
        }
    }
}

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
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IAuthorizationContract.sol";

/// @author Swarm Markets
/// @title Access Manager for AssetToken Contract
/// @notice Contract to manage the Asset Token contracts
abstract contract AccessManager is AccessControl {
    error AM_Blacklisted(address _blacklistedAddress);
    /// @notice Role to be able to deploy an Asset Token
    bytes32 public constant ASSET_DEPLOYER_ROLE = keccak256("ASSET_DEPLOYER_ROLE");

    /// @dev This is a WAD on DSMATH representing 1
    uint256 public constant DECIMALS = 10 ** 18;
    /// @dev This is a proportion of 1 representing 100%, equal to a WAD
    uint256 public constant HUNDRED_PERCENT = 10 ** 18;

    /// @notice Structure to hold the Token Data
    /// @notice guardian and issuer of the contract
    /// @notice isFrozen: boolean to store if the contract is frozen
    /// @notice isOnSafeguard: state of the contract: false is ACTIVE // true is SAFEGUARD
    /// @notice positiveInterest: if the interest will be a positvie or negative one
    /// @notice interestRate: the interest rate set in AssetTokenData.setInterestRate() (percent per seconds)
    /// @notice rate: the interest determined by the formula. Default is 10**18
    /// @notice lastUpdate: last block where the update function was called
    /// @notice blacklist: account => bool (if bool = true, account is blacklisted)
    /// @notice agents: agents => bool(true or false) (enabled/disabled agent)
    /// @notice safeguardTransferAllow: allow certain addresses to transfer even on safeguard
    /// @notice authorizationsPerAgent: list of contracts of each agent to authorize a user
    /// @notice array of addresses. Each one is a contract with the isTxAuthorized function
    struct TokenData {
        address issuer;
        address guardian;
        bool isFrozen;
        bool isOnSafeguard;
        bool positiveInterest;
        uint256 interestRate;
        uint256 rate;
        uint256 lastUpdate;
        mapping(address => bool) blacklist;
        mapping(address => bool) agents;
        mapping(address => bool) safeguardTransferAllow;
        mapping(address => address) authorizationsPerAgent;
        address[] authorizationContracts;
    }

    /// @notice mapping of TokenData, entered by token Address
    mapping(address => TokenData) public tokensData;

    /// @dev this is just to have an estimation of qty and prevent innecesary looping
    uint256 public maxQtyOfAuthorizationLists;

    /// @notice Emitted when changed max quantity
    event ChangedMaxQtyOfAuthorizationLists(address indexed changedBy, uint newQty);

    /// @notice Emitted when Issuer is transferred
    event IssuerTransferred(address indexed _tokenAddress, address indexed _caller, address indexed _newIssuer);
    /// @notice Emitted when Guardian is transferred
    event GuardianTransferred(address indexed _tokenAddress, address indexed _caller, address indexed _newGuardian);

    /// @notice Emitted when Agent is added to the contract
    event AgentAdded(address indexed _tokenAddress, address indexed _caller, address indexed _newAgent);
    /// @notice Emitted when Agent is removed from the contract
    event AgentRemoved(address indexed _tokenAddress, address indexed _caller, address indexed _agent);

    /// @notice Emitted when an Agent list is transferred to another Agent
    event AgentAuthorizationListTransferred(
        address indexed _tokenAddress,
        address _caller,
        address indexed _newAgent,
        address indexed _oldAgent
    );

    /// @notice Emitted when an account is added to the Asset Token Blacklist
    event AddedToBlacklist(address indexed _tokenAddress, address indexed _account, address indexed _from);
    /// @notice Emitted when an account is removed from the Asset Token Blacklist
    event RemovedFromBlacklist(address indexed _tokenAddress, address indexed _account, address indexed _from);

    /// @notice Emitted when a contract is added to the Asset Token Authorization list
    event AddedToAuthorizationContracts(
        address indexed _tokenAddress,
        address indexed _contractAddress,
        address indexed _from
    );
    /// @notice Emitted when a contract is removed from the Asset Token Authorization list
    event RemovedFromAuthorizationContracts(
        address indexed _tokenAddress,
        address indexed _contractAddress,
        address indexed _from
    );

    /// @notice Emitted when an account is granted with the right to transfer on safeguard state
    event AddedTransferOnSafeguardAccount(address indexed _tokenAddress, address indexed _account);
    /// @notice Emitted when an account is revoked the right to transfer on safeguard state
    event RemovedTransferOnSafeguardAccount(address indexed _tokenAddress, address indexed _account);

    /// @notice Emitted when a new Asset Token is deployed and registered
    event TokenRegistered(address indexed _tokenAddress, address _caller);
    /// @notice Emitted when an  Asset Token is deleted
    event TokenDeleted(address indexed _tokenAddress, address _caller);

    /// @notice Emitted when the contract changes to safeguard mode
    event ChangedToSafeGuard(address indexed _tokenAddress);

    /// @notice Emitted when the contract gets frozen
    event FrozenContract(address indexed _tokenAddress);
    /// @notice Emitted when the contract gets unfrozen
    event UnfrozenContract(address indexed _tokenAddress);

    /// @notice Allow TRANSFER on Safeguard
    /// @param _tokenAddress address of the current token being managed
    /// @param _account the account to grant the right to transfer on safeguard state
    function allowTransferOnSafeguard(address _tokenAddress, address _account) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());

        emit AddedTransferOnSafeguardAccount(_tokenAddress, _account);
        tokensData[_tokenAddress].safeguardTransferAllow[_account] = true;
    }

    /// @notice Removed TRANSFER on Safeguard
    /// @param _tokenAddress address of the current token being managed
    /// @param _account the account to be revoked from the right to transfer on safeguard state
    function preventTransferOnSafeguard(address _tokenAddress, address _account) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());

        emit RemovedTransferOnSafeguardAccount(_tokenAddress, _account);
        tokensData[_tokenAddress].safeguardTransferAllow[_account] = false;
    }

    function changeMaxQtyOfAuthorizationLists(uint newMaxQty) public onlyRole(DEFAULT_ADMIN_ROLE) {
        maxQtyOfAuthorizationLists = newMaxQty;

        emit ChangedMaxQtyOfAuthorizationLists(msg.sender, newMaxQty);
    }

    /**
     * @notice Checks if the user is authorized by the agent
     * @dev This function verifies if the `_from` and `_to` addresses are authorized to perform a given `_amount`
     * transaction on the asset token contract `_tokenAddress`.
     * @param _tokenAddress The address of the current token being managed
     * @param _from The address to be checked if it's authorized
     * @param _to The address to be checked if it's authorized
     * @param _amount The amount of the operation to be made
     * @return bool Returns true if `_from` and `_to` are authorized to perform the transaction
     */
    function mustBeAuthorizedHolders(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool) {
        onlyStoredToken(_tokenAddress);

        require(_msgSender() == _tokenAddress, "AccessManager: caller must be tokenAddress");
        // This line below should never happen. A registered asset token shouldn't call
        // to this function with both addresses (from - to) in ZERO
        require(!(_from == address(0) && _to == address(0)), "AccessManager: from and to are addresses 0");

        address[2] memory addresses = [_from, _to];
        uint256 response = 0;
        uint256 arrayLength = addresses.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (addresses[i] != address(0)) {
                if (tokensData[_tokenAddress].blacklist[addresses[i]]) {
                    revert AM_Blacklisted(addresses[i]);
                }

                /// @dev the caller (the asset token contract) is an authorized holder
                if (addresses[i] == _tokenAddress && addresses[i] == _msgSender()) {
                    response++;
                    // this is a resource to avoid validating this contract in other system
                    addresses[i] = address(0);
                }
                if (!tokensData[_tokenAddress].isOnSafeguard) {
                    /// @dev on active state, issuer and agents are authorized holder
                    if (
                        addresses[i] == tokensData[_tokenAddress].issuer ||
                        tokensData[_tokenAddress].agents[addresses[i]]
                    ) {
                        response++;
                        // this is a resource to avoid validating agent/issuer in other system
                        addresses[i] = address(0);
                    }
                } else {
                    /// @dev on safeguard state, guardian is authorized holder
                    if (addresses[i] == tokensData[_tokenAddress].guardian) {
                        response++;
                        // this is a resource to avoid validating guardian in other system
                        addresses[i] = address(0);
                    }
                }

                /// each of these if statements are mutually exclusive, so response cannot be more than 2
            }
        }

        /// if response is more than 0 none of the address are:
        /// the asset token contract itself, agents, issuer or guardian
        /// if response is 1 there is one address which is one of the above
        /// if response is 2 both addresses are one of the above, no need to iterate in external list
        if (response < 2) {
            require(
                tokensData[_tokenAddress].authorizationContracts.length > 0,
                "AccessManager: token authorizations list is empty"
            );
            IAuthorizationContract authorizationList;
            for (uint256 i = 0; i < tokensData[_tokenAddress].authorizationContracts.length; i++) {
                authorizationList = IAuthorizationContract(tokensData[_tokenAddress].authorizationContracts[i]);
                if (authorizationList.isTxAuthorized(_tokenAddress, addresses[0], addresses[1], _amount)) {
                    return true;
                }
            }
        } else {
            return true;
        }
        return false;
    }

    /// @notice Changes the ISSUER
    /// @param _tokenAddress address of the current token being managed
    /// @param _newIssuer to be assigned in the contract
    function transferIssuer(address _tokenAddress, address _newIssuer) external {
        onlyStoredToken(_tokenAddress);
        require(
            _msgSender() == tokensData[_tokenAddress].issuer || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "AccessManager: only issuer or DEFAULT_ADMIN"
        );
        emit IssuerTransferred(_tokenAddress, _msgSender(), _newIssuer);
        tokensData[_tokenAddress].issuer = _newIssuer;
    }

    /// @notice Changes the GUARDIAN
    /// @param _tokenAddress address of the current token being managed
    /// @param _newGuardian to be assigned in the contract
    function transferGuardian(address _tokenAddress, address _newGuardian) external {
        onlyStoredToken(_tokenAddress);
        require(
            _msgSender() == tokensData[_tokenAddress].guardian || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "AccessManager: only guardian or DEFAULT_ADMIN"
        );
        emit GuardianTransferred(_tokenAddress, _msgSender(), _newGuardian);
        tokensData[_tokenAddress].guardian = _newGuardian;
    }

    /// @notice Adds an AGENT
    /// @param _tokenAddress address of the current token being managed
    /// @param _newAgent to be added
    function addAgent(address _tokenAddress, address _newAgent) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());
        require(!tokensData[_tokenAddress].agents[_newAgent], "AccessManager: agent already exists");
        emit AgentAdded(_tokenAddress, _msgSender(), _newAgent);
        tokensData[_tokenAddress].agents[_newAgent] = true;
    }

    /// @notice Deletes an AGENT
    /// @param _tokenAddress address of the current token being managed
    /// @param _agent to be removed
    function removeAgent(address _tokenAddress, address _agent) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());
        require(tokensData[_tokenAddress].agents[_agent], "AccessManager: agent not found");

        require(!_agentHasContractsAssigned(_tokenAddress, _agent), "AccessManager: agent has contracts assigned");

        emit AgentRemoved(_tokenAddress, _msgSender(), _agent);
        delete tokensData[_tokenAddress].agents[_agent];
    }

    /// @notice Transfers the authorization contracts to a new Agent
    /// @param _tokenAddress address of the current token being managed
    /// @param _newAgent to link the authorization list
    /// @param _oldAgent to unlink the authrization list
    function transferAgentList(address _tokenAddress, address _newAgent, address _oldAgent) external {
        onlyStoredToken(_tokenAddress);
        if (!tokensData[_tokenAddress].isOnSafeguard) {
            require(
                _msgSender() == tokensData[_tokenAddress].issuer || tokensData[_tokenAddress].agents[_msgSender()],
                "AccessManager: only agent or issuer (onActive)"
            );
        } else {
            require(_msgSender() == tokensData[_tokenAddress].guardian, "AccessManager: only guardian (onSafeguard)");
        }
        require(
            tokensData[_tokenAddress].authorizationContracts.length > 0,
            "AccessManager: token authorization list is empty"
        );
        require(_newAgent != _oldAgent, "AccessManager: newAgent is oldAgent");
        require(tokensData[_tokenAddress].agents[_oldAgent], "AccessManager: oldAgent not found");

        if (_msgSender() != tokensData[_tokenAddress].issuer && _msgSender() != tokensData[_tokenAddress].guardian) {
            require(_oldAgent == _msgSender(), "AccessManager: list is not owned");
        }
        require(tokensData[_tokenAddress].agents[_newAgent], "AccessManager: newAgent not found");

        (bool executionOk, bool changed) = _changeAuthorizationOwnership(_tokenAddress, _newAgent, _oldAgent);
        // this 2 lines below should never happen. The change list owner should always be successfull
        // because of the requires validating the information before calling _changeAuthorizationOwnership
        require(executionOk, "AccessManager: authorization list ownership transfer failed");
        require(changed, "AccessManager: agent has no contracts");
        emit AgentAuthorizationListTransferred(_tokenAddress, _msgSender(), _newAgent, _oldAgent);
    }

    /// @notice Adds an address to the authorization list
    /// @param _tokenAddress address of the current token being managed
    /// @param _contractAddress the address to be added
    function addToAuthorizationList(address _tokenAddress, address _contractAddress) external {
        onlyStoredToken(_tokenAddress);
        onlyAgent(_tokenAddress, _msgSender());
        require(_isContract(_contractAddress), "AccessManager: contractAddress is not contract");
        require(
            tokensData[_tokenAddress].authorizationsPerAgent[_contractAddress] == address(0),
            "AccessManager: contractAddress belongs to agent"
        );
        emit AddedToAuthorizationContracts(_tokenAddress, _contractAddress, _msgSender());
        tokensData[_tokenAddress].authorizationContracts.push(_contractAddress);
        tokensData[_tokenAddress].authorizationsPerAgent[_contractAddress] = _msgSender();
    }

    /// @notice Removes an address from the authorization list
    /// @param _tokenAddress address of the current token being managed
    /// @param _contractAddress the address to be removed
    function removeFromAuthorizationList(address _tokenAddress, address _contractAddress) external {
        onlyStoredToken(_tokenAddress);
        onlyAgent(_tokenAddress, _msgSender());
        require(_isContract(_contractAddress), "AccessManager: contractAddress is not contract");
        require(
            tokensData[_tokenAddress].authorizationsPerAgent[_contractAddress] != address(0),
            "AccessManager: contractAddress not found"
        );
        require(
            tokensData[_tokenAddress].authorizationsPerAgent[_contractAddress] == _msgSender(),
            "AccessManager: contract not managed by caller"
        );

        emit RemovedFromAuthorizationContracts(_tokenAddress, _contractAddress, _msgSender());

        // this line below should never happen. The removal should always be successfull
        // because of the require validating the caller before _removeFromAuthorizationArray
        require(
            _removeFromAuthorizationArray(_tokenAddress, _contractAddress),
            "AccessManager: failed removing from auth array"
        );
        delete tokensData[_tokenAddress].authorizationsPerAgent[_contractAddress];
    }

    /// @notice Adds an address to the blacklist
    /// @param _tokenAddress address of the current token being managed
    /// @param _account the address to be blacklisted
    function addMemberToBlacklist(address _tokenAddress, address _account) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());
        require(!tokensData[_tokenAddress].blacklist[_account], "AccessManager: account is already blacklisted");
        emit AddedToBlacklist(_tokenAddress, _account, _msgSender());
        tokensData[_tokenAddress].blacklist[_account] = true;
    }

    /// @notice Removes an address from the blacklist
    /// @param _tokenAddress address of the current token being managed
    /// @param _account the address to be removed from the blacklisted
    function removeMemberFromBlacklist(address _tokenAddress, address _account) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());
        require(tokensData[_tokenAddress].blacklist[_account], "AccessManager: account is not blacklisted");
        emit RemovedFromBlacklist(_tokenAddress, _account, _msgSender());
        delete tokensData[_tokenAddress].blacklist[_account];
    }

    /// @notice Register the asset tokens and its rates in this contract
    /// @param _tokenAddress address of the current token being managed
    /// @param _issuer address of the contract issuer
    /// @param _guardian address of the contract guardian
    /// @return bool true if operation was successful
    function registerAssetToken(address _tokenAddress, address _issuer, address _guardian) external returns (bool) {
        require(_tokenAddress != address(0), "AccessManager: tokenAddress is address 0");
        require(_issuer != address(0), "AccessManager: issuer is address 0");
        require(_guardian != address(0), "AccessManager: guardian is address 0");
        // slither-disable-next-line incorrect-equality
        require(tokensData[_tokenAddress].issuer == address(0), "AccessManager: token already registered");
        require(_isContract(_tokenAddress), "AccessManager: tokenAddress must be contract");
        require(hasRole(ASSET_DEPLOYER_ROLE, _msgSender()), "AccessManager: only ASSET_DEPLOYER");

        emit TokenRegistered(_tokenAddress, _msgSender());

        TokenData storage newTokenData = tokensData[_tokenAddress];
        newTokenData.issuer = _issuer;
        newTokenData.guardian = _guardian;
        newTokenData.rate = DECIMALS;
        newTokenData.lastUpdate = block.timestamp;

        return true;
    }

    /// @notice Deletes the asset token from this contract
    /// @notice It has no real use (I think should be removed)
    /// @param _tokenAddress address of the current token being managed
    function deleteAssetToken(address _tokenAddress) external {
        onlyStoredToken(_tokenAddress);
        onlyUnfrozenContract(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());

        emit TokenDeleted(_tokenAddress, _msgSender());
        // slither-disable-next-line mapping-deletion
        delete tokensData[_tokenAddress];
    }

    /// @notice Set the contract into Safeguard)
    /// @param _tokenAddress address of the current token being managed
    /// @return bool true if operation was successful
    function setContractToSafeguard(address _tokenAddress) external returns (bool) {
        onlyStoredToken(_tokenAddress);
        onlyUnfrozenContract(_tokenAddress);
        onlyActiveContract(_tokenAddress);
        require(_msgSender() == _tokenAddress, "AccessManager: only tokenAddress");
        emit ChangedToSafeGuard(_tokenAddress);
        tokensData[_tokenAddress].isOnSafeguard = true;
        return true;
    }

    /// @notice Freeze the contract
    /// @param _tokenAddress address of the current token being managed
    /// @return bool true if operation was successful
    function freezeContract(address _tokenAddress) external returns (bool) {
        onlyStoredToken(_tokenAddress);
        require(_msgSender() == _tokenAddress, "AccessManager: only tokenAddress");

        emit FrozenContract(_tokenAddress);
        tokensData[_tokenAddress].isFrozen = true;
        return true;
    }

    /// @notice Unfreeze the contract
    /// @param _tokenAddress address of the current token being managed
    /// @return bool true if operation was successful
    function unfreezeContract(address _tokenAddress) external returns (bool) {
        onlyStoredToken(_tokenAddress);
        require(_msgSender() == _tokenAddress, "AccessManager: only tokenAddress");

        emit UnfrozenContract(_tokenAddress);
        tokensData[_tokenAddress].isFrozen = false;
        return true;
    }

    /// @notice Check if the token is valid
    /// @param _tokenAddress address of the current token being managed
    function onlyStoredToken(address _tokenAddress) public view {
        require(tokensData[_tokenAddress].issuer != address(0), "AccessManager: token address is address 0");
    }

    /// @notice Check if the token contract is Not frozen
    /// @param _tokenAddress address of the current token being managed
    function onlyUnfrozenContract(address _tokenAddress) public view {
        require(!tokensData[_tokenAddress].isFrozen, "AccessManager: token address frozen");
    }

    /// @notice Check if the token contract is Active
    /// @param _tokenAddress address of the current token being managed
    function onlyActiveContract(address _tokenAddress) public view {
        require(!tokensData[_tokenAddress].isOnSafeguard, "AccessManager: token address not active (onSafeguard)");
    }

    /// @notice Check if sender is the ISSUER
    /// @param _tokenAddress address of the current token being managed
    /// @param _functionCaller the caller of the function where this is used
    function onlyIssuer(address _tokenAddress, address _functionCaller) external view {
        // slither-disable-next-line incorrect-equality
        require(_functionCaller == tokensData[_tokenAddress].issuer, "AccessManager: only issuer");
    }

    /// @notice Check if sender is an AGENT
    /// @param _tokenAddress address of the current token being managed
    /// @param _functionCaller the caller of the function where this is used
    function onlyAgent(address _tokenAddress, address _functionCaller) public view {
        require(tokensData[_tokenAddress].agents[_functionCaller], "AccessManager: only agent");
    }

    /// @notice Check if sender is AGENT_or ISSUER
    /// @param _tokenAddress address of the current token being managed
    /// @param _functionCaller the caller of the function where this is used
    function onlyIssuerOrAgent(address _tokenAddress, address _functionCaller) external view {
        // slither-disable-next-line incorrect-equality
        require(
            _functionCaller == tokensData[_tokenAddress].issuer || tokensData[_tokenAddress].agents[_functionCaller],
            "AccessManager: only issuer or agent"
        );
    }

    /// @notice Check if sender is GUARDIAN or ISSUER
    /// @param _tokenAddress address of the current token being managed
    /// @param _functionCaller the caller of the function where this is used
    function onlyIssuerOrGuardian(address _tokenAddress, address _functionCaller) public view {
        if (tokensData[_tokenAddress].isOnSafeguard) {
            // slither-disable-next-line incorrect-equality
            require(
                _functionCaller == tokensData[_tokenAddress].guardian,
                "AccessManager: only Guardian (onSafeguard)"
            );
        } else {
            // slither-disable-next-line incorrect-equality
            require(_functionCaller == tokensData[_tokenAddress].issuer, "AccessManager: only Issuer (onActive)");
        }
    }

    /// @notice Return if the account can transfer on safeguard
    /// @param _tokenAddress address of the current token being managed
    /// @param _account the account to get info from
    /// @return bool true or false
    function isAllowedTransferOnSafeguard(address _tokenAddress, address _account) external view returns (bool) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].safeguardTransferAllow[_account];
    }

    /// @notice Get if the contract is on SafeGuard or not
    /// @param _tokenAddress address of the current token being managed
    /// @return bool true if the contract is on SafeGuard
    function isOnSafeguard(address _tokenAddress) external view returns (bool) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].isOnSafeguard;
    }

    /// @notice Get if the contract is frozen or not
    /// @param _tokenAddress address of the current token being managed
    /// @return bool true if the contract is frozen
    function isContractFrozen(address _tokenAddress) external view returns (bool) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].isFrozen;
    }

    /// @notice Get the issuer of the asset token
    /// @param _tokenAddress address of the current token being managed
    /// @return address the issuer address
    function getIssuer(address _tokenAddress) external view returns (address) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].issuer;
    }

    /// @notice Get the guardian of the asset token
    /// @param _tokenAddress address of the current token being managed
    /// @return address the guardian address
    function getGuardian(address _tokenAddress) external view returns (address) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].guardian;
    }

    /// @notice Get if the account is blacklisted for the asset token
    /// @param _tokenAddress address of the current token being managed
    /// @return bool true if the account is blacklisted
    function isBlacklisted(address _tokenAddress, address _account) external view returns (bool) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].blacklist[_account];
    }

    /// @notice Get if the account is an agent of the asset token
    /// @param _tokenAddress address of the current token being managed
    /// @return bool true if account is an agent
    function isAgent(address _tokenAddress, address _agentAddress) external view returns (bool) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].agents[_agentAddress];
    }

    /// @notice Get the agent address who was responsable of the validation contract (_contractAddress)
    /// @param _tokenAddress address of the current token being managed
    /// @return address of the agent
    function authorizationContractAddedBy(
        address _tokenAddress,
        address _contractAddress
    ) external view returns (address) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].authorizationsPerAgent[_contractAddress];
    }

    /// @notice Get the position (index) in the authorizationContracts array of the authorization contract
    /// @param _tokenAddress address of the current token being managed
    /// @return uint256 the index of the array
    function getIndexByAuthorizationAddress(
        address _tokenAddress,
        address _authorizationContractAddress
    ) external view returns (uint256) {
        onlyStoredToken(_tokenAddress);
        uint256 arrayLength = tokensData[_tokenAddress].authorizationContracts.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            // slither-disable-next-line incorrect-equality
            if (tokensData[_tokenAddress].authorizationContracts[i] == _authorizationContractAddress) {
                return i;
            }
        }
        /// @dev returning this when address is not found
        return maxQtyOfAuthorizationLists + 1;
    }

    /// @notice Get the authorization contract address given an index in authorizationContracts array
    /// @param _tokenAddress address of the current token being managed
    /// @return address the address of the authorization contract
    function getAuthorizationAddressByIndex(address _tokenAddress, uint256 _index) external view returns (address) {
        require(
            _index < tokensData[_tokenAddress].authorizationContracts.length,
            "AccessManager: index does not exist"
        );
        return tokensData[_tokenAddress].authorizationContracts[_index];
    }

    /* *
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
     */

    /// @notice Returns true if `account` is a contract
    /// @param _contractAddress the address to be ckecked
    /// @return bool if `account` is a contract
    function _isContract(address _contractAddress) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_contractAddress)
        }
        return size > 0;
    }

    /// @notice checks if the agent has a contract from the array list assigned
    /// @param _tokenAddress address of the current token being managed
    /// @param _agent agent to check
    /// @return bool if the agent has any contract assigned
    function _agentHasContractsAssigned(address _tokenAddress, address _agent) internal view returns (bool) {
        uint256 arrayLength = tokensData[_tokenAddress].authorizationContracts.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (
                // slither-disable-next-line incorrect-equality
                tokensData[_tokenAddress].authorizationsPerAgent[tokensData[_tokenAddress].authorizationContracts[i]] ==
                _agent
            ) {
                return true;
            }
        }
        return false;
    }

    /// @notice changes the owner of the contracts auth array
    /// @param _tokenAddress address of the current token being managed
    /// @param _newAgent target agent to link the contracts to
    /// @param _oldAgent source agent to unlink the contracts from
    /// @return bool true if there was no error
    /// @return bool true if authorization ownership has occurred
    function _changeAuthorizationOwnership(
        address _tokenAddress,
        address _newAgent,
        address _oldAgent
    ) internal returns (bool, bool) {
        bool changed = false;
        uint256 arrayLength = tokensData[_tokenAddress].authorizationContracts.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            if (
                // slither-disable-next-line incorrect-equality
                tokensData[_tokenAddress].authorizationsPerAgent[tokensData[_tokenAddress].authorizationContracts[i]] ==
                _oldAgent
            ) {
                tokensData[_tokenAddress].authorizationsPerAgent[
                    tokensData[_tokenAddress].authorizationContracts[i]
                ] = _newAgent;
                changed = true;
            }
        }
        return (true, changed);
    }

    /// @notice removes contract from auth array
    /// @param _tokenAddress address of the current token being managed
    /// @param _contractAddress to be removed
    /// @return bool if address was removed
    function _removeFromAuthorizationArray(address _tokenAddress, address _contractAddress) internal returns (bool) {
        uint256 arrayLength = tokensData[_tokenAddress].authorizationContracts.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            // slither-disable-next-line incorrect-equality
            if (tokensData[_tokenAddress].authorizationContracts[i] == _contractAddress) {
                tokensData[_tokenAddress].authorizationContracts[i] = tokensData[_tokenAddress].authorizationContracts[
                    arrayLength - 1
                ];
                tokensData[_tokenAddress].authorizationContracts.pop();
                return true;
            }
        }
        // This line below should never happen. Before calling this function,
        // it is known that the address exists in the array
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@dlsl/dev-modules/libs/math/DSMath.sol";
import "./AccessManager.sol";

/// @author Swarm Markets
/// @title Asset Token Data for Asset Token Contract
/// @notice Contract to manage the interest rate on the Asset Token contract
contract AssetTokenData is AccessManager {
    /// @notice Emitted when the interest rate is set
    event InterestRateStored(
        address indexed _tokenAddress,
        address indexed _caller,
        uint256 _interestRate,
        bool _positiveInterest
    );

    /// @notice Emitted when the rate gets updated
    event RateUpdated(address indexed _tokenAddress, address indexed _caller, uint256 _newRate, bool _positiveInterest);

    /// @notice Constructor
    /// @param _maxQtyOfAuthorizationLists max qty for addresses to be added in the authorization list
    constructor(uint256 _maxQtyOfAuthorizationLists) {
        require(_maxQtyOfAuthorizationLists > 0, "AssetTokenData: maxQtyOfAuthorizationLists must be > 0");
        require(_maxQtyOfAuthorizationLists < 100, "AssetTokenData: maxQtyOfAuthorizationLists must be < 100");

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        maxQtyOfAuthorizationLists = _maxQtyOfAuthorizationLists;
    }

    /// @notice Gets the interest rate and positive/negative interest value
    /// @param _tokenAddress address of the current token being managed
    /// @return uint256 the interest rate
    /// @return bool true if it is positive interest, false if it is not
    function getInterestRate(address _tokenAddress) external view returns (uint256, bool) {
        onlyStoredToken(_tokenAddress);
        return (tokensData[_tokenAddress].interestRate, tokensData[_tokenAddress].positiveInterest);
    }

    /// @notice Gets the current rate
    /// @param _tokenAddress address of the current token being managed
    /// @return uint256 the rate
    function getCurrentRate(address _tokenAddress) external view returns (uint256) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].rate;
    }

    /// @notice Gets the timestamp of the last update
    /// @param _tokenAddress address of the current token being managed
    /// @return uint256 the last update in block.timestamp format
    function getLastUpdate(address _tokenAddress) external view returns (uint256) {
        onlyStoredToken(_tokenAddress);
        return tokensData[_tokenAddress].lastUpdate;
    }

    /// @notice Sets the new intereset rate
    /// @param _tokenAddress address of the current token being managed
    /// @param _interestRate the value to be set
    /// @param _positiveInterest if it's a negative or positive interest
    function setInterestRate(address _tokenAddress, uint256 _interestRate, bool _positiveInterest) external {
        onlyStoredToken(_tokenAddress);
        onlyIssuerOrGuardian(_tokenAddress, _msgSender());
        // @note the value is in percent per seconds

        // 20 digits - THIS IS 100% ANUAL
        require(_interestRate <= 21979553151, "AssetTokenData: interestRate must be <= 21979553151");
        emit InterestRateStored(_tokenAddress, _msgSender(), _interestRate, _positiveInterest);
        update(_tokenAddress);
        tokensData[_tokenAddress].interestRate = _interestRate;
        tokensData[_tokenAddress].positiveInterest = _positiveInterest;
    }

    /// @notice Update the Structure counting the blocks since the last update and calculating the rate
    /// @param _tokenAddress address of the current token being managed
    function update(address _tokenAddress) public {
        onlyStoredToken(_tokenAddress);

        uint256 _period = block.timestamp - tokensData[_tokenAddress].lastUpdate;
        uint previousRate = tokensData[_tokenAddress].rate;
        uint256 _newRate;

        if (tokensData[_tokenAddress].positiveInterest) {
            _newRate =
                (previousRate * DSMath.rpow(DECIMALS + tokensData[_tokenAddress].interestRate, _period, DECIMALS)) /
                DECIMALS;
        } else {
            _newRate =
                (previousRate * DSMath.rpow(DECIMALS - tokensData[_tokenAddress].interestRate, _period, DECIMALS)) /
                DECIMALS;
        }

        tokensData[_tokenAddress].rate = _newRate;
        tokensData[_tokenAddress].lastUpdate = block.timestamp;

        emit RateUpdated(_tokenAddress, _msgSender(), _newRate, tokensData[_tokenAddress].positiveInterest);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @author Swarm Markets
/// @title IAuthorizationContracts
/// @notice Provided interface to interact with any contract to check
/// @notice authorization to a certain transaction
interface IAuthorizationContract {
    function isAccountAuthorized(address _user) external view returns (bool);

    function isTxAuthorized(address _tokenAddress, address _from, address _to, uint256 _amount) external returns (bool);
}