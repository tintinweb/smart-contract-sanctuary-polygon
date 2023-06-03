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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ICals.sol";
import "./IFounders.sol";

/// @title Contract to works as a DataBase in Founders section.
/// @author Panoram Finance.
/// @notice This contract is use to save all the information related to Founders Section.
contract FoundersControl is AccessControl, ReentrancyGuard, IFounders {

    ///@dev developer role created
    bytes32 public constant DEV_ROLE = keccak256("DEV_ROLE");
    
    uint256 private constant _BITMASK_NFTID_DATA_ENTRY = (1 << 128) - 1;
    uint256 private constant _BITPOS_FINAL_ID = 128;

    uint256 public requestId = 0;
    uint256 public idFounder = 0;

    uint256 public year = 1095 days; //3 años

    ICals private calc;
 
    /// @dev wallets that have deposited in Founders. ID Founders => user wallet.
    mapping(uint256 => address) private walletsRegister; 

    /// @dev User address => Founders ID => Struct Data
    mapping(address => mapping(uint256 => Data)) public founders;

    /// @dev User address => Founders ID => Struct NFTInfo for control NFTID
    mapping(address => mapping(uint256 => NFTInfo)) public NFTInformation;

    /// @dev User address => Founders ID => Struct
    mapping(address => mapping(uint256 => Payments)) public payments;

    /// @dev Collection address => Annual interest in base 10k => 1000 = 10%
    mapping(address => uint16) private CollectionToInterest;

    /// @dev Struct for withdrawal data.
    struct withdrawRequest{
        uint256 _amount; // amount to withdraw from Founders
        uint256 _rewards; // interest amount to withdraw
        uint96 _date; // time of withdrawal request creation
        uint96 lastCalcTime; //in case of user cancellation, Data's lastCalcTime is returned to this date.
        uint32 numNFT;
        Status _status;
    }

    /// @dev user address => Request ID => Struct
    mapping(address => mapping(uint256 => withdrawRequest)) private request;

    /// @dev wallet => ID Request - registration of withdrawals by wallet
    mapping(address => uint256) private idRequestInfo;

    mapping(address => bool) private haveWithdraw;

    /// @dev Mapping for permissions.
    mapping(address => bool) public lend;

    /// @dev Contract Constructor.
    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEV_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, 0xb818dd90d667D6D269FA7a690114f98473aF7b95);
        _setupRole(DEV_ROLE, 0xb818dd90d667D6D269FA7a690114f98473aF7b95);  
    }

    /// @dev Modifier to allow or deny access to contract functions, only contracts allowed can use these functions.
    modifier onlyLending() {
        if (!lend[msg.sender]) {
            revert("you can not modify");
        }
        _;
    }

    /// @dev Modifier to allow or deny access to admin functions.
    modifier onlyDev(){
        if(!hasRole(DEV_ROLE, msg.sender)){
            revert("Not enough Permissions");
        }
        _;
    }

    /// @dev Function to return the interest to pay for a Founders collection (one collection = one phase)
    /// @param _collection - The addres of the Collection to query.
    /// @return _interest - the interest to pay for the NFTs of the collection.
    function getCollectionToInterest(address _collection) public view returns(uint16 _interest){
        _interest =  CollectionToInterest[_collection];
    }

    /// @dev Function to get specific information from a Founder necessary in other contracts.
    /// @param wallet - the user's wallet address.
    /// @param id - the user's Founder ID.
    /// @return amount - the amount the user deposited in Founders.
    /// @return depositTime - the deposit date.
    /// @return lastCalcTime - the date of the last time the interest was calculated.
    /// @return payPerSecond - the amount to pay per second to this Founder.
    /// @return withdrawTime - the last time the user withdraw money/earnings from Founders.
    function getFoundersInfo(address wallet, uint256 id) public view returns (uint256 amount, uint256 depositTime, uint96 lastCalcTime, uint256 payPerSecond, uint96 withdrawTime, bool allInteresPaid, bool isFullyPaid) {
        amount = founders[wallet][id].amount;
        depositTime = founders[wallet][id].depositTime;
        lastCalcTime = payments[wallet][id].lastCalcTime;
        payPerSecond= payments[wallet][id].payPerSecond;
        withdrawTime = founders[wallet][id].withdrawTime;
        allInteresPaid = payments[wallet][id].allInteresPaid;
        isFullyPaid = founders[wallet][id].isFullyPaid;
    }

    /// @dev Function to get information related to the interests earned by the user.
    /// @param wallet - the user's wallet address.
    /// @param id - the user's Founders ID.
    /// @return claimed - the interests that the user has claimed.
    /// @return claimhistory - the history amount of the interest claimed.
    /// @return claimTime - the date when the user claimed the rewards/interests.
    /// @return lastTimeClaim - the date of the last time the interest was calculated.
    /// @return totalToPaid - the total amount of interest to pay to the user. 
    function getRewardsClaimed(address wallet, uint256 id) public view returns (uint256 claimed, uint256 claimhistory,uint96 claimTime, uint96 lastTimeClaim, uint256 totalToPaid){
        claimed = payments[wallet][id].claimed;
        claimhistory = founders[wallet][id].claimedHistory;
        claimTime = payments[wallet][id].claimTime;
        lastTimeClaim = payments[wallet][id].lastCalcTime;
        totalToPaid = payments[wallet][id].totalToPaid;
    }

    /// @dev Function to get the pending interests/rewards to be paid to the user.
    /// @param _wallet - the user's wallet address.
    /// @param _id - the user's Founders ID.
    /// @return pendRewards - the pending interests/rewards.
    function getPendingRewards(address _wallet, uint256 _id) public view returns(uint256){
        return payments[_wallet][_id].pendRewards;
    }

    /// @dev Function to get the last time the user set a claim for interests.
    /// @param _wallet - the user's wallet address.
    /// @param _id - the user's Founders ID.
    /// @return lastSetClaimRewards - the date the user set a interests/rewards claim.
    function getLastSetClaimRewards(address _wallet,uint256 _id) public view returns(uint96 lastSetClaimRewards){
        lastSetClaimRewards = payments[_wallet][_id].lastSetClaimRewards;
    }

    /// @dev Function to register a new Founder.
    /// @param wallet - the user's wallet address.
    /// @param _amount - the amount deposited by the user.
    /// @param _payPerSecond - The payment per second that corresponds to this user.
    /// @return _id - the Founders ID
    function addRegistry(address wallet, uint256 _amount, uint256 _payPerSecond, uint32 _totalNFTsBuyed) public onlyLending nonReentrant returns(uint256 _id){
        uint96 time = safeCastToUint96(block.timestamp);
        _id = ++idFounder;
        founders[wallet][_id].amount = _amount;
        founders[wallet][_id].depositTime = time;
        payments[wallet][_id].lastCalcTime = time;
        payments[wallet][_id].claimTime = time;
        payments[wallet][_id].lastSetClaimRewards = time;
        payments[wallet][_id].payPerSecond = _payPerSecond;
        founders[wallet][_id].endFoundersDate = safeCastToUint96(time + year); // fecha en que terminan los 3 años
        
        uint256 _totalToPaid = ICals(calc).calcTotalPayInterest(founders[wallet][_id].endFoundersDate, time, _payPerSecond);
        payments[wallet][_id].totalToPaid = _totalToPaid;

        founders[wallet][_id].totalNFTs = _totalNFTsBuyed;
        NFTInformation[wallet][_id].quantity = _totalNFTsBuyed;
        walletsRegister[_id] = wallet;

        return _id;
    }

    /// @dev Function to update a user deposit in Founders.
    /// @param id - the Founder ID created for the user.
    /// @param wallet - the user's wallet address.
    /// @param _amount - the amount deposited by the user.
    /// @param _payPerSecond - The payment per second that corresponds to this user.
    function updateRegistry(uint256 id, address wallet, uint256 _amount, uint256 _payPerSecond) public onlyLending nonReentrant {
        founders[wallet][id].amount += _amount;
        founders[wallet][id].depositTime = safeCastToUint96(block.timestamp);
        payments[wallet][id].payPerSecond = _payPerSecond;
    }

    /// @dev Function to update the last time the interest to be paid to the user was calculated.
    /// @param wallet - the user's wallet address.
    /// @param _id - the Founders ID created for the user.
    /// @param _timeClaim - The date of the last time the user's interest payment was calculated.
    function updateLastTimeClaim(address wallet, uint256 _id, uint256 _timeClaim) public onlyLending nonReentrant {
        payments[wallet][_id].lastCalcTime = safeCastToUint96(_timeClaim);
    }

    /// @dev Function to clear the pending rewards after the user set a claim for that rewards/interests.
    /// @param wallet - the user's wallet address.
    /// @param _id - the Founders ID created for the user.
    /// @param _timeClaim - The date of the last time the user's interest payment was calculated.
    function updatePendingRewards(address wallet, uint256 _id, uint256 _timeClaim) public onlyLending nonReentrant {
        payments[wallet][_id].pendRewards = 0;
        payments[wallet][_id].lastSetClaimRewards = safeCastToUint96(_timeClaim);
    }

    /// @dev Function to update the interest claimed and the last time the user claims it.
    /// @param id - the Founders ID created for the user.
    /// @param wallet - the user's wallet address.
    /// @param _rewards - the amount claimed.
    /// @param _claimTime - The date when the user claimed their interests/rewards.
    function updateClaimed(uint256 id, address wallet, uint256 _rewards, uint256 _claimTime) public onlyLending nonReentrant {
        payments[wallet][id].claimed += _rewards;
        founders[wallet][id].claimedHistory += _rewards;
        payments[wallet][id].claimTime = safeCastToUint96(_claimTime);
    }

    /// @dev Function to reset the rewards claimed after a withdraw.
    /// @param _id - the Founders ID created for the user.
    /// @param _wallet - the user's wallet address.
   function resetClaimed(uint256 _id, address _wallet) external onlyLending nonReentrant {
        payments[_wallet][_id].claimed = 0;
    } 

    /// @dev Function to rest the amount to withdrawn from the deposit amount register for the user after He set a withdrawal request.
    /// @param id - the Founders ID created for the user.
    /// @param wallet - the user's wallet address.
    /// @param _amount - the amount the user wants to withdraw.
    function claimMoney(uint256 id, address wallet, uint256 _amount, uint256 realAmount) public onlyLending nonReentrant{
        if(founders[wallet][id].amount <= _amount){
            founders[wallet][id].amount = 0;
            founders[wallet][id].isFullyPaid = true;
        }else{
            founders[wallet][id].amount -= realAmount;
        }
    }

    /// @dev Function to add the amount to the amount registered for the user if He cancels the withdrawal.
    /// @param id - the Founders ID created for the user.
    /// @param wallet - the user's wallet address.
    /// @param _amount - The amount that the user had requested to withdraw.
    function updateMoney(uint256 id, address wallet, uint256 _amount) public onlyLending nonReentrant{
        founders[wallet][id].amount += _amount;
        if(founders[wallet][id].isFullyPaid){
            founders[wallet][id].isFullyPaid = false;
        }
    }

    /// @dev Function to update the amount to pay per second to a Founder.
    /// @param _wallet - the user's wallet address.
    /// @param _id - the Founders ID created for the user.
    /// @param _newPayPerSecond - The new payment per second that corresponds to this user.
    /// @param _newTotalToPaid - The new total interest payment corresponds to this user.
    function updatePayPerSecond(address _wallet, uint256 _id ,uint256 _newPayPerSecond, uint256 _newTotalToPaid) public onlyLending {
        payments[_wallet][_id].payPerSecond = _newPayPerSecond;
        payments[_wallet][_id].totalToPaid = _newTotalToPaid;
    }

    /// @dev Function to update the flag that validate if all the interest has been paid to the user.
    /// @param _wallet - the user's wallet address.
    /// @param _id - the Founders ID created for the user.
    function setAllInteresPaid(address _wallet, uint256 _id, bool _state) external onlyLending {
         payments[_wallet][_id].allInteresPaid = _state;
    }

    /// @dev Function to create a request to withdraw your investment or your interest earned.
    /// @param _wallet - the user's wallet address.
    /// @param _amount - The amount to withdraw when the user wants to withdraw from the money they deposited in Founders.
    /// @param _rewards - The interest/rewards earned by the user.
    /// @param _flag - a flag (1,2) to know if the user's request is to withdraw the earned interests or what the user deposited in Founders.
    /// @return _id - The Request ID created.
    function createRequest(address _wallet, uint256 _amount, uint256 _rewards, uint8 _flag, uint32 _numNFT) public onlyLending returns(uint256){
        uint256 _id = ++requestId;
        if(_flag == 1){
            request[_wallet][_id]._amount = _amount;
            request[_wallet][_id]._status = Status.pending;
            request[_wallet][_id].numNFT = _numNFT;
        } else if(_flag == 2){
            request[_wallet][_id]._rewards = _rewards ;
            request[_wallet][_id]._status = Status.pendrewards;
        }
        request[_wallet][_id]._date = safeCastToUint96(block.timestamp);
        request[_wallet][_id].lastCalcTime = payments[_wallet][_id].lastCalcTime;
        setIdRequestInfo(_wallet, _id);
        return _id;
    }

    /// @dev Function to close a withdrawal request.
    /// @param _wallet - the user's wallet address.
    /// @param _id - the Request ID created for the withdrawal.
    /// @param _state - the state from the Status enum that you want to set in the request.
    /// @param _idFounder - The user's Founder ID.
    function closeRequest(address _wallet, uint256 _id, Status _state, uint256 _idFounder) public onlyLending {
        founders[_wallet][_idFounder].withdrawTime = safeCastToUint96(block.timestamp);
        request[_wallet][_id]._status = _state;
    }

    /// @dev Function to get the information registered in a withdrawal request.
    /// @param _wallet - the user's wallet address.
    /// @param _id - the Request ID created for the withdrawal.
    /// @return _amount - The amount to withdraw in case the user wants to withdraw from the money they deposited in Founders.
    /// @return _rewards - The amount of interests to claim if they want to withdraw the interests they have earned.
    /// @return _state - The current status of this request.
    /// @return _date - The date this request was created.
    function getRequest(address _wallet, uint256 _id) public view returns(uint256 _amount,uint256 _rewards, Status _state, uint96 _date, uint96 _numNFT) {
        return(
            request[_wallet][_id]._amount,
            request[_wallet][_id]._rewards,
            request[_wallet][_id]._status,
            request[_wallet][_id]._date,
            request[_wallet][_id].numNFT
        );
    }

    /// @dev Function to associate and address to a Founders ID.
    /// @param id - the Founder ID created for the user.
    /// @param wallet - the user's wallet address.
    function addInfo(uint256 id, address wallet) public onlyLending nonReentrant {
        walletsRegister[id]= wallet;
    }

    /// @dev Function to delete the register of an Founder ID.
    /// @param id - the id Founder to delete.
    function deleteInfo(uint256 id) public onlyLending nonReentrant {
        walletsRegister[id]= address(0);
    }

    /// @dev Function to get the Address of a Founder ID.
    /// @param id - the id Founder to query.
    /// @return _wallet - the user's wallet address.
    function getIdInfo(uint256 id) public view returns(address _wallet){
        return  walletsRegister[id];
    }

    /// @dev Function to update the pending interest to pay for an user.
    /// @param _wallet - the user's wallet address.
    /// @param _id - the Founder ID created for the user.
    /// @return timeOfCalc - the time of the last interest calc. 
   function UpdateInteresAccumulated(address _wallet, uint _id) public onlyLending nonReentrant returns(uint256 timeOfCalc){
        uint256 interesToPay;
            (interesToPay, timeOfCalc) = calc.calcInterestAccumulated(_wallet, _id);
            payments[_wallet][_id].pendRewards += interesToPay;
            payments[_wallet][_id].lastCalcTime = safeCastToUint96(timeOfCalc);
            return timeOfCalc;
    }

    /// @dev Function that saves the earned interests for when the interest rate is changed.
    /// @notice It works updating the interest for batches of Ids Founders.
    /// @param _collection - the collection address for which you want to update the interest.
    /// @param _initialIDFounder - the Id founder in which the funtion will start to save the interest till this moment.
    /// @param _endIDFounder - the Id founder in which the funtion will end the update of interests
    function SaveInteresAccumulated(address _collection, uint256 _initialIDFounder, uint256 _endIDFounder) external onlyDev {
        if(_initialIDFounder > _endIDFounder){
            revert("Initial ID can't be greater than End ID founder");
        }
        uint256 interesToPay;
        uint256 timeOfCalc;
        uint256 payPerSecond;
        uint16 interest = getCollectionToInterest(_collection);

        for(uint256 i = _initialIDFounder; i<=_endIDFounder; ){
            (interesToPay, timeOfCalc) = calc.calcInterestAccumulated(walletsRegister[i], i);
            payments[walletsRegister[i]][i].pendRewards = interesToPay;
            payments[walletsRegister[i]][i].lastCalcTime = safeCastToUint96(timeOfCalc);
            
            payPerSecond = calc.calcInterestForSecond(founders[walletsRegister[i]][i].amount, interest);
            payments[walletsRegister[i]][i].payPerSecond = payPerSecond;
            if(timeOfCalc <= founders[walletsRegister[i]][i].endFoundersDate){
                payments[walletsRegister[i]][i].totalToPaid = (founders[walletsRegister[i]][i].endFoundersDate - timeOfCalc) * payPerSecond;
                payments[walletsRegister[i]][i].claimed = 0;
            } 
            unchecked {
                ++i;
            }
        }  
    }
    
    /// @notice Primero se debe llamar a esta funcion cuando se actualice el interes a pagar
    /// @notice y despues llamar a SaveInteresAccumulated para actualizar el interes pendiente por pagar y el nuevo payPersecond y TotalToPay.
    /// @dev Function to change the annual interest to pay for a collection in each Phase.
    /// @param _interes - the new interest to pay.
    /// @param _collection - the address collection to update.
    function setInteresForCollection(uint16 _interes, address _collection)external onlyDev {
        CollectionToInterest[_collection] = _interes;
        // SaveInteresAccumulated(_collection): update pay per second y total to paid con el nuevo interest
    }

    /// @dev Function to set the contracts that can use the functions of this contract.
    /// @param _lend - The contract address to allow or deny.
    /// @param _state - True to allow or false to remove the permission.
    function setLendContract(address _lend, bool _state) public onlyDev {
        lend[_lend] = _state;
    }

    function updateTime(uint256 _year) public onlyDev {
        year = _year;
    }

    /// @dev function to avoid silently overflow bug.
    /// @param value - the value to cast.
    /// @return result - the value casted
    function safeCastToUint96(uint256 value) private pure returns(uint96){
        require(value <= type(uint96).max, "SafeCast: Value doesn't fit in 96 bits");
        return uint96(value);
    }

    // Llamar a esta funcion en cuanto se tenga desplegado el contrato de calcs
    /// @dev Function to set the Calcs contract address.
    /// @param _calcs - the calcs contract address.
    function updateCalcs(address _calcs) external onlyDev{
        if(_calcs == address(0)){
            revert("Address 0 not allowed");
        }
        calc = ICals(_calcs);
    }

    /// @dev Function to check if a Request ID is associated with an address wallet.
    /// @param wallet - the user's wallet address to check.
    /// @param _id - the Lending ID created for the user to check.
    /// @return _valid - "true" if the wallet is associated with the Lending ID or "false" otherwise.
    function validateId(address wallet, uint256 _id) public view returns (bool _valid){
        uint256 cons = getIdRequestInfo(wallet);
        if(cons == _id){
            return true;
        }else{
            return false;
        }
    }

    function setIdRequestInfo(address wallet, uint256 _id) private {
        idRequestInfo[wallet] = _id;
    }
    function getIdRequestInfo(address wallet) public view returns(uint256 _id){
        return idRequestInfo[wallet];
    }

    function getHaveRequest(address _wallet) public view returns(bool) {
        return haveWithdraw[_wallet];
    }

    function addHaveRequest(address _wallet) external {
         haveWithdraw[_wallet] = true;
    }

    function deleteHaveRequest(address _wallet) external {
         haveWithdraw[_wallet] = false;
    }

    function getEndFoundersDay(address _wallet,uint256 _id) public view returns(uint96) {
        return founders[_wallet][_id].endFoundersDate;
    }
    
    function getDepositTime(address _wallet,uint256 _id) public view returns(uint256) {
        return founders[_wallet][_id].depositTime;
    }

    function writeNFTId(uint256 _startId, uint256 _finalId, address _wallet, uint256 _id) external onlyLending nonReentrant  {
        if(_startId > type(uint128).max || _finalId > type(uint128).max){
            revert("Greater than 128 bits");
        }
        if(_startId > _finalId){
            revert("FinalId is smaller");
        }
        founders[_wallet][_id].nftIds = ((_finalId  << _BITPOS_FINAL_ID) | _startId);
        NFTInformation[_wallet][_id].nftIds = ((_finalId  << _BITPOS_FINAL_ID) | _startId);
    }

    function updateNFTInformation(address _wallet, uint256 _id, uint256 _quantity, uint256 _startId,uint256 _finalId) external onlyLending nonReentrant {
        NFTInformation[_wallet][_id].quantity = _quantity;
        NFTInformation[_wallet][_id].nftIds = ((_finalId  << _BITPOS_FINAL_ID) | _startId);
    }

    function getDataNFTId(address _wallet, uint256 _id) external view returns(uint256 _startId,uint256 _finalId){
        _startId = founders[_wallet][_id].nftIds & _BITMASK_NFTID_DATA_ENTRY;
        _finalId = founders[_wallet][_id].nftIds >> _BITPOS_FINAL_ID;
         return (_startId, _finalId);
    }

    function getNFTInformation(address _wallet, uint256 _id) external view returns(uint256 _startId,uint256 _finalId, uint256 _quantity){
        _startId = NFTInformation[_wallet][_id].nftIds & _BITMASK_NFTID_DATA_ENTRY;
        _finalId = NFTInformation[_wallet][_id].nftIds >> _BITPOS_FINAL_ID;
        _quantity = NFTInformation[_wallet][_id].quantity;
        return (_startId,_finalId,_quantity);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/// @title Calcs Interface.
/// @author Panoram Finance.
/// @notice You can use this interface in other contracts to connect to the Calcs Contract.
interface ICals {

    /// @dev Function to calculate the user's interest accumulated in Lending.  
    function calcInterestAccumulated(address _wallet,uint256 _idLending) external view returns(uint256 interesToPay, uint256 timeOfCalc);

    /// @dev Function to calculate the interest paid to the user every second.
    function calcInterestForSecond(uint256 _amountDeposit, uint16 _interes) external pure returns(uint256 payPerSecond);

    ///@dev Function to calculate the total interest to pay to the user in 3 years.
    function calcTotalPayInterest(uint256 _endFoundersDate, uint256 _timeOfCalc, uint256 _payPerSecond) external pure returns(uint256 totalInterest);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/// @title Founders Interface.
/// @author Panoram Finance.
/// @notice You can import this interface to access the statuses of a Founders withdraw.
interface IFounders {

    /// @dev Enum to declare the Status of a Founders withdrawal
    enum Status{
        complete, //0
        pending, //1
        pendrewards,//2
        cancelled //3
    }

    struct Data {
        uint256 amount; // Total amount invested
        uint256 claimedHistory; //history Amount claimed.
        uint96 depositTime;
        uint96 withdrawTime; 
        uint96 endFoundersDate; // the Date on which the 3 years are fulfilled.
        uint32 totalNFTs; // Number of NTFs bought by the user.
        uint256 nftIds; // Bits [0..127] => 'Start  id' / Bits [128..255] => 'Final  id'
        bool isFullyPaid; // True cuando la deuda fue pagada por voha.
    }

    struct Payments {
        uint256 capitalRedeemed; // Capital cobrado
        uint256 pendRewards; // pending Rewards for withdrawals.
        uint256 claimed; //Amount of rewards already redeemed
        uint256 payPerSecond; // how much the user earn per second.
        uint256 totalToPaid; // total interest to paid (18% * 3 years).
        uint96 lastCalcTime; // Date of the last time the interest was calculate.
        uint96 claimTime; // last time the user claim the rewards
        uint96 lastSetClaimRewards; // the date when the user set a rewards claim.
        bool allInteresPaid; // true cuando se han pagado todos los intereses
    }

    struct NFTInfo {
        uint256 quantity;
        // - [0..127]  'Start  id'
        // - [128..255] 'Final  id'
        uint256 nftIds;
    }

}