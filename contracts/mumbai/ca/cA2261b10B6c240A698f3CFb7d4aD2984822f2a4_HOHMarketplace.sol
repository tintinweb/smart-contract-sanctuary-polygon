// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/access/[email protected]

//
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File @openzeppelin/contracts/access/[email protected]

//
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

// File @openzeppelin/contracts/utils/math/[email protected]

//
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

//
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

// File @openzeppelin/contracts/utils/introspection/[email protected]

//
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

//
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

// File @openzeppelin/contracts/access/[email protected]

//
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

// File @openzeppelin/contracts/token/ERC721/[email protected]

//
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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

// File @openzeppelin/contracts/interfaces/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

// File contracts/interface/IERC4907.sol

pragma solidity ^0.8.15;

interface IERC4907 {
    // Logged when the user of a token assigns a new user or updates expires
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint256 expires);

    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(uint256 tokenId, address user, uint64 expires) external;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns (address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns (uint256);
}

// File contracts/interface/IHOHERC721.sol

//
pragma solidity ^0.8.15;

/// @dev Represents a schema to claim an NFT, which has already been minted on blockchain. A signed voucher can be redeemed for a real NFT using the claim function.
struct RecruitVoucher {
    // The address of the claimer
    address redeemer;
    // The id of the token to be redeemed. Must be unique - if another token with this ID already exists, the claim function will revert.
    string uri;
    // The hash of the NFT stats signed by the owner.
    bytes32 statsHash;
    // The valid nonce value of the NFT creator, fetched through _nonces mapping.
    uint256 nonce;
    // The time period for which the voucher is valid.
    uint256 expiry;
    // The EIP-712 signature of all other fields in the RecruitVoucher struct. For a voucher to be valid, it must be signed by the owner account.
    bytes signature;
}

interface IHOHERC721 is IERC721, IERC4907 {
    function recruit(uint256 parent1, uint256 parent2, RecruitVoucher calldata voucher) external;

    function getRecCount(uint256 tokenId) external view returns (uint8);

    function getLockedTime(uint256 id) external view returns (uint256);

    function lockNFT(uint256 tokenId, uint256 secnds) external;

    function mint(address to, string memory uri, bytes32 statsHash) external returns (uint256);

    function burn(uint256 tokenId) external;
}

// File contracts/interface/IHOHChest.sol

//
pragma solidity ^0.8.15;

enum Chest {
    RARE,
    EPIC,
    LEGENDARY
}

interface IHOHChest is IHOHERC721 {
    function openChest(address buyer, uint8 chest, uint16[] memory uriIndexes, uint80 nonce, bytes memory signature) external;
}

// File contracts/interface/IHOHERC20.sol

//
pragma solidity ^0.8.15;

interface IHOHERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address from, address to, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// File contracts/marketplace/HOHMarketplace.sol

//
pragma solidity ^0.8.15;

contract HOHMarketplace is Ownable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event ItemListedForRent(
        address owner,
        ItemType itemType,
        uint256 indexed tokenId,
        uint256 amountPerDayInETH,
        uint256 amountPerDayInWETH,
        uint256 amountPerDayInGameCoin,
        uint256 amountPerDayInCompanyCoin,
        uint256 rentingPeriodInDays
    );
    event ItemRented(
        address owner,
        address renter,
        ItemType itemType,
        uint256 indexed tokenId,
        PaymentMethod indexed coin,
        uint256 rentalFeePaid,
        uint256 rentalPeriod,
        uint256 expireTimestamp
    );
    event ItemListedForSale(
        address owner,
        ItemType itemType,
        uint256 indexed tokenId,
        uint256 priceInETH,
        uint256 priceInWETH,
        uint256 priceInGameCoin,
        uint256 priceInCompanyCoin
    );
    event ItemSold(address owner, address buyer, ItemType itemType, uint256 indexed tokenId, PaymentMethod indexed coin, uint256 pricePaid);
    event ListingRemoved(uint8 indexed listingType, address owner, ItemType itemType, uint256 indexed tokenId);

    struct RentableItem {
        bool rentable;
        ItemType itemType;
        uint256 amountPerDayInETH;
        uint256 amountPerDayInWETH;
        uint256 amountPerDayInGameCoin;
        uint256 amountPerDayInCompanyCoin;
        uint256 rentingPeriodInDays;
    }

    struct BuyableItem {
        bool buyable;
        ItemType itemType;
        uint256 buyingPriceInETH;
        uint256 buyingPriceInWETH;
        uint256 buyingPriceInGameCoin;
        uint256 buyingPriceInCompanyCoin;
    }

    enum PaymentMethod {
        ETH,
        WETH,
        GameCoin,
        CompanyCoin
    }

    enum ItemType {
        HOH,
        CHEST
    }

    modifier approved(ItemType _itemType, uint256 _tokenId) {
        if (_itemType == ItemType.HOH) {
            require(
                address(this) == HOHNFT.getApproved(_tokenId) || HOHNFT.isApprovedForAll(_msgSender(), address(this)),
                "HOHMarketplace: Item not approved"
            );
        } else if (_itemType == ItemType.CHEST) {
            require(
                address(this) == HOHChest.getApproved(_tokenId) || HOHChest.isApprovedForAll(_msgSender(), address(this)),
                "HOHMarketplace: Item not approved"
            );
        }
        _;
    }

    modifier onlyNFTOwner(ItemType _itemType, uint256 _tokenId) {
        if (_itemType == ItemType.HOH) {
            require(_msgSender() == HOHNFT.ownerOf(_tokenId), "HOHMarketplace: Caller is not the token owner");
        } else if (_itemType == ItemType.CHEST) {
            require(_msgSender() == HOHChest.ownerOf(_tokenId), "HOHMarketplace: Caller is not the token owner");
        }
        _;
    }

    modifier notOwner(ItemType _itemType, uint256 _tokenId) {
        if (_itemType == ItemType.HOH) {
            require(_msgSender() != HOHNFT.ownerOf(_tokenId), "HOHMarketplace: Owner cannot call this method");
        } else if (_itemType == ItemType.CHEST) {
            require(_msgSender() != HOHChest.ownerOf(_tokenId), "HOHMarketplace: Owner cannot call this method");
        }
        _;
    }

    modifier rentable(ItemType _itemType, uint256 _tokenId) {
        require(rentables[_itemType][_tokenId].rentable == true, "HOHMarketplace: Item is not rentable");
        _;
    }

    modifier buyable(ItemType _itemType, uint256 _tokenId) {
        require(buyables[_itemType][_tokenId].buyable == true, "HOHMarketplace: Item is not buyable");
        _;
    }

    modifier notRented(ItemType _itemType, uint256 _tokenId) {
        require(!isRented(_itemType, _tokenId), "HOHMarketplace: Item is rented");
        _;
    }

    modifier notRentable(ItemType _itemType, uint256 _tokenId) {
        require(rentables[_itemType][_tokenId].rentable == false, "HOHMarketplace: Item is rentable");
        _;
    }

    modifier notBuyable(ItemType _itemType, uint256 _tokenId) {
        require(buyables[_itemType][_tokenId].buyable == false, "HOHMarketplace: Item is buyable");
        _;
    }

    IHOHERC721 public HOHNFT;
    IHOHChest public HOHChest;
    IHOHERC20 public WETH;
    IHOHERC20 public GameCoin;
    IHOHERC20 public CompanyCoin;
    uint256 public rareChestFee;
    uint256 public epicChestFee;
    uint256 public legendaryChestFee;
    uint256 public gameBaseFee;
    uint256 public companyFee;
    uint8 public platformFeePercentage;
    address public treasuryAddress;
    uint8[6] public recruitRewards = [1, 2, 4, 8, 16, 32];
    mapping(ItemType => mapping(uint256 => RentableItem)) public rentables;
    mapping(ItemType => mapping(uint256 => BuyableItem)) public buyables;

    constructor(
        address _HOHNFT,
        address _HOHChest,
        address _WETH,
        address _GameCoin,
        address _CompanyCoin,
        uint256 _rareChestFee,
        uint256 _epicChestFee,
        uint256 _legendaryChestFee,
        uint256 _gameBaseFee,
        uint256 _companyFee,
        uint8 _platformFeePercentage,
        address _treasuryAddress
    ) {
        HOHNFT = IHOHERC721(_HOHNFT);
        HOHChest = IHOHChest(_HOHChest);
        WETH = IHOHERC20(_WETH);
        GameCoin = IHOHERC20(_GameCoin);
        CompanyCoin = IHOHERC20(_CompanyCoin);
        rareChestFee = _rareChestFee;
        epicChestFee = _epicChestFee;
        legendaryChestFee = _legendaryChestFee;
        gameBaseFee = _gameBaseFee;
        companyFee = _companyFee;
        platformFeePercentage = _platformFeePercentage;
        treasuryAddress = _treasuryAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    function listNFTForRent(
        ItemType _itemType,
        uint256 _tokenId,
        uint256 _amountPerDayInETH,
        uint256 _amountPerDayInWETH,
        uint256 _amountPerDayInGameCoin,
        uint256 _amountPerDayInCompanyCoin,
        uint256 _rentingPeriodInDays
    )
        external
        onlyNFTOwner(ItemType(_itemType), _tokenId)
        approved(ItemType(_itemType), _tokenId)
        notRentable(ItemType(_itemType), _tokenId)
        notRented(ItemType(_itemType), _tokenId)
        notBuyable(ItemType(_itemType), _tokenId)
    {
        _setRentable(_itemType, _tokenId, true);
        _setRentFee(_itemType, _tokenId, _amountPerDayInETH, _amountPerDayInWETH, _amountPerDayInGameCoin, _amountPerDayInCompanyCoin);
        _setRentingPeriod(_itemType, _tokenId, _rentingPeriodInDays);
        emit ItemListedForRent(
            _msgSender(),
            _itemType,
            _tokenId,
            _amountPerDayInETH,
            _amountPerDayInWETH,
            _amountPerDayInGameCoin,
            _amountPerDayInCompanyCoin,
            _rentingPeriodInDays
        );
    }

    function listNFTForSale(
        ItemType _itemType,
        uint256 _tokenId,
        uint256 priceInETH,
        uint256 priceInWETH,
        uint256 priceInGameCoin,
        uint256 priceInCompanyCoin
    )
        external
        onlyNFTOwner(ItemType(_itemType), _tokenId)
        approved(ItemType(_itemType), _tokenId)
        notRented(ItemType(_itemType), _tokenId)
        notRentable(ItemType(_itemType), _tokenId)
        notBuyable(ItemType(_itemType), _tokenId)
    {
        _setBuyable(_itemType, _tokenId, true);
        _setBuyingPrice(_itemType, _tokenId, priceInETH, priceInWETH, priceInGameCoin, priceInCompanyCoin);
        emit ItemListedForSale(_msgSender(), _itemType, _tokenId, priceInETH, priceInWETH, priceInGameCoin, priceInCompanyCoin);
    }

    function rentNFT(
        ItemType _itemType,
        uint256 _tokenId,
        uint64 _rentalPeriod,
        PaymentMethod _paymentMethod
    )
        external
        payable
        virtual
        notOwner(_itemType, _tokenId)
        notRented(_itemType, _tokenId)
        rentable(_itemType, _tokenId)
        notBuyable(_itemType, _tokenId)
    {
        require(
            rentables[_itemType][_tokenId].rentingPeriodInDays - _rentalPeriod >= 0,
            "HOHMarketplace: Renting time exceeds the renting period"
        );
        address NFTOwner;
        uint256 expires = block.timestamp + (_rentalPeriod * 1 days);
        if (_itemType == ItemType.HOH) {
            NFTOwner = HOHNFT.ownerOf(_tokenId);
            HOHNFT.setUser(_tokenId, _msgSender(), uint64(expires));
        } else if (_itemType == ItemType.CHEST) {
            NFTOwner = HOHChest.ownerOf(_tokenId);
            HOHChest.setUser(_tokenId, _msgSender(), uint64(expires));
        }
        uint256 amount;
        if (_paymentMethod == PaymentMethod.ETH) {
            amount = rentables[_itemType][_tokenId].amountPerDayInETH * _rentalPeriod;
        } else if (_paymentMethod == PaymentMethod.WETH) {
            amount = rentables[_itemType][_tokenId].amountPerDayInWETH * _rentalPeriod;
        } else if (_paymentMethod == PaymentMethod.GameCoin) {
            amount = rentables[_itemType][_tokenId].amountPerDayInGameCoin * _rentalPeriod;
        } else {
            amount = rentables[_itemType][_tokenId].amountPerDayInCompanyCoin * _rentalPeriod;
        }
        _setRentingPeriod(_itemType, _tokenId, _rentalPeriod);
        _deductAmount(_msgSender(), NFTOwner, _paymentMethod, amount);
        emit ItemRented(NFTOwner, _msgSender(), _itemType, _tokenId, _paymentMethod, amount, _rentalPeriod, expires);
    }

    function buyNFT(
        ItemType _itemType,
        uint256 _tokenId,
        PaymentMethod _paymentMethod
    )
        external
        payable
        virtual
        notOwner(_itemType, _tokenId)
        notRented(_itemType, _tokenId)
        notRentable(_itemType, _tokenId)
        buyable(_itemType, _tokenId)
    {
        address NFTOwner;
        if (_itemType == ItemType.HOH) {
            NFTOwner = HOHNFT.ownerOf(_tokenId);
            HOHNFT.safeTransferFrom(NFTOwner, _msgSender(), _tokenId);
        } else if (_itemType == ItemType.CHEST) {
            NFTOwner = HOHChest.ownerOf(_tokenId);
            HOHChest.safeTransferFrom(NFTOwner, _msgSender(), _tokenId);
        }
        uint256 amount;
        if (_paymentMethod == PaymentMethod.ETH) {
            amount = buyables[_itemType][_tokenId].buyingPriceInETH;
        } else if (_paymentMethod == PaymentMethod.WETH) {
            amount = buyables[_itemType][_tokenId].buyingPriceInWETH;
        } else if (_paymentMethod == PaymentMethod.GameCoin) {
            amount = buyables[_itemType][_tokenId].buyingPriceInGameCoin;
        } else {
            amount = buyables[_itemType][_tokenId].buyingPriceInCompanyCoin;
        }
        _deductAmount(_msgSender(), NFTOwner, _paymentMethod, amount);
        _removeRentListing(NFTOwner, _itemType, _tokenId);
        _removeSaleListing(NFTOwner, _itemType, _tokenId);
        emit ItemSold(NFTOwner, _msgSender(), _itemType, _tokenId, _paymentMethod, amount);
    }

    function _deductAmount(address payer, address receiver, PaymentMethod paymentMethod, uint256 amount) internal {
        require(amount > 0, "HOHMarketplace: Amount for this payment method is not set");
        uint256 platformFee = (amount * platformFeePercentage) / 100;
        if (paymentMethod == PaymentMethod.ETH) {
            require(msg.value >= amount + platformFee, "HOHMarketplace: Insufficient amount provided");
            payable(receiver).transfer(amount);
            payable(treasuryAddress).transfer(platformFee);
        } else if (paymentMethod == PaymentMethod.WETH) {
            WETH.transferFrom(payer, receiver, amount);
            WETH.transferFrom(payer, treasuryAddress, platformFee);
        } else if (paymentMethod == PaymentMethod.GameCoin) {
            GameCoin.transferFrom(payer, receiver, amount);
            GameCoin.transferFrom(payer, treasuryAddress, platformFee);
        } else {
            CompanyCoin.transferFrom(payer, receiver, amount);
            CompanyCoin.transferFrom(payer, treasuryAddress, platformFee);
        }
    }

    function isRented(ItemType _itemType, uint256 tokenId) public view returns (bool) {
        if (_itemType == ItemType.HOH) {
            return HOHNFT.userOf(tokenId) != address(0);
        } else {
            return HOHChest.userOf(tokenId) != address(0);
        }
    }

    function renter(ItemType _itemType, uint256 _tokenId) public view returns (address) {
        if (_itemType == ItemType.HOH) {
            return HOHNFT.userOf(_tokenId);
        } else {
            return HOHChest.userOf(_tokenId);
        }
    }

    function getRentableItem(ItemType _itemType, uint256 _tokenId) public view returns (RentableItem memory) {
        return rentables[_itemType][_tokenId];
    }

    function getBuyableItem(ItemType _itemType, uint256 _tokenId) public view returns (BuyableItem memory) {
        return buyables[_itemType][_tokenId];
    }

    /**
     * @dev Used for pausing and unpausing the renting
     */
    function setRentable(ItemType _itemType, uint256 _tokenId, bool _rentable) external onlyNFTOwner(_itemType, _tokenId) {
        _setRentable(_itemType, _tokenId, _rentable);
    }

    function _setRentable(ItemType _itemType, uint256 _tokenId, bool _rentable) internal {
        rentables[_itemType][_tokenId].rentable = _rentable;
    }

    function setRentFee(
        ItemType _itemType,
        uint256 _tokenId,
        uint256 _amountPerDayInETH,
        uint256 _amountPerDayInWETH,
        uint256 _amountPerDayInGameCoin,
        uint256 _amountPerDayInCompanyCoin
    ) external onlyNFTOwner(_itemType, _tokenId) {
        _setRentFee(_itemType, _tokenId, _amountPerDayInETH, _amountPerDayInWETH, _amountPerDayInGameCoin, _amountPerDayInCompanyCoin);
    }

    function _setRentFee(
        ItemType _itemType,
        uint256 _tokenId,
        uint256 _amountPerDayInETH,
        uint256 _amountPerDayInWETH,
        uint256 _amountPerDayInGameCoin,
        uint256 _amountPerDayInCompanyCoin
    ) internal {
        rentables[_itemType][_tokenId].amountPerDayInETH = _amountPerDayInETH;
        rentables[_itemType][_tokenId].amountPerDayInWETH = _amountPerDayInWETH;
        rentables[_itemType][_tokenId].amountPerDayInGameCoin = _amountPerDayInGameCoin;
        rentables[_itemType][_tokenId].amountPerDayInCompanyCoin = _amountPerDayInCompanyCoin;
    }

    function setRentingPeriod(ItemType _itemType, uint256 _tokenId, uint256 _rentingPeriodInDays) external onlyNFTOwner(_itemType, _tokenId) {
        _setRentingPeriod(_itemType, _tokenId, _rentingPeriodInDays);
    }

    function _setRentingPeriod(ItemType _itemType, uint256 _tokenId, uint256 _rentingPeriodInDays) internal {
        require(_rentingPeriodInDays > 0, "HOHMarketplace: Renting period cannot be 0");
        rentables[_itemType][_tokenId].rentingPeriodInDays = _rentingPeriodInDays;
    }

    function setBuyable(ItemType _itemType, uint256 _tokenId, bool _buyable) external onlyNFTOwner(_itemType, _tokenId) {
        _setBuyable(_itemType, _tokenId, _buyable);
    }

    function _setBuyable(ItemType _itemType, uint256 _tokenId, bool _buyable) internal {
        buyables[_itemType][_tokenId].buyable = _buyable;
    }

    function setBuyingPrice(
        ItemType _itemType,
        uint256 _tokenId,
        uint256 _priceInETH,
        uint256 _priceInWETH,
        uint256 _priceInGameCoin,
        uint256 _priceInCompanyCoin
    ) external onlyNFTOwner(_itemType, _tokenId) {
        _setBuyingPrice(_itemType, _tokenId, _priceInETH, _priceInWETH, _priceInGameCoin, _priceInCompanyCoin);
    }

    function _setBuyingPrice(
        ItemType _itemType,
        uint256 _tokenId,
        uint256 _priceInETH,
        uint256 _priceInWETH,
        uint256 _priceInGameCoin,
        uint256 _priceInCompanyCoin
    ) internal {
        buyables[_itemType][_tokenId].buyingPriceInETH = _priceInETH;
        buyables[_itemType][_tokenId].buyingPriceInWETH = _priceInWETH;
        buyables[_itemType][_tokenId].buyingPriceInGameCoin = _priceInGameCoin;
        buyables[_itemType][_tokenId].buyingPriceInCompanyCoin = _priceInCompanyCoin;
    }

    function removeRentListing(ItemType _itemType, uint256 _tokenId) external onlyNFTOwner(_itemType, _tokenId) {
        _removeRentListing(_msgSender(), _itemType, _tokenId);
    }

    function _removeRentListing(address owner, ItemType _itemType, uint256 _tokenId) internal {
        delete rentables[_itemType][_tokenId];
        emit ListingRemoved(0, owner, _itemType, _tokenId);
    }

    function removeSaleListing(ItemType _itemType, uint256 _tokenId) external onlyNFTOwner(_itemType, _tokenId) {
        _removeSaleListing(_msgSender(), _itemType, _tokenId);
    }

    function _removeSaleListing(address owner, ItemType _itemType, uint256 _tokenId) internal {
        delete buyables[_itemType][_tokenId];
        emit ListingRemoved(1, owner, _itemType, _tokenId);
    }

    function recruitHOH(uint256 parent1, uint256 parent2, RecruitVoucher calldata voucher) external {
        require(_msgSender() == voucher.redeemer, "HOHMarketplace: Caller is not the redeemer");
        // Calculate fee
        uint256 gameFee = calculateGameFee(parent1, parent2);

        require(GameCoin.allowance(_msgSender(), address(this)) >= gameFee, "HOHMarketplace: Allowance is not enough for Game coin");
        require(CompanyCoin.allowance(_msgSender(), address(this)) >= companyFee, "HOHMarketplace: Allowance is not enough for Company token");

        // Transfer fees to treasury
        bool transferStatus;
        transferStatus = GameCoin.transferFrom(_msgSender(), treasuryAddress, gameFee);
        require(transferStatus, "HOHMarketplace: Failed to transfer Game fee");
        transferStatus = CompanyCoin.transferFrom(_msgSender(), treasuryAddress, companyFee);
        require(transferStatus, "HOHMarketplace: Failed to transfer Company fee");

        HOHNFT.recruit(parent1, parent2, voucher);
    }

    function buyChest(uint8 chest, uint16[] memory uriIndexes, uint80 nonce, bytes memory signature) external {
        require(_msgSender() != treasuryAddress, "HOHMarketplace: Cannot buy chest from treasury address");
        require(chest < 4, "HOHMarketplace: Invalid chest type");
        if (chest == uint8(Chest.RARE)) {
            GameCoin.transferFrom(_msgSender(), treasuryAddress, rareChestFee);
        } else if (chest == uint8(Chest.EPIC)) {
            GameCoin.transferFrom(_msgSender(), treasuryAddress, epicChestFee);
        } else if (chest == uint8(Chest.LEGENDARY)) {
            CompanyCoin.transferFrom(_msgSender(), treasuryAddress, legendaryChestFee);
        }
        HOHChest.openChest(_msgSender(), chest, uriIndexes, nonce, signature);
    }

    function calculateGameFee(uint256 tokenId1, uint256 tokenId2) public view returns (uint256) {
        uint256 token1RecCount = HOHNFT.getRecCount(tokenId1);
        uint256 token2RecCount = HOHNFT.getRecCount(tokenId2);
        uint256 token1Fee = gameBaseFee * recruitRewards[token1RecCount];
        uint256 token2Fee = gameBaseFee * recruitRewards[token2RecCount];
        return token1Fee + token2Fee;
    }

    function setHOHNFT(address _HOHNFT) external onlyRole(ADMIN_ROLE) {
        HOHNFT = IHOHERC721(_HOHNFT);
    }

    function setHOHCHEST(address _HOHChest) external onlyRole(ADMIN_ROLE) {
        HOHChest = IHOHChest(_HOHChest);
    }

    /**
     * @dev Set the contract instance for ERC20
     * @param _gameCoin The address of the ERC20 contract that needs to be set
     */
    function setGameCoin(address _gameCoin) external onlyRole(ADMIN_ROLE) {
        GameCoin = IHOHERC20(_gameCoin);
    }

    /**
     * @dev Set the contract instance for ERC20
     * @param _companyCoin The address of the ERC20 contract that needs to be set
     */
    function setCompanyCoin(address _companyCoin) external onlyRole(ADMIN_ROLE) {
        CompanyCoin = IHOHERC20(_companyCoin);
    }

    /**
     * @dev Set the price to mint
     * @param _gameBaseFee Minting fee, default is 10 FT
     */
    function setGameBaseFee(uint256 _gameBaseFee) external onlyRole(ADMIN_ROLE) {
        gameBaseFee = _gameBaseFee;
    }

    /**
     * @dev Set the price to mint
     * @param _companyFee Minting fee, default is 10 FT
     */
    function setCompanyFee(uint256 _companyFee) external onlyRole(ADMIN_ROLE) {
        companyFee = _companyFee;
    }

    function setRareChestFee(uint256 _rareChestFee) external onlyRole(ADMIN_ROLE) {
        rareChestFee = _rareChestFee;
    }

    function setEpicChestFee(uint256 _epicChestFee) external onlyRole(ADMIN_ROLE) {
        epicChestFee = _epicChestFee;
    }

    function setLegendaryChestFee(uint256 _legendaryChestFee) external onlyRole(ADMIN_ROLE) {
        legendaryChestFee = _legendaryChestFee;
    }

    function serPlatformFeePercentage(uint8 _platformFeePercentage) external onlyRole(ADMIN_ROLE) {
        platformFeePercentage = _platformFeePercentage;
    }

    /**
     * @dev Set the treasury address
     * @param _treasuryAddress Account address of the treasurer
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        treasuryAddress = _treasuryAddress;
    }
}