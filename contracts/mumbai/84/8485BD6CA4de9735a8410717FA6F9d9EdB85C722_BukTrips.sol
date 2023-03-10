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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ISupplierContract.sol";
import "./IBukSupplierDeployer.sol";
import "./IBukSupplierUtilityDeployer.sol";
import "./ITreasury.sol";
import "./ISupplierContractUtility.sol";

/**
* @title BUK Protocol Factory Contract
* @author BUK Technology Inc
* @dev Genesis contract for managing all operations of the BUK protocol including ERC1155 token management for room-night NFTs and underlying sub-contracts such as Supplier, Hotel, Treasury, and Marketplace.
*/
contract BukTrips is AccessControl, ReentrancyGuard {

    /**
    * @dev Enum for booking statuses.
    * @var BookingStatus.nil         Booking has not yet been initiated.
    * @var BookingStatus.booked      Booking has been initiated but not yet confirmed.
    * @var BookingStatus.confirmed   Booking has been confirmed.
    * @var BookingStatus.cancelled   Booking has been cancelled.
    * @var BookingStatus.expired     Booking has expired.
    */
    enum BookingStatus {nil, booked, confirmed, cancelled, expired}

    /**
    * @dev Addresses for the Buk wallet, currency, treasury, supplier deployer, and utility deployer.
    * @dev address buk_wallet        Address of the Buk wallet.
    * @dev address currency          Address of the currency.
    * @dev address treasury          Address of the treasury.
    * @dev address supplier_deployer Address of the supplier deployer.
    * @dev address utility_deployer  Address of the utility deployer.
    */
    address private bukWallet;
    address private currency;
    address private treasury;
    address public supplierDeployer;
    address public utilityDeployer;
    /**
    * @dev Commission charged on bookings.
    */
    uint8 private commission = 5;

    /**
    * @dev Counters.Counter supplierIds   Counter for supplier IDs.
    * @dev Counters.Counter bookingIds    Counter for booking IDs.
    */
    uint256 private _supplierIds;
    uint256 private _bookingIds;

    /**
    * @dev Struct for booking details.
    * @var uint256 id                Booking ID.
    * @var BookingStatus status      Booking status.
    * @var uint256 tokenID           Token ID.
    * @var address owner             Address of the booking owner.
    * @var uint256 supplierId        Supplier ID.
    * @var uint256 checkin          Check-in date.
    * @var uint256 checkout          Check-out date.
    * @var uint256 total             Total price.
    * @var uint256 baseRate          Base rate.
    */
    struct Booking {
        uint256 id;
        BookingStatus status;
        uint256 tokenID;
        address owner;
        uint256 supplierId;
        uint256 checkin;
        uint256 checkout;
        uint256 total;
        uint256 baseRate;
    }
    /**
    * @dev Struct for supplier details.
    * @var uint256 id                Supplier ID.
    * @var bool status               Supplier status.
    * @var address supplierContract Address of the supplier contract.
    * @var address supplierOwner    Address of the supplier owner.
    * @var address utility_contract  Address of the utility contract.
    */
    struct SupplierDetails {
        uint256 id;
        bool status;
        address supplierContract;
        address supplierOwner;
        address utilityContract;
    }

    /**
    * @dev Constant for the role of admin
    */
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    /**
    * @dev mapping(uint256 => Booking) bookingDetails   Mapping of booking IDs to booking details.
    */
    mapping(uint256 => Booking) public bookingDetails; //bookingID -> Booking Details
    /**
    * @dev mapping(uint256 => mapping(uint256 => uint256)) timeLocks   Mapping of booking IDs to time locks.
    */
    mapping(uint256 => mapping(uint256 => uint256)) public timeLocks; //bookingID -> Booking Details
    /**
    * @dev mapping(uint256 => SupplierDetails) suppliers   Mapping of supplier IDs to supplier details.
    */
    mapping(uint256 => SupplierDetails) public suppliers; //supplierID -> Contract Address

    /**
    * @dev Emitted when the deployers are set.
    */
    event SetDeployers(address indexed supplierDeployer, address indexed utilityDeployer);
    /**
    * @dev Emitted when the commission is set.
    */
    event SetCommission(uint256 indexed commission);
    /**
    * @dev Event to safe transfer NFT
    */
    event GrantSupplierFactoryRole(address indexed oldFactory, address indexed newFactory);
    /**
    * @dev Emitted when nft status is toggled.
    */
    event ToggleNFT(uint256 indexed supplierId, uint256 indexed nftId);
    /**
    * @dev Emitted when the supplier details are updated.
    */
    event UpdateSupplierDetails(uint256 indexed id, bytes32 name, string indexed contractName);
    /**
    * @dev Emitted when the supplier is registered.
    */
    event RegisterSupplier(uint256 indexed id, address indexed supplierContract, address indexed utilityContract);
    /**
    * @dev Emitted when token uri is set.
    */
    event SetTokenURI(uint256 indexed supplierId, uint256 indexed nftId, string indexed uri);
    /**
    * @dev Emitted when supplier contract uri is set.
    */
    event SetContractURI(uint256 indexed supplierId, string indexed uri);
    /**
    * @dev Emitted when time lock is set for an NFT.
    */
    event SetTimeLock(uint256 indexed supplierId, uint256 indexed nftId, uint256 indexed time);
    /**
    * @dev Emitted when treasury is updated.
    */
    event SetTreasury(address indexed treasuryContract);
    /**
    * @dev Emitted when single room is booked.
    */
    event BookRoom(uint256 indexed booking);
    /**
    * @dev Emitted when multiple rooms are booked together.
    */
    event BookRooms(uint256[] indexed bookings, uint256 indexed total, uint256 indexed commission);
    /**
    * @dev Emitted when booking refund is done.
    */
    event BookingRefund(uint256 indexed total, address indexed owner);
    /**
    * @dev Emitted when room bookings are confirmed.
    */
    event ConfirmRooms(uint256[] indexed bookings, bool indexed status);
    /**
    * @dev Emitted when room bookings are checked out.
    */
    event CheckoutRooms(uint256[] indexed bookings, bool indexed status);
    /**
    * @dev Emitted when room bookings are cancelled.
    */
    event CancelRoom(uint256 indexed booking, bool indexed status);

    /**
    * @dev Modifier to check the access to toggle NFTs.
    */
    modifier onlyAdminOwner(uint256 _bookingId) {
        require(((hasRole(ADMIN_ROLE, _msgSender())) || (_msgSender()==bookingDetails[_bookingId].owner)), "Caller does not have access");
        _;
    }

    /**
    * @dev Constructor to initialize the contract
    * @param _treasury Address of the treasury.
    * @param _currency Address of the currency.
    * @param _bukWallet Address of the Buk wallet.
    */
    constructor (address _treasury, address _currency, address _bukWallet) {
        currency = _currency;
        treasury = _treasury;
        bukWallet = _bukWallet;
        _grantRole(ADMIN_ROLE, _msgSender());
    }

    /**
    * @dev Function to set the deployer contracts.
    * @param _supplierDeployer Address of the supplier deployer contract.
    * @param _utilityDeployer Address of the utility deployer contract.
    * @notice Only admin can call this function.
    */
    function setDeployers(address _supplierDeployer, address _utilityDeployer) external onlyRole(ADMIN_ROLE) {
        supplierDeployer = _supplierDeployer;
        utilityDeployer = _utilityDeployer;
        emit SetDeployers(_supplierDeployer, _utilityDeployer);
    }

    /**
    * @dev Function to update the treasury address.
    * @param _treasury Address of the treasury.
    */
    function setTreasury(address _treasury) external onlyRole(ADMIN_ROLE) {
        treasury = _treasury;
        emit SetTreasury(_treasury);
    }

    /**
    * @dev Function to update the token uri.
    * @param _supplierId Supplier Id.
    * @param _tokenId Token Id.
    */
    function setTokenUri(uint _supplierId, uint _tokenId, string memory _newUri) external onlyRole(ADMIN_ROLE) {
        ISupplierContract(suppliers[_supplierId].supplierContract).setURI(_tokenId, _newUri);
        emit SetTokenURI(_supplierId,_tokenId,_newUri);
    }

    /**
    * @dev Function to update the contract uri.
    * @param _supplierId Supplier Id.
    */
    function setContractUri(uint _supplierId, string memory _newUri) external onlyRole(ADMIN_ROLE) {
        ISupplierContract(suppliers[_supplierId].supplierContract).setContractURI(_newUri);
        emit SetContractURI(_supplierId,_newUri);
    }

    /**
    * @dev Function to grant the factory role to a given supplier
    * @param _newFactoryContract address: New factory contract of the supplier contract
    * @notice This function can only be called by a contract with `ADMIN_ROLE`
    */
    function grantSupplierFactoryRole(uint256 _supplierId, address _newFactoryContract) external onlyRole(ADMIN_ROLE)  {
        ISupplierContract(suppliers[_supplierId].supplierContract).grantFactoryRole(_newFactoryContract);
        emit GrantSupplierFactoryRole(address(this), _newFactoryContract);
    }

    /**
    * @dev Function to update the supplier details.
    * @param _supplierId ID of the supplier.
    * @param _name New name of the supplier.
    * @param _contractName New name of the supplier contract.
    */
    function updateSupplierDetails(uint256 _supplierId, bytes32 _name, string memory _contractName) external onlyRole(ADMIN_ROLE) {
        ISupplierContract(suppliers[_supplierId].supplierContract).updateSupplierDetails(_name, _contractName);
        emit UpdateSupplierDetails(_supplierId,_name,_contractName);
    }

    /**
    * @dev Function to set the Buk commission percentage.
    * @param _commission Commission percentage.
    */
    function setCommission(uint8 _commission) external onlyRole(ADMIN_ROLE) {
        commission = _commission;
        emit SetCommission(_commission);
    }
    
    /**
    * @dev Function to set the time lock for NFT Transfer.
    * @param _supplierId ID of the supplier.
    * @param _nftId ID of the NFT.
    * @param _timeLock Time lock in hours.
    */
    function setTransferLock(uint256 _supplierId, uint256 _nftId, uint256 _timeLock) external onlyRole(ADMIN_ROLE) {
        timeLocks[_supplierId][_nftId] = 3600 * _timeLock;
        emit SetTimeLock(_supplierId, _nftId, _timeLock);
    }

    /** 
    * @dev Function to toggle the NFT status.
    * @param _id ID of the NFT.
    * @param status Status of the NFT.
    * @notice Only admin or the owner of the NFT can call this function.
    */
    function toggleNFTStatus(uint _id, bool status) external nonReentrant() onlyAdminOwner(_id) {
        require((bookingDetails[_id].tokenID > 0), "NFT does not exist");
        uint256 threshold = bookingDetails[_id].checkin - timeLocks[bookingDetails[_id].supplierId][_id];
        require((block.timestamp < threshold), "NFT toggle not possible now");
        ISupplierContract(suppliers[bookingDetails[_id].supplierId].supplierContract).toggleNFTStatus(_id, status);
        emit ToggleNFT(bookingDetails[_id].supplierId, _id);
    }

    /**
    * @dev Function to register a supplier.
    * @param _contractName Name of the supplier contract.
    * @param _name Name of the supplier.
    * @param _supplierOwner Address of the supplier owner.
    * @param _contractUri URI of the supplier contract.
    * @notice Only admin can call this function.
    */
    function registerSupplier(string memory _contractName, bytes32 _name, address _supplierOwner, string memory _contractUri) external onlyRole(ADMIN_ROLE) {
        ++_supplierIds;
        address utilityContractAddr = IBukSupplierUtilityDeployer(utilityDeployer).deploySupplierUtility(_contractName,_supplierIds,_name, _contractUri);
        address supplierContractAddr = IBukSupplierDeployer(supplierDeployer).deploySupplier(_contractName, _supplierIds,_name, _supplierOwner, utilityContractAddr, _contractUri);
        ISupplierContractUtility(utilityContractAddr).grantSupplierRole(supplierContractAddr);
        suppliers[_supplierIds].id = _supplierIds;
        suppliers[_supplierIds].status = true;
        suppliers[_supplierIds].supplierContract = supplierContractAddr;
        suppliers[_supplierIds].supplierOwner = _supplierOwner;
        suppliers[_supplierIds].utilityContract = utilityContractAddr;
        emit RegisterSupplier(_supplierIds, supplierContractAddr, utilityContractAddr);
    }

    /** 
    * @dev Function to book rooms.
    * @param _supplierId ID of the supplier.
    * @param _count Number of rooms to be booked.
    * @param _total Total amount to be paid.
    * @param _baseRate Base rate of the room.
    * @param _checkin Checkin date.
    * @param _checkout Checkout date.
    * @return ids IDs of the bookings.
    * @notice Only registered Suppliers' rooms can be booked.
    */
    function bookRoom(uint256 _supplierId, uint256 _count, uint256[] memory _total, uint256[] memory _baseRate, uint256 _checkin, uint256 _checkout) external nonReentrant() returns (bool) {
        require(suppliers[_supplierId].status, "Supplier not registered");
        require(((_total.length == _baseRate.length) && (_total.length == _count) && (_count>0)), "Array sizes mismatch");
        uint256[] memory bookings = new uint256[](_count);
        uint total = 0;
        uint commissionTotal = 0;
        for(uint8 i=0; i<_count;++i) {
            ++_bookingIds;
            bookingDetails[_bookingIds] = Booking(_bookingIds, BookingStatus.booked, 0, _msgSender(), _supplierId, _checkin, _checkout, _total[i], _baseRate[i]);
            bookings[i] = _bookingIds;
            total+=_total[i];
            commissionTotal+= _baseRate[i]*commission/100;
            emit BookRoom(_bookingIds);
        }
        return _bookingPayment(commissionTotal, total, bookings);
    }

    /** 
    * @dev Function to refund the amount for the failure scenarios.
    * @param _supplierId ID of the supplier.
    * @param _ids IDs of the bookings.
    * @notice Only registered Suppliers' rooms can be booked.
    */
    function bookingRefund(uint256 _supplierId, uint256[] memory _ids, address _owner) external onlyRole(ADMIN_ROLE) {
        require(suppliers[_supplierId].status, "Supplier not registered");
        uint256 len = _ids.length;
        require((len>0), "Array is empty");
        for(uint8 i=0; i<len; ++i) {
            require(bookingDetails[_ids[i]].owner == _owner, "Check the booking owner");
            require(bookingDetails[_ids[i]].status == BookingStatus.booked, "Check the Booking status");
        }
        uint total = 0;
        for(uint8 i=0; i<len;++i) {
            bookingDetails[_ids[i]].status = BookingStatus.cancelled;
            total+= bookingDetails[_ids[i]].total + bookingDetails[_ids[i]].baseRate*commission/100;
        }
        ITreasury(treasury).cancelUSDCRefund(total, _owner);
        emit BookingRefund(total, _owner);
    }
    
    /**
    * @dev Function to confirm the room bookings.
    * @param _supplierId ID of the supplier.
    * @param _ids IDs of the bookings.
    * @param _uri URIs of the NFTs.
    * @param _status Status of the NFT.
    * @notice Only registered Suppliers' rooms can be confirmed.
    * @notice Only the owner of the booking can confirm the rooms.
    * @notice The number of bookings and URIs should be same.
    * @notice The booking status should be booked to confirm it.
    * @notice The NFTs are minted to the owner of the booking.
    */
    function confirmRoom(uint256 _supplierId, uint256[] memory _ids, string[] memory _uri, bool _status) external nonReentrant() {
        require(suppliers[_supplierId].status, "Supplier not registered");
        uint256 len = _ids.length;
        for(uint8 i=0; i<len; ++i) {
            require(bookingDetails[_ids[i]].status == BookingStatus.booked, "Check the Booking status");
            require(bookingDetails[_ids[i]].owner == _msgSender(), "Only booking owner has access");
        }
        require((len == _uri.length), "Check Ids and URIs size");
        require(((len > 0) && (len < 11)), "Not in max - min booking limit");
        ISupplierContract _supplierContract = ISupplierContract(suppliers[_supplierId].supplierContract);
        for(uint8 i=0; i<len; ++i) {
            bookingDetails[_ids[i]].status = BookingStatus.confirmed;
            _supplierContract.mint(_ids[i], bookingDetails[_ids[i]].owner, 1, "", _uri[i], _status);
            bookingDetails[_ids[i]].tokenID = _ids[i];
        }
        emit ConfirmRooms(_ids, true);
    }

    /**
    * @dev Function to checkout the rooms.
    * @param _supplierId ID of the supplier.
    * @param _ids IDs of the bookings.
    * @notice Only registered Suppliers' rooms can be checked out.
    * @notice Only the admin can checkout the rooms.
    * @notice The booking status should be confirmed to checkout it.
    * @notice The Active Booking NFTs are burnt from the owner's account.
    * @notice The Utility NFTs are minted to the owner of the booking.
    */
    function checkout(uint256 _supplierId, uint256[] memory _ids ) external onlyRole(ADMIN_ROLE)  {
        require(suppliers[_supplierId].status, "Supplier not registered");
        uint256 len = _ids.length;
        require(((len > 0) && (len < 11)), "Not in max-min booking limit");
        for(uint8 i=0; i<len; ++i) {
            require(bookingDetails[_ids[i]].status == BookingStatus.confirmed, "Check the Booking status");
        }
        for(uint8 i=0; i<len;++i) {
            bookingDetails[_ids[i]].status = BookingStatus.expired;
            ISupplierContract(suppliers[_supplierId].supplierContract).burn(bookingDetails[_ids[i]].owner, _ids[i], 1, true);
        }
        emit CheckoutRooms(_ids, true);
    }

    /** 
    * @dev Function to cancel the room bookings.
    * @param _supplierId ID of the supplier.
    * @param _id ID of the booking.
    * @param _penalty Penalty amount to be refunded.
    * @param _refund Refund amount to be refunded.
    * @param _charges Charges amount to be refunded.
    * @notice Only registered Suppliers' rooms can be cancelled.
    * @notice Only the admin can cancel the rooms.
    * @notice The booking status should be confirmed to cancel it.
    * @notice The Active Booking NFTs are burnt from the owner's account.
    */
    function cancelRoom(uint256 _supplierId, uint256 _id, uint256 _penalty, uint256 _refund, uint256 _charges) external onlyRole(ADMIN_ROLE) {
        require(suppliers[_supplierId].status, "Supplier not registered");
        require((bookingDetails[_id].status == BookingStatus.confirmed), "Supplier not registered");
        require(((_penalty+_refund+_charges)<(bookingDetails[_id].total+1)), "Transfer amount exceeds total");
        ISupplierContract _supplierContract = ISupplierContract(suppliers[_supplierId].supplierContract);
        bookingDetails[_id].status = BookingStatus.cancelled;
        ITreasury(treasury).cancelUSDCRefund(_penalty, suppliers[bookingDetails[_id].supplierId].supplierOwner);
        ITreasury(treasury).cancelUSDCRefund(_refund, bookingDetails[_id].owner);
        ITreasury(treasury).cancelUSDCRefund(_charges, bukWallet);
        _supplierContract.burn(bookingDetails[_id].owner, _id, 1, false);
        emit CancelRoom(_id, true);
    }

    /** 
    * @dev Function to do the booking payment.
    * @param _commission Total BUK commission.
    * @param _total Total Booking Charge Excluding BUK commission.
    * @param _bookings Array of Booking Ids.
    */
    function _bookingPayment(uint256 _commission, uint256 _total, uint[] memory _bookings) internal returns (bool){
        bool collectCommission = IERC20(currency).transferFrom(_msgSender(), bukWallet, _commission);
        if(collectCommission) {
            bool collectPayment = IERC20(currency).transferFrom(_msgSender(), treasury, _total);
            if(collectPayment) {
                emit BookRooms(_bookings, _total, _commission);
                return true;
            } else {
                IERC20(currency).transferFrom(bukWallet, _msgSender(), _commission);
                IERC20(currency).transferFrom(treasury, _msgSender(), _total);
                return false;
            }
        } else {
            IERC20(currency).transferFrom(bukWallet, _msgSender(), _commission);
            return false;
        }

    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IBukSupplierDeployer {
    function deploySupplier(string memory _contractName, uint256 id, bytes32 _name, address _supplierOwner, address _utilityContractAddr, string memory _contractUri) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IBukSupplierUtilityDeployer {
    function deploySupplierUtility(string memory _contractName, uint256 id, bytes32 _name, string memory _contractUri) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface ISupplierContract {

    function updateSupplierDetails(bytes32 name, string memory contractName) external;

    function grantFactoryRole(address _factory_contract) external;

    function toggleNFTStatus(uint _id, bool status) external;

    function uri(uint256 id) external view returns (string memory);

    function mint(uint256 _id, address account, uint256 amount, bytes calldata data, string calldata _uri, bool _status) external returns (uint256);

    function burn(address account, uint256 id, uint256 amount, bool utility) external;

    function setContractURI(string memory _contractUri) external;

    function setURI(uint256 _id, string memory _newuri) external;

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface ISupplierContractUtility {

    function grantSupplierRole(address _supplierContract) external;

    function grantFactoryRole(address _factoryContract) external;

    function updateSupplierDetails(bytes32 _name, string memory _contractName) external;

    function mint(address account, uint256 _id, uint256 amount, string calldata _newuri, bytes calldata data) external;

    function setURI(uint256 _id, string memory _newuri) external;

    function setContractURI(string memory _contractUri) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface ITreasury {
    function cancelUSDCRefund(uint256 _total, address _account)  external;
    function cancelRefund(uint256 _total, address _account, address _currency) external;
}