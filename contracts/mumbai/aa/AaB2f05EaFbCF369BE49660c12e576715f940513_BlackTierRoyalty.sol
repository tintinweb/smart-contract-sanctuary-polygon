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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IColleCollection is IERC721 {
    function mint(string memory uri, address receiver) external;

    function updateSaleMetadata(uint256 _tokenId, string memory uri) external;

    function getSaleMetadata(uint256 _tokenId) external view returns (string memory);

    function isSaleMetadataSet(uint256 _tokenId) external view returns (bool);

    function permitApprove(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _deadline,
        bytes memory _signature
    ) external;

    function permitSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _deadline,
        bytes memory _signature
    ) external;

    ////
    // Adding back transfer to allow users the ability to transfer manually if needed.
    // This breaks mirroring assets the same way transferFrom does, however only when intentional.
    // It avoids accidental breaking, as 3rd party market places will not assume these functions exist.
    ////
    function transfer(address _from, address _to, uint256 _tokenId) external;

    ////
    // Adding back transfer to allow users the ability to transfer manually if needed.
    // This breaks mirroring assets the same way safeTransferFrom does, however only when intentional.
    // It avoids accidental breaking, as 3rd party market places will not assume these functions exist.
    ////
    function safeTransfer(address _from, address _to, uint256 _tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IColleCollection.sol";

interface ICollectionRegistry {
    function registerCollection(address _collection) external;

    function unregisterCollection(address _collection) external;

    function isERC721Registered(address _collection) external view returns (bool);

    function getCollection(address _collection) external view returns (IColleCollection);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../MarketHubRegistrar.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BaseCurrency is MarketHubRegistrar {
    IERC20 erc20;

    constructor(address _erc20) {
        erc20 = IERC20(_erc20);
    }

    function getERC20() public view returns (IERC20) {
        return erc20;
    }

    function getEstimatedUSDCValue(uint256 _amount) public view virtual returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./BaseCurrency.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICurrencyRegistry {
    function registerERC20(address _currency) external;

    function unregisterERC20(address _currency) external;

    function getCurrencyByERC20(address _erc20) external view returns (BaseCurrency);

    function getERC20ByCurrency(address _currency) external view returns (IERC20);

    function isERC20Registered(address _erc20) external view returns (bool);

    function getERC20s() external view returns (address[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../IMarketHubRegistrar.sol";

interface IEscrow is IMarketHubRegistrar {
    enum State {
        AwaitingSettlement,
        AwaitingERC20Deposit,
        PendingSale,
        ProcessingSale,
        ShippingToBuyer,
        Received,
        ShippingToColleForAuthentication,
        ColleProcessingSale,
        ShippingToColleForDispute,
        IssueWithDelivery,
        IssueWithProduct,
        SaleCancelled,
        SaleSuccess
    }

    struct Sale {
        uint256 id;
        address buyer;
        address spender;
        address erc20;
        uint256 price;
        address seller;
        address erc721;
        uint256 tokenId;
        State state;
        uint256 createdTimestamp;
        uint256 receivedTimestamp;
    }

    function setBuyerChallengeWndow(uint256 _hours) external;

    function buyerChallengeWindow() external view returns (uint256);

    function createSale(
        address buyer,
        address spender,
        address erc20,
        uint256 price,
        address seller,
        address erc721,
        uint256 tokenId,
        bool payNow
    ) external;

    function getSale(uint256 saleId) external view returns (Sale memory);

    function hasActiveSale(address erc721, uint256 tokenId) external view returns (bool);

    function updateSale(uint256 saleId, State newState) external;

    function permitUpdateSale(
        address signer,
        uint256 saleId,
        State newState,
        uint256 deadline,
        bytes memory signature
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IEscrow.sol";

interface IEscrowRegistry {
    function registerEscrow(address _escrow) external;

    function unregisterEscrow() external;

    function getEscrow() external view returns (IEscrow);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./markets/IMarketRegistry.sol";
import "./currencies/ICurrencyRegistry.sol";
import "./royalties/IRoyaltyRegistry.sol";
import "./kycs/IKYCRegistry.sol";
import "./vaults/IVaultRegistry.sol";
import "./escrow/IEscrowRegistry.sol";
import "./upgrade-gatekeeper/IUpgradeGatekeeper.sol";
import "./collections/ICollectionRegistry.sol";

interface IMarketHub is
    IMarketRegistry,
    ICurrencyRegistry,
    IRoyaltyRegistry,
    IKYCRegistry,
    IVaultRegistry,
    IEscrowRegistry,
    ICollectionRegistry
{
    function notifyTokenIdNoLongerAvailable(address _seller, address _erc721, uint256 _tokenId) external;

    function setMinUSDCPrice(uint256 _minUSDCPrice) external;

    function getMinUSDCPrice() external view returns (uint256);

    function getUpgradeGatekeeper() external view returns (IUpgradeGatekeeper);

    function allowNewSales() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IMarketHubRegistrar {
    function register() external;

    function unregister() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

enum AccountStatus {
    ACTIVE,
    HAULTED,
    BANNED
}

struct Account {
    address account;
    bytes32 tier; // e.g. keccak("Black"), keccak("Gold"), keccak("Platinum"), keccak("Green")
    AccountStatus status;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Account.sol";

interface IKYCRegistry {
    function registerAccount(address _account, bytes32 _tier) external;

    function updateTier(address _account, bytes32 _tier) external;

    function haultAccount(address _account) external;

    function unhaultAccount(address _account) external;

    function banAccount(address _account) external;

    function unbanAccount(address _account) external;

    function getAccount(address _account) external view returns (Account memory);

    function isAccountRegistered(address _account) external view returns (bool);

    function isAccountActive(address _account) external view returns (bool);

    function isAccountHaulted(address _account) external view returns (bool);

    function isAccountBanned(address _account) external view returns (bool);
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: UNLICENSED
import "./IMarketHub.sol";
import "../utils/ColleAccess.sol";
import "./IMarketHubRegistrar.sol";

contract MarketHubRegistrar is IMarketHubRegistrar, ColleAccess {
    IMarketHub public marketHub;

    modifier onlyMarketHub() {
        require(msg.sender == address(marketHub), "Only MarketHub can call this function.");
        _;
    }

    function register() public {
        require(address(marketHub) == address(0), "Market already registered.");
        marketHub = IMarketHub(msg.sender);
    }

    function unregister() public onlyMarketHub {
        require(address(marketHub) != address(0), "Market not registered.");
        marketHub = IMarketHub(address(0));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../IMarketHubRegistrar.sol";

interface IMarket is IMarketHubRegistrar {
    function handleTokenIdNoLongerAvailable(address _seller, address _erc721, uint256 _tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IMarket.sol";

interface IMarketRegistry {
    function registerMarket(address _marketAddress, bytes32 _marketName) external;

    function unregisterMarket(address _marketAddress, bytes32 _marketName) external;

    function getMarket(bytes32 _marketName) external view returns (IMarket);

    function getMarketNames() external view returns (bytes32[] memory);

    function isMarket(address _marketAddress) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../MarketHubRegistrar.sol";

abstract contract BaseRoyalty is MarketHubRegistrar {
    function getRoyaltyPoolBasisPoints(
        address _erc20Address,
        uint256 _totalAmount
    ) external view virtual returns (uint256 royaltyPoolBasisPoints);

    function getCommissionBasisPoints(
        address _erc20Address,
        uint256 _totalAmount
    ) external view virtual returns (uint256 commissionBasisPoints);

    function getRoyaltyBreakdown(
        address _erc20Address,
        uint256 _totalAmount
    ) public view returns (uint256 _royaltyPoolAmount, uint256 _comissionAmount) {
        uint256 royaltyPoolBasisPoints = this.getRoyaltyPoolBasisPoints(_erc20Address, _totalAmount);
        uint256 commissionBasisPoints = this.getCommissionBasisPoints(_erc20Address, _totalAmount);

        _royaltyPoolAmount = (_totalAmount * royaltyPoolBasisPoints) / 10000;
        _comissionAmount = (_totalAmount * commissionBasisPoints) / 10000;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./BaseRoyalty.sol";

contract BlackTierRoyalty is BaseRoyalty {
    function getRoyaltyPoolBasisPoints(
        address _erc20Address,
        uint256 _totalAmount
    ) external view override returns (uint256 royaltyPoolBasisPoints) {
        uint256 usdcValue = marketHub.getCurrencyByERC20(_erc20Address).getEstimatedUSDCValue(_totalAmount);

        if (usdcValue <= 1000000000) {
            return 200; // <=$1000, 2%
        } else if (usdcValue <= 10000000000) {
            return 150; // <=$10000, 1.5%
        } else {
            return 100; // >$10000, 1%
        }
    }

    function getCommissionBasisPoints(
        address _erc20Address,
        uint256 _totalAmount
    ) external view override returns (uint256 commissionBasisPoints) {
        uint256 usdcValue = marketHub.getCurrencyByERC20(_erc20Address).getEstimatedUSDCValue(_totalAmount);

        if (usdcValue <= 1000000000) {
            return 300; // <=$1000, 3%
        } else if (usdcValue <= 10000000000) {
            return 200; // <=$10000, 2%
        } else {
            return 150; // >$10000, 1.5%
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./BaseRoyalty.sol";
import "./RoyaltyPool.sol";

interface IRoyaltyRegistry {
    function registerRoyalty(bytes32 _accountTier, address _royalty) external;

    function unregisterRoyalty(bytes32 _accountTier) external;

    function registerRoyaltyPool(address _royaltyPool) external;

    function registerColleCommissions(address _colleCommissions) external;

    function getRoyalty(bytes32 _accountTier) external view returns (BaseRoyalty);

    function getRoyaltyPool() external view returns (RoyaltyPool);

    function getColleComissions() external view returns (address);

    function isRoyaltyRegistered(bytes32 _accountTier) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../MarketHubRegistrar.sol";

contract RoyaltyPool is MarketHubRegistrar {
    struct Pool {
        address initialOwner;
        address[4] recentOwners;
    }

    mapping(address => mapping(uint256 => Pool)) private pools;
    uint private initialOwnerWeight = 1;

    event PoolUpdated(
        address indexed tokenAddress,
        uint256 indexed tokenId,
        address initialOwner,
        address[4] recentOwners,
        uint initialOwnerWeight
    );

    modifier onlyEscrow() {
        // TODO: Remove hasRole
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || msg.sender == address(marketHub.getEscrow()),
            "Caller is not the escrow"
        );
        _;
    }

    constructor() {}

    function setInitialOwnerWeight(uint _weight) external onlyColle {
        initialOwnerWeight = _weight;
    }

    function trackInitialOwner(address tokenAddress, uint256 tokenId, address owner) external onlyEscrow {
        require(pools[tokenAddress][tokenId].initialOwner == address(0), "Initial owner already set");
        pools[tokenAddress][tokenId].initialOwner = owner;
        emit PoolUpdated(
            tokenAddress,
            tokenId,
            pools[tokenAddress][tokenId].initialOwner,
            pools[tokenAddress][tokenId].recentOwners,
            initialOwnerWeight
        );
    }

    function trackNewOwner(address tokenAddress, uint256 tokenId, address owner) external onlyEscrow {
        // If there is no one else in the pool AND the owner is the initialOwner, do not track them as a new owner
        if (
            pools[tokenAddress][tokenId].initialOwner == owner &&
            pools[tokenAddress][tokenId].recentOwners[3] == address(0)
        ) {
            return;
        }

        // Shift the array to the left
        for (uint i = 0; i < 3; i++) {
            pools[tokenAddress][tokenId].recentOwners[i] = pools[tokenAddress][tokenId].recentOwners[i + 1];
        }
        // Add the new owner to the end
        pools[tokenAddress][tokenId].recentOwners[3] = owner;
        emit PoolUpdated(
            tokenAddress,
            tokenId,
            pools[tokenAddress][tokenId].initialOwner,
            pools[tokenAddress][tokenId].recentOwners,
            initialOwnerWeight
        );
    }

    function getInitialOwnerWeight() external view returns (uint) {
        return initialOwnerWeight;
    }

    function getInitialOwner(address tokenAddress, uint256 tokenId) external view returns (address) {
        return pools[tokenAddress][tokenId].initialOwner;
    }

    function getRecentOwners(address tokenAddress, uint256 tokenId) external view returns (address[4] memory) {
        return pools[tokenAddress][tokenId].recentOwners;
    }

    function totalPoolShares(address tokenAddress, uint256 tokenId) external view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < 4; i++) {
            if (pools[tokenAddress][tokenId].recentOwners[i] != address(0)) {
                count++;
            }
        }
        return count + initialOwnerWeight;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IUpgradeGatekeeper {
    event UpgradeTargetSet(address indexed proxy, address indexed target);

    function setUpgradeTarget(address proxy, address target) external;

    function getUpgradeTarget(address proxy) external view returns (address);

    function resetUpgradeTarget() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../IMarketHubRegistrar.sol";

interface IVault is IMarketHubRegistrar {
    event DepositedERC20(address indexed erc20, uint256 amount);
    event WithdrawERC20(address indexed erc20, uint256 amount);
    event DepositERC721(address indexed erc721, uint256 tokenId);
    event WithdrawERC721(address indexed erc721, uint256 tokenId);

    function depositERC20(address _erc20Address, uint256 _erc20Amount, address _sender) external;

    function depositColleNFT(address _erc721Address, uint256 _tokenId, address _sender) external;

    function withdrawERC20(address _erc20Address, uint256 _erc20Amount, address _receiver) external;

    function withdrawColleNFT(address _erc721Address, uint256 _tokenId, address _receiver) external;

    function erc20Balances(address _erc20Address) external view returns (uint256);

    function erc721Balances(address _erc721Address, uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IVault.sol";

interface IVaultRegistry {
    function registerVault(address _vaultAddress) external;

    function unregisterVault(address _vaultAddress) external;

    function getVault() external view returns (IVault);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract ColleAccess is AccessControl {
    bytes32 public constant COLLE_ROLE = keccak256("COLLE_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(COLLE_ROLE, msg.sender);
    }

    function isColle(address _address) internal view returns (bool) {
        return hasRole(COLLE_ROLE, _address);
    }

    modifier onlyColle() {
        require(hasRole(COLLE_ROLE, msg.sender), "Caller is not a colle");
        _;
    }
}