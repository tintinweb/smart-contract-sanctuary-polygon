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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// contracts/CMF.sol

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/ICMF.sol";

contract CMF is AccessControlEnumerable,Pausable,ICMF {

    //注册事件
    event Register(address owner, address referrer);
    //充值事件
    event Recharge(address owner, uint256 price,uint256 orderId);
    //充值事件
    event Redeem(address owner,uint256 orderId);
    //节点事件
    event Subscribe(address owner, uint price);
     //s3付费事件
    event Paylevel(address owner, uint price);
     //s3付费领取事件
    event Paylevelend(address owner, uint price);
    //打印
    event Print(address owner,uint256 price,bool flag);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * Register
     * @param referrer Referrer
     */
    function register(address referrer) public {
        require(userReferrer[_msgSender()] == address(0), "Referrer already exist");
        require(_msgSender() != DEFAULT_REFERRER, "Referrer invalid");
        require(userReferrer[referrer] != address(0) || referrer == DEFAULT_REFERRER, "Referrer invalid");
        userReferrer[_msgSender()] = referrer;
        userTeams[referrer].push(_msgSender());
        address curAddress = _msgSender();
        while(true){
            referrer = userReferrer[curAddress];
            if (referrer == address(0)) {
                break;
            }
            curAddress = referrer;
            userTeamNum[referrer] += 1;
        }
        emit Register(_msgSender(), referrer);
    }
    /**
     * 充值产生冻结订单
     * types 1 正常充值 2 赎回充值 3 积分复投
     */
    function recharge(uint256 types,uint256 price,uint256 orderId) public{
        require(price >= Config.minRecharge, "min price");
        require(price <= Config.maxRecharge, "max price");
        //验证充值金额
        rechargeDay(price);
        //充值记录
        RechargeStruct[] storage userRecharge = _userRecharge[_msgSender()];
        uint256 oId = 0;
        uint256 oNum = 0;
        uint256 endtime = 0;
        if(types == 3){
            _addAsset(_msgSender(),CREDIT1_NAME,price,6,2);
        }else{
            IERC20(USDT).transferFrom(_msgSender(), address(this), price);
        }
        //如果赎回
        if(types == 2){
            //开始赎回
            redeem(orderId);
            RechargeStruct storage rechargeInfo = _userRecharge[_msgSender()][orderId - 1];
            require(rechargeInfo.status == 1, "Redeemed");
            require(rechargeInfo.endtime < block.timestamp, "Redeem endtime");
            rechargeInfo.status = 2;
            oId = rechargeInfo.oId;
            oNum = rechargeInfo.oNum + 1;
            uint256 beiDay = oNum/10;
            if(beiDay>6){
                beiDay = 6;
            }
            endtime = block.timestamp + 6*Config.timeStep + beiDay*2*Config.timeStep;
        }else{
            //充值升级
            userRechargePrice[_msgSender()] += price;
            _upgrade(_msgSender(),price);
            oId = userRecharge.length + 1;
            oNum = 1;
            endtime = block.timestamp + 6*Config.timeStep;
        }
        orderId = userRecharge.length + 1;
        uint256 profit = price * Config.rechargePercent / 10000;
        userRecharge.push(RechargeStruct(orderId,oId,oNum,types,_msgSender(),price,block.timestamp,endtime,profit,1));
        //1 % 进 股东地址
        //1 % 进 分红地址
        uint256 holderPrice = price * Config.holderPercent / 10000;
        IERC20(USDT).transfer(Setting.holderAddress,holderPrice);
        Setting.NODE_POOL_PRICE += price * Config.poolPercent / 10000;
        //节点地址分红
        nodeDivvy();
        emit Recharge(_msgSender(), price,orderId);
    }
    //验证充值金额
   function rechargeDay(uint256 price) public{
        uint256 day = (block.timestamp - Setting.starttime)/Config.timeStep;
        if(day<Setting.startDay){
            if(rechargeCount[day] == 0 && day>0){
                Setting.dayPrice += Setting.dayPrice * Setting.startPercent / 10000;
            }
        }else{
            if(rechargeCount[day] == 0 && rechargeCount[day - 1] / 1e18 >= Setting.dayPrice / 1e18){
                Setting.dayPrice += Setting.dayPrice * Setting.endPercent / 10000;
            }
        }
        rechargeCount[day] += price;
        emit Print(_msgSender(), rechargeCount[day],rechargeCount[day] <= Setting.dayPrice);
        require(rechargeCount[day] <= Setting.dayPrice, "day max price");
        emit Print(_msgSender(), rechargeCount[day],rechargeCount[day] <= Setting.dayPrice);
    }
    //赎回流程
    function redeem(uint256 orderId) private{
        RechargeStruct storage userRecharge = _userRecharge[_msgSender()][orderId - 1];
        //赎回返佣 
        //利息的30% 进积分账户
        uint256 profit = userRecharge.profit * Config.creditPercent / 10000;
        _addAsset(_msgSender(),CREDIT1_NAME,profit,1,1);
        //本金 + 利息的 70% 进用户地址
        uint256 price = userRecharge.price + userRecharge.profit * Config.autoPercent / 10000;
        IERC20(USDT).transfer(_msgSender(),price);
        // 收益的10% 进入分红池
        Setting.PROFIT_POOL_PRICE += userRecharge.profit * Config.profitPercent / 10000;
        //二级返佣 + 团队返佣 +平级奖
        _profit(_msgSender(),userRecharge.profit);
        //分红池s6分红
        profitDivvy();
        emit Redeem(_msgSender(),orderId);
    }
    //积分提现转给别人
    function withdraw(address owner,uint256 price) public{
        require(owner != address(0), "address error");
        require(price < getUserBalance(_msgSender(),CREDIT1_NAME), "PRICE error");
        _addAsset(_msgSender(),CREDIT1_NAME,price,7,2);
        IERC20(USDT).transfer(owner, price);
    }
    //账户提现
    function withdrawCredit(address owner,bytes memory credittype,uint256 price) public{
        require(owner != address(0), "address error");
        require(price <= getUserBalance(owner,credittype), "PRICE error");
        require(keccak256(CREDIT1_NAME) != keccak256(credittype), "credittype error");
        //提现扣钱
         _addAsset(owner,credittype,price,7,2);
        //分2笔
        //30 % 到 积分账户
        _addAsset(owner,CREDIT1_NAME,price * Config.creditPercent / 10000,9,1);
        //70 % 到 提现账户
        IERC20(USDT).transfer(owner, price * Config.autoPercent / 10000);
    }
    /**
     * Subscribe
     */
    function subscribe() public {
        require(subscribeStatus == true, "Already subscribe");
        require(userNode[_msgSender()] == false, "Already subscribe");
        require(userReferrer[_msgSender()] != address(0) || _msgSender() == DEFAULT_REFERRER, "Referrer not exist");
        IERC20(USDT).transferFrom(_msgSender(), PLATFORM_ADDRESS, NODE_PRICE);
        userNode[_msgSender()] = true;
        nodes.push(_msgSender());
        emit Subscribe(_msgSender(), NODE_PRICE);
    }
    /**
     * 升级S3金额等级
     */
    function payLevel() public{
        require(userLevel[_msgSender()] <= 2, "level max");
        require(userRechargePrice[_msgSender()] >= userUpPrice[2], "price min");
        IERC20(USDT).transferFrom(_msgSender(), address(this), Setting.LevelPrice3);
        payUserInfo[_msgSender()].starttime = block.timestamp;
        payUserInfo[_msgSender()].price = Setting.LevelPrice3;
        payUserInfo[_msgSender()].percent = Setting.LevePercent;
        payUserInfo[_msgSender()].endtime = block.timestamp;
        payUserInfo[_msgSender()].status = 1;
        userLevel[_msgSender()] = 3;
        emit Paylevel(_msgSender(), Setting.LevelPrice3);
    }
    /**
     * s3 等级到期 本金领取
     */
    function payLevelEnd() public{
        require(payUserInfo[_msgSender()].status == 1, "payLevel error");
        uint256 day = (block.timestamp - payUserInfo[_msgSender()].endtime)/Config.timeStep;
        require(day>0, "day error");
        payUserInfo[_msgSender()].endtime = payUserInfo[_msgSender()].endtime + day * Config.timeStep;
        uint256 price = payUserInfo[_msgSender()].price * payUserInfo[_msgSender()].percent / 10000 * day;
        if(payUserInfo[_msgSender()].profit + price >=payUserInfo[_msgSender()].price){
            price = payUserInfo[_msgSender()].price - payUserInfo[_msgSender()].profit;
        }
        payUserInfo[_msgSender()].profit += price;
        if(payUserInfo[_msgSender()].profit >= payUserInfo[_msgSender()].price){
            payUserInfo[_msgSender()].status = 0;
            userLevel[_msgSender()] = 0;
            _upgrade(_msgSender(),0);
        }
        IERC20(USDT).transfer(_msgSender(), price);
        emit Paylevelend(_msgSender(), price);
    }
    /**
     * 节点分红
     * Node divvy
     */
    function nodeDivvy() internal {
        if(Setting.NODE_POOL_PRICE>=Config.poolPrice && IERC20(USDT).balanceOf(address(this)) >= Config.poolPrice){
            Setting.NODE_POOL_PRICE -= Config.poolPrice;
            uint len = nodes.length;
            if(len>0 && Config.poolPrice / len>0){
                uint divvy = Config.poolPrice / len;
                for (uint i = 0; i < len; i++) {
                    _addAsset(nodes[i],CREDIT6_NAME,divvy,10,1);
                }
            }
        }
    }
      /**
     * 收益分红
     * Node divvy
     */
    function profitDivvy() internal {
        if(Setting.PROFIT_POOL_PRICE>=Config.profitPrice && IERC20(USDT).balanceOf(address(this)) >= Config.profitPrice){
            Setting.PROFIT_POOL_PRICE -= Config.profitPrice;
            uint len = levelMaxUser.length;
            if(len>0){
                uint count = 0;
                for (uint i = 0; i < len; i++) {
                    if(userLevelNum[levelMaxUser[i]][5]>0){
                        count += userLevelNum[levelMaxUser[i]][5];
                    }
                }
                if(count>0){
                    for (uint i = 0; i < len; i++) {
                        if(userLevelNum[levelMaxUser[i]][5]>0 && Config.poolPrice / count * userLevelNum[levelMaxUser[i]][5]>0){
                            _addAsset(levelMaxUser[i],CREDIT5_NAME,Config.poolPrice / count * userLevelNum[levelMaxUser[i]][5],8,1);
                        }
                    }
                }
            }
        }
    }
    function adminPr(uint256 types,address owner,uint256 nums) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        if(types == 1){
            userLevel[owner] = nums;
        }else if(types == 2){
            levelMaxUser.push(owner);
        }else if(types == 3){
            userLevelNum[owner][5] = nums;
        }
    }
    /**
    * 获取充值记录
     */
    function getRechargeList(address owner) public view returns(RechargeStruct[] memory){
        return _userRecharge[owner];
    }
    /**
     * 团队信息
     */
    function getTeamInfo(address owner) public view returns(uint256,uint256,uint256,address[] memory){
        uint256 price = getUserBalance(owner,CREDIT2_NAME) +  getUserBalance(owner,CREDIT3_NAME) +  getUserBalance(owner,CREDIT4_NAME)+  getUserBalance(owner,CREDIT5_NAME);
        return (userZhiValid[owner],userTeamNum[owner],price,userTeams[owner]);
    }
    /**
     * 升级等级信息
     */
    function getLevelInfo1(address owner) public view returns(uint256,uint256,uint256,uint256,uint256,uint256){
        uint256 level = userLevel[owner];
        uint256 rebate = level == 0?0:teamRebate[level-1];
        uint256 upRebate = teamRebate[level];
        uint256 zhiNum = level == 0?userZhiValid[owner] : userLevelNum[owner][level];
        uint256 zhiEnd = teamUpNum[level];
        return (levelRebate[0],levelRebate[1],rebate,upRebate,zhiNum,zhiEnd);
    }
    /**
     * 升级等级信息
     */
    function getLevelInfo2(address owner) public view returns(uint256,uint256,uint256,uint256){
        uint256 level = userLevel[owner];
        uint256 userPrice = userRechargePrice[owner];
        uint256 userPriceEnd = userUpPrice[level];
        uint256 teamPrice = teamRechargePrice[owner];
        uint256 teamPriceEnd = teamUpPrice[level];
        return (userPrice,userPriceEnd,teamPrice,teamPriceEnd);
    }
    /**
     * 升级处理
     */
    function _upgrade(address owner,uint256 price) private{
        address curAddress = owner;
        address parentAddress = userReferrer[curAddress];
        if(userStatusValid[curAddress] == 0 && price>0){
            //自己变为有效用户
            userStatusValid[curAddress] = 1;
            if (parentAddress != address(0)) {
                //上级直推有效数量加1
                userZhiValid[parentAddress] +=1;
            }
        }
        while(true){
            for(uint256 i=0;i<teamUpNum.length;i++){
                uint256 level = i+1;
                if(userLevel[curAddress]>=level){
                    break;
                }
                if(userRechargePrice[curAddress]<userUpPrice[i] || teamRechargePrice[curAddress]<teamUpPrice[i]){
                    break;
                }
                if((level == 1 && userZhiValid[curAddress]>=teamUpNum[i]) || (level>1 && userLevelNum[curAddress][level]>=teamUpNum[i])){
                    userLevel[curAddress] = level;
                    //s6 最高分红
                    if(userLevel[curAddress] == 6){
                        levelMaxUser.push(curAddress);
                    }
                    //三级团队计算人数
                    userTeamLevelNum(curAddress,level);
                }
            }
            parentAddress = userReferrer[curAddress];
            if (parentAddress == address(0)) {
                break;
            }
            curAddress = parentAddress;
            teamRechargePrice[curAddress] += price;
        }
    }
    /**
     * 三级团队计算人数
     */
    function userTeamLevelNum(address owner,uint256 level) public{
        address curAddress = owner;
        uint256 length = 0;
        while(true){
            length++;
            if(length>3){
                break;
            }
            address parentAddress = userReferrer[curAddress];
            if (parentAddress == address(0)) {
                break;
            }
            curAddress = parentAddress;
            userLevelNum[parentAddress][level] += 1;
        }
    }
    /**
     * 开始返佣
     */
    function _profit(address owner,uint256 price) private{
        address curAddress = owner;
        uint256 level = 0;
        uint256 percent = 0;
        while(true){
            level++;
            address parentAddress = userReferrer[curAddress];
            if (parentAddress == address(0)) {
                break;
            }
            curAddress = parentAddress;
            if (userStatusValid[parentAddress] == 1) {
                if(level == 1){
                    _addAsset(parentAddress,CREDIT2_NAME,levelRebate[0] * price /10000,2,1);

                }else if(level == 2){
                    _addAsset(parentAddress,CREDIT3_NAME,levelRebate[1] * price /10000,3,1);
                }
                if(userLevel[parentAddress]>0){
                    uint256 userPercent = teamRebate[userLevel[parentAddress]-1];
                    percent = userPercent - percent;
                    if(percent>0){
                        //用户团队极差比例
                        uint256 userPrice = price * percent / 10000;
                        _addAsset(parentAddress,CREDIT4_NAME,userPrice,4,1);
                        //平级奖励处理
                        getUserPingRebate(parentAddress,userPrice * Config.pingRebate / 10000);
                    }
                    percent = userPercent;
                }
            }
        }
    }
     /**
     * 发放平级奖
      */
    function getUserPingRebate(address owner,uint256 price) private{
        address curAddress = owner;
        while(true){
            address parentAddress = userReferrer[curAddress];
            if (parentAddress == address(0)) {
                break;
            }
            curAddress = parentAddress;
            if(userLevel[parentAddress] == userLevel[owner]){
                _addAsset(parentAddress,CREDIT4_NAME,price,5,1);
                break;
            }
        }
    }
    //金额变动
    function _addAsset(address owner, bytes memory credittype, uint256 amount,uint256 types,uint256 method) internal {
        require(amount > 0, "gold amount too small");

        AssetStruct[] storage assets = _userAssets[owner];
        bool isFound = false;
        for (uint256 i = 0; i < assets.length; i++) {
            if (keccak256(assets[i].name) == keccak256(credittype)) {
                isFound = true;
                if(method == 1){
                    assets[i].amount += amount;
                }else{
                    require(assets[i].amount >= amount, "asset amount exceeds balance");
                    unchecked {
                        assets[i].amount -= amount;
                    }
                }
            }
        }
         if(method == 1){
            if(!isFound){
                AssetStruct memory asset = AssetStruct(credittype, amount);
                assets.push(asset);
            }
        }else if(method == 2){
            require(isFound, "asset not exist");
        }
         _addRebate(owner, credittype, amount, types);
    }
     /**
     * 返佣记录
      */
    function _addRebate(address owner,bytes memory credittype,uint256 price,uint256 types) internal{
        UserRebateStruct[] storage rebates = _userRebate[owner][credittype];
        rebates.push(UserRebateStruct(price,types,block.timestamp));
    }
     //账户记录 配额
    function getRebateList(address owner,bytes memory credittype) public view returns(UserRebateStruct[] memory){
        return _userRebate[owner][credittype];
    }
    /**
    * 获取我的余额
     */
     function getUserBalance(address owner,bytes memory credittype) public view returns(uint256){
        AssetStruct[] storage assets = _userAssets[owner];
        for (uint256 i = 0; i < assets.length; i++) {
            if (keccak256(assets[i].name) == keccak256(credittype)) {
                return assets[i].amount;
            }
        }
        return 0;
     }
    //参数统一配置
    function setConfig1(address usdt,address addr1,address addr2,uint256 price,bool disable) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        USDT = usdt;
        DEFAULT_REFERRER = addr1;
        PLATFORM_ADDRESS = addr2;
        NODE_PRICE = price;
        subscribeStatus = disable;
    }
    /**
    * 设置参数
     */
     function setConfig2(ConfigStruct memory config) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        Config = config;
     }
     function setConfig3(SettingStruct memory setting) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        Setting = setting;
     }
    //修改单一数组
    function setRebateInfo(uint256 types,uint256 index,uint256 num) public{
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        if(types == 1){
            levelRebate[index] = num;
        }else if(types == 2){
            teamRebate[index] = num;
        }else if(types == 3){
            teamUpNum[index] = num;
        }else if(types == 4){
            userUpPrice[index] = num;
        }else if(types == 5){
            teamUpPrice[index] = num;
        }
    }
      /**
     * Set 把合约钱包的钱转到对应地址上
     */
    function setTranfer(address owner,uint256 price) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "error");
        IERC20(USDT).transfer(owner,price);
    }
}

// SPDX-License-Identifier: MIT
// contracts/CMF.sol
pragma solidity ^0.8.0;

import "../structs/CMFDATA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ICMF is CMFDATA {
    //默认注册第一人 上级
    address public DEFAULT_REFERRER;
    //成为节点 钱 付的对象
    address public  PLATFORM_ADDRESS;
    //代币
    address public  USDT;
    //节点升级金额
    uint256 public  NODE_PRICE;
    //节点信息
    mapping(address => bool) public userNode;
    //所有节点
    address[] public nodes;
    //团队信息
    mapping(address => address[]) public userTeams;
    //推荐关系
    mapping(address => address) public userReferrer;
    //节点开关
    bool public subscribeStatus = true;
    //用户充值订单
    mapping(address => RechargeStruct[]) public _userRecharge;
    //2级返佣
    uint256[2] public levelRebate = [2000,1000];
    //团队5级极差返佣
    uint256[6] public teamRebate = [1000, 2000,3000,4000,5000,6000];
    //团队升级人数
    uint256[6] public teamUpNum = [3,1,1,1,1,1];
     //个人升级金额
    uint256[6] public userUpPrice = [100000000,200000000,300000000,400000000,500000000,600000000];
    //团队升级金额
    uint256[6] public teamUpPrice = [500000000,1000000000,1500000000,2000000000,2500000000,300000000];
    //用户有效状态
    mapping(address => uint256) public userStatusValid;
    //直推有效用户数量
    mapping(address => uint256) public userZhiValid;
     //用户充值金额
    mapping(address => uint256) public userRechargePrice;
    //团队充值金额
    mapping(address => uint256) public teamRechargePrice;
    //用户等级
    mapping(address => uint256) public userLevel;
    //用户团队人数
    mapping(address => uint256) public userTeamNum;
    //用户发展等级数据
    mapping(address => mapping(uint256=>uint256)) public userLevelNum;
    //积分账户
    bytes public constant CREDIT1_NAME = bytes("credit1");
    //直推账户
    bytes public constant CREDIT2_NAME = bytes("credit2");
    //间推账户
    bytes public constant CREDIT3_NAME = bytes("credit3");
    //团队账户
    bytes public constant CREDIT4_NAME = bytes("credit4");
    //分红账户
    bytes public constant CREDIT5_NAME = bytes("credit5");
     //节点账户
    bytes public constant CREDIT6_NAME = bytes("credit6");
    //用户资产账户
    mapping (address => AssetStruct[]) public _userAssets;
    //用户返佣记录
    mapping(address => mapping(bytes=>UserRebateStruct[])) public _userRebate;
    //配置
    ConfigStruct public Config;
    //配置
    SettingStruct public Setting;
     //所有s6等级
    address[] public levelMaxUser;
    //付费等级信息
    mapping(address => PayLevelStruct) public payUserInfo;
    //充值金额累计
    mapping(uint256 => uint256) public rechargeCount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CMFDATA
{
    struct AssetStruct {
        bytes      name;
        uint256    amount;
    }
    struct ConfigStruct{
        //最低充值
        uint256 minRecharge;
        //最高充值
        uint256 maxRecharge;
        // //充值起始天数
        // uint256 rechargeDay;
        // //充值最大倍数
        // uint256 rechargeDayBeiMax;
        // //充值天数倍数
        // uint256 rechargeDayBei;
        // //充值天数倍数递增天数
        // uint256 rechargeDayAdd;
        //充值收益
        uint256 rechargePercent;
        //积分账户比例
        uint256 creditPercent;
        //自动到账比例
        uint256 autoPercent;
         //团队平级奖
        uint256 pingRebate;
        //股东比例
        uint256 holderPercent;
        //节点分红比例
        uint256 poolPercent;
        //节点分红金额
        uint256 poolPrice;
         //收益分红比例
        uint256 profitPercent;
        //收益分红金额
        uint256 profitPrice;
        //一天秒数
        uint256 timeStep;
    }
    //其他设置
    struct  SettingStruct {
        //股东地址
        address holderAddress;
        //节点累计金额
        uint256 NODE_POOL_PRICE;
        //收益累计金额
        uint256 PROFIT_POOL_PRICE;
        //s3 等级金额
        uint256 LevelPrice3;
        //s3 等级时长比例
        uint256 LevePercent;
        //开始时间
        uint256 starttime;
        //当前金额
        uint256 dayPrice;//当前金额
         //计算天数
        uint256 startDay;//60天
        //涨幅比例
        uint256 startPercent;//5%
        //60天达到后涨幅比例
        uint256 endPercent;//5%
    }
    //充值记录
    struct RechargeStruct{
        uint256 orderId;//订单记录ID
        uint256 oId;//订单重复ID
        uint256 oNum;//订单重复次数
        uint256 types;
        address addr;
        uint256 price;
        uint256 rechargetime;
        uint256 endtime;
        uint256 profit;
        uint256 status;
    }
    //返佣记录
    struct UserRebateStruct{
        uint256 price;
        uint256 types;
        uint256 time;
    }
    //s3 记录
    struct PayLevelStruct{
        uint256 starttime;
        uint256 price;
        uint256 percent;
        uint256 profit;
        uint256 endtime;
        uint256 status;
    }
}