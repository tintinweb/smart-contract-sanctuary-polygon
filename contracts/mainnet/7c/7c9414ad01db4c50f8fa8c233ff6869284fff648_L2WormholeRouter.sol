// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

import "./interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
pragma solidity ^0.8.4;

/// @notice Contract that enables a single call to call multiple methods on itself.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Multicallable.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Multicallable.sol)
/// @dev WARNING!
/// Multicallable is NOT SAFE for use in contracts with checks / requires on `msg.value`
/// (e.g. in NFT minting / auction contracts) without a suitable nonce mechanism.
/// It WILL open up your contract to double-spend vulnerabilities / exploits.
/// See: (https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/)
abstract contract Multicallable {
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        assembly {
            if data.length {
                results := mload(0x40) // Point `results` to start of free memory.
                mstore(results, data.length) // Store `data.length` into `results`.
                results := add(results, 0x20)

                // `shl` 5 is equivalent to multiplying by 0x20.
                let end := shl(5, data.length)
                // Copy the offsets from calldata into memory.
                calldatacopy(results, data.offset, end)
                // Pointer to the top of the memory (i.e. start of the free memory).
                let memPtr := add(results, end)
                end := add(results, end)

                // prettier-ignore
                for {} 1 {} {
                    // The offset of the current bytes in the calldata.
                    let o := add(data.offset, mload(results))
                    // Copy the current bytes from calldata to the memory.
                    calldatacopy(
                        memPtr,
                        add(o, 0x20), // The offset of the current bytes' bytes.
                        calldataload(o) // The length of the current bytes.
                    )
                    if iszero(delegatecall(gas(), address(), memPtr, calldataload(o), 0x00, 0x00)) {
                        // Bubble up the revert if the delegatecall reverts.
                        returndatacopy(0x00, 0x00, returndatasize())
                        revert(0x00, returndatasize())
                    }
                    // Append the current `memPtr` into `results`.
                    mstore(results, memPtr)
                    results := add(results, 0x20)
                    // Append the `returndatasize()`, and the return data.
                    mstore(memPtr, returndatasize())
                    returndatacopy(add(memPtr, 0x20), 0x00, returndatasize())
                    // Advance the `memPtr` by `returndatasize() + 0x20`,
                    // rounded up to the next multiple of 32.
                    memPtr := and(add(add(memPtr, returndatasize()), 0x3f), 0xffffffffffffffe0)
                    // prettier-ignore
                    if iszero(lt(results, end)) { break }
                }
                // Restore `results` and allocate memory for it.
                results := mload(0x40)
                mstore(0x40, memPtr)
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

/// @author Open Zeppelin
interface IERC4626 {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     * call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     * in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     * deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     * deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     * approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     * in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     * same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     * would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     * execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     * approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     * call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     * called
     * in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     * the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     * withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     * not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     * in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     * same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     * redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     * redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     * not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

interface IWormhole {
    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;
        uint32 guardianSetIndex;
        Signature[] signatures;
        bytes32 hash;
    }

    function publishMessage(uint32 nonce, bytes memory payload, uint8 consistencyLevel)
        external
        payable
        returns (uint64 sequence);

    function parseAndVerifyVM(bytes calldata encodedVM)
        external
        view
        returns (VM memory vm, bool valid, string memory reason);

    function nextSequence(address emitter) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

library Constants {
    // Message types
    // Messages received by L1
    bytes32 constant L2_FUND_TRANSFER_REPORT = keccak256("L2_FUND_TRANSFER_REPORT");
    bytes32 constant L2_FUND_REQUEST = keccak256("L2_FUND_REQUEST");

    // Messages received by L2
    bytes32 constant L1_TVL = keccak256("L1_TVL");
    bytes32 constant L1_FUND_TRANSFER_REPORT = keccak256("L1_FUND_TRANSFER_REPORT");
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

/*  solhint-disable func-visibility */
function uncheckedInc(uint256 i) pure returns (uint256) {
    unchecked {
        return i + 1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {AffineVault} from "src/vaults/AffineVault.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @notice Base strategy contract
abstract contract BaseStrategy {
    using SafeTransferLib for ERC20;

    constructor(AffineVault _vault) {
        vault = _vault;
        asset = ERC20(_vault.asset());
    }

    /// @notice The vault which will deposit/withdraw from the this contract
    AffineVault public immutable vault;

    modifier onlyVault() {
        require(msg.sender == address(vault), "BS: only vault");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == vault.governance(), "BS: only governance");
        _;
    }

    /// @notice Returns the underlying ERC20 asset the strategy accepts.
    ERC20 public immutable asset;

    /// @notice Strategy's balance of underlying asset.
    /// @return assets Strategy's balance.
    function balanceOfAsset() public view returns (uint256 assets) {
        assets = asset.balanceOf(address(this));
    }

    /// @notice Deposit vault's underlying asset into strategy.
    /// @param amount The amount to invest.
    /// @dev This function must revert if investment fails.
    function invest(uint256 amount) external {
        asset.safeTransferFrom(msg.sender, address(this), amount);
        _afterInvest(amount);
    }

    /// @notice After getting money from the vault, do something with it.
    /// @param amount The amount received from the vault.
    /// @dev Since investment is often gas-intensive and may require off-chain data, this will often be unimplemented.
    /// @dev Strategists will call custom functions for handling deployment of capital.
    function _afterInvest(uint256 amount) internal virtual {}

    /// @notice Withdraw vault's underlying asset from strategy.
    /// @param amount The amount to withdraw.
    /// @return The amount of `asset` divested from the strategy
    function divest(uint256 amount) external onlyVault returns (uint256) {
        return _divest(amount);
    }

    /// @dev This function should not revert if we get less than `amount` out of the strategy
    function _divest(uint256 amount) internal virtual returns (uint256) {}

    /// @notice The total amount of `asset` that the strategy is managing
    /// @dev This should not overestimate, and should account for slippage during divestment
    /// @return The strategy tvl
    function totalLockedValue() external virtual returns (uint256);

    function sweep(ERC20 token) external onlyGovernance {
        token.safeTransfer(vault.governance(), token.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

contract AffineGovernable {
    /// @notice The governance address
    address public governance;

    modifier onlyGovernance() {
        _onlyGovernance();
        _;
    }

    function _onlyGovernance() internal view {
        require(msg.sender == governance, "Only Governance.");
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

abstract contract DetailedShare {
    /**
     * @notice A representation of a floating point number.
     * `decimals` is the number of digits before the where the decimal point would be placeds
     */
    struct Number {
        uint256 num;
        uint8 decimals;
    }

    /// @notice The tvl is a dollar amount representing the total value locked in the vault.
    function detailedTVL() external virtual returns (Number memory);

    /**
     * @notice The number of dollars that "one" share is worth.
     * @dev "One" share is always 1 * 10 ^ (decimals). Note that `decimals` refers
     * to the ERC20 property.
     */
    function detailedPrice() external virtual returns (Number memory);

    /**
     * @notice The total supply of the token. The value of Number.num here is the same as `totalSupply()`
     * @dev detailedTVL() / detailedTotalSupply() ==  detailedPrice()
     */
    function detailedTotalSupply() external virtual returns (Number memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

import {AffineGovernable} from "src/utils/AffineGovernable.sol";
import {BaseStrategy as Strategy} from "src/strategies/BaseStrategy.sol";
import {uncheckedInc} from "src/libs/Unchecked.sol";

/**
 * @notice A core contract to be inherited by the L1 and L2 vault contracts. This contract handles adding
 * and removing strategies, investing in (and divesting from) strategies, harvesting gains/losses, and
 * strategy liquidation.
 */
contract AffineVault is AffineGovernable, AccessControlUpgradeable {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                             INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    ERC20 _asset;

    /// @notice The token that the vault takes in and tries to get more of, e.g. USDC
    function asset() public view virtual returns (address) {
        return address(_asset);
    }

    /**
     * @dev Initialize the vault.
     * @param _governance The governance address.
     * @param vaultAsset The vault's input asset.
     */
    function baseInitialize(address _governance, ERC20 vaultAsset) internal virtual {
        governance = _governance;
        _asset = vaultAsset;

        // All roles use the default admin role
        // Governance has the admin role and all roles
        _grantRole(DEFAULT_ADMIN_ROLE, governance);
        _grantRole(HARVESTER, governance);

        lastHarvest = uint128(block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                             AUTHENTICATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Role with authority to call "harvest", i.e. update this vault's tvl
    bytes32 public constant HARVESTER = keccak256("HARVESTER");

    /*//////////////////////////////////////////////////////////////
                            WITHDRAWAL QUEUE
    //////////////////////////////////////////////////////////////*/

    uint8 constant MAX_STRATEGIES = 20;

    /**
     * @notice An ordered array of strategies representing the withdrawal queue. The withdrawal queue is used
     * whenever the vault wants to pull money out of strategies.
     * @dev The first strategy in the array (index 0) is withdrawn from first.
     * This is a list of the currently active strategies  (all non-zero addresses are active).
     */
    Strategy[MAX_STRATEGIES] public withdrawalQueue;

    /**
     * @notice Gets the full withdrawal queue.
     * @return The withdrawal queue.
     * @dev This gives easy access to the whole array (by default we can only get one index at a time)
     */
    function getWithdrawalQueue() external view returns (Strategy[MAX_STRATEGIES] memory) {
        return withdrawalQueue;
    }

    /**
     * @notice Sets a new withdrawal queue.
     * @param newQueue The new withdrawal queue.
     */
    function setWithdrawalQueue(Strategy[MAX_STRATEGIES] calldata newQueue) external onlyGovernance {
        // Maintain queue size
        require(newQueue.length == MAX_STRATEGIES, "BV: bad qu size");

        // Replace the withdrawal queue.
        withdrawalQueue = newQueue;

        emit WithdrawalQueueSet(newQueue);
    }

    /**
     * @notice Emitted when the withdrawal queue is updated.
     * @param newQueue The new withdrawal queue.
     */
    event WithdrawalQueueSet(Strategy[MAX_STRATEGIES] newQueue);

    /*//////////////////////////////////////////////////////////////
                               STRATEGIES
    //////////////////////////////////////////////////////////////*/

    /// @notice The total amount of underlying assets held in strategies at the time of the last harvest.
    uint256 public totalStrategyHoldings;

    struct StrategyInfo {
        bool isActive;
        uint16 tvlBps;
        uint232 balance;
    }

    /// @notice A map of strategy addresses to details
    mapping(Strategy => StrategyInfo) public strategies;

    uint256 constant MAX_BPS = 10_000;
    /// @notice The number of bps of the vault's tvl which may be given to strategies (at most MAX_BPS)
    uint256 public totalBps;

    /// @notice Emitted when a strategy is added by governance
    event StrategyAdded(Strategy indexed strategy);
    /// @notice Emitted when a strategy is removed by governance
    event StrategyRemoved(Strategy indexed strategy);

    /**
     * @notice Add a strategy
     * @param strategy The strategy to add
     * @param tvlBps The number of bps of our tvl the strategy will get when funds are distributed to strategies
     */
    function addStrategy(Strategy strategy, uint16 tvlBps) external onlyGovernance {
        _increaseTVLBps(tvlBps);
        strategies[strategy] = StrategyInfo({isActive: true, tvlBps: tvlBps, balance: 0});
        //  Add strategy to withdrawal queue
        withdrawalQueue[MAX_STRATEGIES - 1] = strategy;
        emit StrategyAdded(strategy);
        _organizeWithdrawalQueue();
    }

    /// @notice A helper function for increasing `totalBps`. Used when adding strategies or updating strategy allocs
    function _increaseTVLBps(uint256 tvlBps) internal {
        uint256 newTotalBps = totalBps + tvlBps;
        require(newTotalBps <= MAX_BPS, "BV: too many bps");
        totalBps = newTotalBps;
    }

    /**
     * @notice Push all zero addresses to the end of the array. This function is used whenever a strategy is
     * added or removed from the withdrawal queue
     * @dev Relative ordering of non-zero values is maintained.
     */
    function _organizeWithdrawalQueue() internal {
        // number or empty values we've seen iterating from left to right
        uint256 offset;

        for (uint256 i = 0; i < MAX_STRATEGIES; i = uncheckedInc(i)) {
            Strategy strategy = withdrawalQueue[i];
            if (address(strategy) == address(0)) {
                offset += 1;
            } else if (offset > 0) {
                // index of first empty value seen takes on value of `strategy`
                withdrawalQueue[i - offset] = strategy;
                withdrawalQueue[i] = Strategy(address(0));
            }
        }
    }

    /**
     * @notice Remove a strategy from the withdrawal queue. Fully divest from the strategy.
     * @param strategy The strategy to remove
     * @dev  removeStrategy MUST be called with harvest via multicall. This helps get the most accurate tvl numbers
     * and allows us to add any realized profits to our lockedProfit
     */
    function removeStrategy(Strategy strategy) external onlyGovernance {
        for (uint256 i = 0; i < MAX_STRATEGIES; i = uncheckedInc(i)) {
            if (strategy != withdrawalQueue[i]) {
                continue;
            }

            strategies[strategy].isActive = false;

            // The vault can re-allocate bps to a new strategy
            totalBps -= strategies[strategy].tvlBps;
            strategies[strategy].tvlBps = 0;

            // Remove strategy from withdrawal queue
            withdrawalQueue[i] = Strategy(address(0));
            emit StrategyRemoved(strategy);
            _organizeWithdrawalQueue();

            // Take all money out of strategy.
            _withdrawFromStrategy(strategy, strategy.totalLockedValue());
            break;
        }
    }

    /**
     * @notice Update tvl bps assigned to the given list of strategies
     * @param strategyList The list of strategies
     * @param strategyBps The new bps
     */
    function updateStrategyAllocations(Strategy[] calldata strategyList, uint16[] calldata strategyBps)
        external
        onlyRole(HARVESTER)
    {
        for (uint256 i = 0; i < strategyList.length; i = uncheckedInc(i)) {
            // Get the strategy at the current index.
            Strategy strategy = strategyList[i];

            // Ignore inactive (removed) strategies
            if (!strategies[strategy].isActive) continue;

            // update tvl bps
            totalBps -= strategies[strategy].tvlBps;
            _increaseTVLBps(strategyBps[i]);
            strategies[strategy].tvlBps = strategyBps[i];
        }
        emit StrategyAllocsUpdated(strategyList, strategyBps);
    }

    /**
     * @notice Emitted when we update tvl bps for a list of strategies.
     * @param strategyList The list of strategies.
     * @param strategyBps The new tvl bps for the strategies
     */
    event StrategyAllocsUpdated(Strategy[] strategyList, uint16[] strategyBps);

    /*//////////////////////////////////////////////////////////////
                      STRATEGY DEPOSIT/WITHDRAWAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted after the Vault deposits into a strategy contract.
     * @param strategy The strategy that was deposited into.
     * @param assets The amount of assets deposited.
     */
    event StrategyDeposit(Strategy indexed strategy, uint256 assets);

    /**
     * @notice Emitted after the Vault withdraws funds from a strategy contract.
     * @param strategy The strategy that was withdrawn from.
     * @param assetsRequested The amount of assets we tried to divest from the strategy.
     * @param assetsReceived The amount of assets actually withdrawn.
     */
    event StrategyWithdrawal(Strategy indexed strategy, uint256 assetsRequested, uint256 assetsReceived);

    /// @notice Deposit `assetAmount` amount of `asset` into strategies according to each strategy's `tvlBps`.
    function _depositIntoStrategies(uint256 assetAmount) internal {
        // All non-zero strategies are active
        for (uint256 i = 0; i < MAX_STRATEGIES; i = uncheckedInc(i)) {
            Strategy strategy = withdrawalQueue[i];
            if (address(strategy) == address(0)) {
                break;
            }
            _depositIntoStrategy(strategy, (assetAmount * strategies[strategy].tvlBps) / MAX_BPS);
        }
    }

    function _depositIntoStrategy(Strategy strategy, uint256 assets) internal {
        // Don't allow empty investments
        if (assets == 0) return;

        // Increase totalStrategyHoldings to account for the deposit.
        totalStrategyHoldings += assets;

        unchecked {
            // Without this the next harvest would count the deposit as profit.
            // Cannot overflow as the balance of one strategy can't exceed the sum of all.
            strategies[strategy].balance += uint232(assets);
        }

        // Approve assets to the strategy so we can deposit.
        _asset.safeApprove(address(strategy), assets);

        // Deposit into the strategy, will revert upon failure
        strategy.invest(assets);
        emit StrategyDeposit(strategy, assets);
    }

    /**
     * @notice Withdraw a specific amount of underlying tokens from a strategy.
     * @dev This is a "best effort" withdrawal. It could potentially withdraw nothing.
     * @param strategy The strategy to withdraw from.
     * @param assets  The amount of underlying tokens to withdraw.
     * @return The amount of assets actually received.
     */
    function _withdrawFromStrategy(Strategy strategy, uint256 assets) internal returns (uint256) {
        // Withdraw from the strategy
        uint256 amountWithdrawn = _divest(strategy, assets);

        // Without this the next harvest would count the withdrawal as a loss.
        // We update the balance to the current tvl because a withdrawal can reduce the tvl by more than the amount
        // withdrawn (e.g. fees during a swap)
        uint256 oldStratTVL = strategies[strategy].balance;
        uint256 newStratTvl = strategy.totalLockedValue();
        strategies[strategy].balance = uint232(newStratTvl);

        // Decrease totalStrategyHoldings to account for the withdrawal.
        // If we haven't harvested in a long time, newStratTvl could be bigger than oldStratTvl
        totalStrategyHoldings -= oldStratTVL > newStratTvl ? oldStratTVL - newStratTvl : 0;
        emit StrategyWithdrawal({strategy: strategy, assetsRequested: assets, assetsReceived: amountWithdrawn});
        return amountWithdrawn;
    }

    /// @dev A small wrapper around divest(). We try-catch to make sure that a bad strategy does not pause withdrawals.
    function _divest(Strategy strategy, uint256 assets) internal returns (uint256) {
        try strategy.divest(assets) returns (uint256 amountDivested) {
            return amountDivested;
        } catch {
            return 0;
        }
    }

    /*//////////////////////////////////////////////////////////////
                               HARVESTING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice A timestamp representing when the most recent harvest occurred.
     * @dev Since the time since the last harvest is used to calculate management fees, this is set
     * to `block.timestamp` (instead of 0) during initialization.
     */
    uint128 public lastHarvest;
    /// @notice The amount of profit *originally* locked after harvesting from a strategy
    uint128 public maxLockedProfit;
    /// @notice Amount of time in seconds that profit takes to fully unlock. See lockedProfit().
    uint256 public constant LOCK_INTERVAL = 24 hours;

    /**
     * @notice Emitted after a successful harvest.
     * @param user The authorized user who triggered the harvest.
     * @param strategies The trusted strategies that were harvested.
     */
    event Harvest(address indexed user, Strategy[] strategies);

    /**
     * @notice Harvest a set of trusted strategies.
     * @param strategyList The trusted strategies to harvest.
     * @dev Will always revert if profit from last harvest has not finished unlocking.
     */
    function harvest(Strategy[] calldata strategyList) external onlyRole(HARVESTER) {
        // Profit must not be unlocking
        require(block.timestamp >= lastHarvest + LOCK_INTERVAL, "BV: profit unlocking");

        // Get the Vault's current total strategy holdings.
        uint256 oldTotalStrategyHoldings = totalStrategyHoldings;

        // Used to store the new total strategy holdings after harvesting.
        uint256 newTotalStrategyHoldings = oldTotalStrategyHoldings;

        // Used to store the total profit accrued by the strategies.
        uint256 totalProfitAccrued;

        // Will revert if any of the specified strategies are untrusted.
        for (uint256 i = 0; i < strategyList.length; i = uncheckedInc(i)) {
            // Get the strategy at the current index.
            Strategy strategy = strategyList[i];

            // Ignore inactive (removed) strategies
            if (!strategies[strategy].isActive) {
                continue;
            }

            // Get the strategy's previous and current balance.
            uint232 balanceLastHarvest = strategies[strategy].balance;
            uint256 balanceThisHarvest = strategy.totalLockedValue();

            // Update the strategy's stored balance.
            strategies[strategy].balance = uint232(balanceThisHarvest);

            // Increase/decrease newTotalStrategyHoldings based on the profit/loss registered.
            // We cannot wrap the subtraction in parenthesis as it would underflow if the strategy had a loss.
            newTotalStrategyHoldings = newTotalStrategyHoldings + balanceThisHarvest - balanceLastHarvest;

            unchecked {
                // Update the total profit accrued while counting losses as zero profit.
                // Cannot overflow as we already increased total holdings without reverting.
                totalProfitAccrued += balanceThisHarvest > balanceLastHarvest
                    ? balanceThisHarvest - balanceLastHarvest // Profits since last harvest.
                    : 0; // If the strategy registered a net loss we don't have any new profit.
            }
        }

        // Update max unlocked profit based on any remaining locked profit plus new profit.
        maxLockedProfit = uint128(lockedProfit() + totalProfitAccrued);

        // Set strategy holdings to our new total.
        totalStrategyHoldings = newTotalStrategyHoldings;

        // Assess fees (using old lastHarvest) and update the last harvest timestamp.
        _assessFees();
        lastHarvest = uint128(block.timestamp);

        emit Harvest(msg.sender, strategyList);
    }

    /**
     * @notice Current locked profit amount.
     * @dev Profit unlocks uniformly over `LOCK_INTERVAL` seconds after the last harvest
     */
    function lockedProfit() public view virtual returns (uint256) {
        if (block.timestamp >= lastHarvest + LOCK_INTERVAL) {
            return 0;
        }

        uint256 unlockedProfit = (maxLockedProfit * (block.timestamp - lastHarvest)) / LOCK_INTERVAL;
        return maxLockedProfit - unlockedProfit;
    }

    /*//////////////////////////////////////////////////////////////
                        LIQUIDATION/REBALANCING
    //////////////////////////////////////////////////////////////*/

    /// @notice The total amount of the underlying asset the vault has.
    function vaultTVL() public view returns (uint256) {
        return _asset.balanceOf(address(this)) + totalStrategyHoldings;
    }

    /**
     * @notice Emitted when the vault must make a certain amount of assets available
     * @dev We liquidate during cross chain rebalancing or withdrawals.
     * @param assetsRequested The amount we wanted to make available for withdrawal.
     * @param assetsLiquidated The amount we actually liquidated.
     */
    event Liquidation(uint256 assetsRequested, uint256 assetsLiquidated);

    /**
     * @notice Withdraw `amount` of underlying asset from strategies.
     * @dev Always check the return value when using this function, we might not liquidate anything!
     * @param amount The amount we want to liquidate
     * @return The amount we actually liquidated
     */
    function _liquidate(uint256 amount) internal returns (uint256) {
        uint256 amountLiquidated;
        for (uint256 i = 0; i < MAX_STRATEGIES; i = uncheckedInc(i)) {
            Strategy strategy = withdrawalQueue[i];
            if (address(strategy) == address(0)) {
                break;
            }

            uint256 balance = _asset.balanceOf(address(this));
            if (balance >= amount) {
                break;
            }

            uint256 amountNeeded = amount - balance;
            amountNeeded = Math.min(amountNeeded, strategies[strategy].balance);

            // Force withdraw of token from strategy
            uint256 withdrawn = _withdrawFromStrategy(strategy, amountNeeded);
            amountLiquidated += withdrawn;
        }
        emit Liquidation({assetsRequested: amount, assetsLiquidated: amountLiquidated});
        return amountLiquidated;
    }

    /**
     * @notice Assess fees.
     * @dev This is called during harvest() to assess management fees.
     */
    function _assessFees() internal virtual {}

    /**
     * @notice Emitted when we do a strategy rebalance, i.e. when we make the strategy tvls match their tvl bps
     * @param caller The caller
     */
    event Rebalance(address indexed caller);

    /// @notice  Rebalance strategies according to given tvl bps
    function rebalance() external onlyRole(HARVESTER) {
        uint256 tvl = vaultTVL();

        // Loop through all strategies. Divesting from those whose tvl is too high,
        // Invest in those whose tvl is too low

        // MAX_STRATEGIES is always equal to withdrawalQueue.length
        uint256[MAX_STRATEGIES] memory amountsToInvest;

        for (uint256 i = 0; i < MAX_STRATEGIES; i = uncheckedInc(i)) {
            Strategy strategy = withdrawalQueue[i];
            if (address(strategy) == address(0)) {
                break;
            }

            uint256 idealStrategyTVL = (tvl * strategies[strategy].tvlBps) / MAX_BPS;
            uint256 currStrategyTVL = strategy.totalLockedValue();
            if (idealStrategyTVL < currStrategyTVL) {
                _withdrawFromStrategy(strategy, currStrategyTVL - idealStrategyTVL);
            }
            if (idealStrategyTVL > currStrategyTVL) {
                amountsToInvest[i] = idealStrategyTVL - currStrategyTVL;
            }
        }

        // Loop through the strategies to invest in, and invest in them
        for (uint256 i = 0; i < MAX_STRATEGIES; i = uncheckedInc(i)) {
            uint256 amountToInvest = amountsToInvest[i];
            if (amountToInvest == 0) {
                continue;
            }

            // We aren't guaranteed that the vault has `amountToInvest` since there can be slippage
            // when divesting from strategies
            // NOTE: Strategies closer to the start of the queue are more likely to get the exact
            // amount of money needed
            amountToInvest = Math.min(amountToInvest, _asset.balanceOf(address(this)));
            if (amountToInvest == 0) {
                break;
            }
            // Deposit into strategy, making sure to not count this investment as a profit
            _depositIntoStrategy(withdrawalQueue[i], amountToInvest);
        }

        emit Rebalance(msg.sender);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

import {Multicallable} from "solady/src/utils/Multicallable.sol";

import {BaseStrategy as Strategy} from "src/strategies/BaseStrategy.sol";
import {AffineGovernable} from "src/utils/AffineGovernable.sol";
import {BridgeEscrow} from "./escrow/BridgeEscrow.sol";
import {WormholeRouter} from "./wormhole/WormholeRouter.sol";
import {uncheckedInc} from "src/libs/Unchecked.sol";

/**
 * @notice A core contract to be inherited by the L1 and L2 vault contracts. This contract handles adding
 * and removing strategies, investing in (and divesting from) strategies, harvesting gains/losses, and
 * strategy liquidation.
 */
abstract contract BaseVault is AccessControlUpgradeable, AffineGovernable, Multicallable {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                             INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    ERC20 _asset;

    /// @notice The token that the vault takes in and tries to get more of, e.g. USDC
    function asset() public view virtual returns (address) {
        return address(_asset);
    }

    /**
     * @dev Initialize the vault.
     * @param _governance The governance address.
     * @param vaultAsset The vault's input asset.
     * @param _wormholeRouter The wormhole router.
     * @param _bridgeEscrow Bridge escrow for receiving cross-chain transfers.
     */
    function baseInitialize(address _governance, ERC20 vaultAsset, address _wormholeRouter, BridgeEscrow _bridgeEscrow)
        internal
        virtual
    {
        governance = _governance;
        _asset = vaultAsset;
        wormholeRouter = _wormholeRouter;
        bridgeEscrow = _bridgeEscrow;

        // All roles use the default admin role
        // Governance has the admin role and all roles
        _grantRole(DEFAULT_ADMIN_ROLE, governance);
        _grantRole(HARVESTER, governance);

        lastHarvest = uint128(block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                        CROSS-CHAIN REBALANCING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice A contract used for sending and receiving messages via wormhole.
     * @dev We use an address since we need to cast this to the L1 and L2 router types.
     */
    address public wormholeRouter;
    /// @notice A "BridgeEscrow" contract for sending and receiving `token` across a bridge.
    BridgeEscrow public bridgeEscrow;

    /**
     * @notice Update the address of the wormhole router.
     * @param _router The new router.
     */
    function setWormholeRouter(address _router) external onlyGovernance {
        emit WormholeRouterSet({oldRouter: wormholeRouter, newRouter: _router});
        wormholeRouter = _router;
    }
    /**
     * @notice Update the address of the bridge escrow.
     * @param _escrow The new escrow.
     */

    function setBridgeEscrow(BridgeEscrow _escrow) external onlyGovernance {
        emit BridgeEscrowSet({oldEscrow: address(bridgeEscrow), newEscrow: address(_escrow)});
        bridgeEscrow = _escrow;
    }

    /**
     * @notice Emitted when the wormhole router is updated.
     * @param oldRouter The old router.
     * @param newRouter The new router.
     */
    event WormholeRouterSet(address indexed oldRouter, address indexed newRouter);
    /**
     * @notice Emitted when the escorw is updated.
     * @param oldEscrow The old router.
     * @param newEscrow The new router.
     */
    event BridgeEscrowSet(address indexed oldEscrow, address indexed newEscrow);

    /*//////////////////////////////////////////////////////////////
                             AUTHENTICATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Role with authority to call "harvest", i.e. update this vault's tvl
    bytes32 public constant HARVESTER = keccak256("HARVESTER");

    /*//////////////////////////////////////////////////////////////
                            WITHDRAWAL QUEUE
    //////////////////////////////////////////////////////////////*/

    uint8 constant MAX_STRATEGIES = 20;

    /**
     * @notice An ordered array of strategies representing the withdrawal queue. The withdrawal queue is used
     * whenever the vault wants to pull money out of strategies (cross-chain rebalancing and user withdrawals).
     * @dev The first strategy in the array (index 0) is withdrawn from first.
     * This is a list of the currently active strategies  (all non-zero addresses are active).
     */
    Strategy[MAX_STRATEGIES] public withdrawalQueue;

    /**
     * @notice Gets the full withdrawal queue.
     * @return The withdrawal queue.
     * @dev This gives easy access to the whole array (by default we can only get one index at a time)
     */
    function getWithdrawalQueue() external view returns (Strategy[MAX_STRATEGIES] memory) {
        return withdrawalQueue;
    }

    /**
     * @notice Sets a new withdrawal queue.
     * @param newQueue The new withdrawal queue.
     */
    function setWithdrawalQueue(Strategy[MAX_STRATEGIES] calldata newQueue) external onlyGovernance {
        // Maintain queue size
        require(newQueue.length == MAX_STRATEGIES, "BV: bad qu size");

        // Replace the withdrawal queue.
        withdrawalQueue = newQueue;

        emit WithdrawalQueueSet(newQueue);
    }

    /**
     * @notice Emitted when the withdrawal queue is updated.
     * @param newQueue The new withdrawal queue.
     */
    event WithdrawalQueueSet(Strategy[MAX_STRATEGIES] newQueue);

    /*//////////////////////////////////////////////////////////////
                               STRATEGIES
    //////////////////////////////////////////////////////////////*/

    /// @notice The total amount of underlying assets held in strategies at the time of the last harvest.
    uint256 public totalStrategyHoldings;

    struct StrategyInfo {
        bool isActive;
        uint16 tvlBps;
        uint232 balance;
    }

    /// @notice A map of strategy addresses to details
    mapping(Strategy => StrategyInfo) public strategies;

    uint256 constant MAX_BPS = 10_000;
    /// @notice The number of bps of the vault's tvl which may be given to strategies (at most MAX_BPS)
    uint256 public totalBps;

    /// @notice Emitted when a strategy is added by governance
    event StrategyAdded(Strategy indexed strategy);
    /// @notice Emitted when a strategy is removed by governance
    event StrategyRemoved(Strategy indexed strategy);

    /**
     * @notice Add a strategy
     * @param strategy The strategy to add
     * @param tvlBps The number of bps of our tvl the strategy will get when funds are distributed to strategies
     */
    function addStrategy(Strategy strategy, uint16 tvlBps) external onlyGovernance {
        _increaseTVLBps(tvlBps);
        strategies[strategy] = StrategyInfo({isActive: true, tvlBps: tvlBps, balance: 0});
        //  Add strategy to withdrawal queue
        withdrawalQueue[MAX_STRATEGIES - 1] = strategy;
        emit StrategyAdded(strategy);
        _organizeWithdrawalQueue();
    }

    /// @notice A helper function for increasing `totalBps`. Used when adding strategies or updating strategy allocs
    function _increaseTVLBps(uint256 tvlBps) internal {
        uint256 newTotalBps = totalBps + tvlBps;
        require(newTotalBps <= MAX_BPS, "BV: too many bps");
        totalBps = newTotalBps;
    }

    /**
     * @notice Push all zero addresses to the end of the array. This function is used whenever a strategy is
     * added or removed from the withdrawal queue
     * @dev Relative ordering of non-zero values is maintained.
     */
    function _organizeWithdrawalQueue() internal {
        // number or empty values we've seen iterating from left to right
        uint256 offset;

        for (uint256 i = 0; i < MAX_STRATEGIES; i = uncheckedInc(i)) {
            Strategy strategy = withdrawalQueue[i];
            if (address(strategy) == address(0)) {
                offset += 1;
            } else if (offset > 0) {
                // index of first empty value seen takes on value of `strategy`
                withdrawalQueue[i - offset] = strategy;
                withdrawalQueue[i] = Strategy(address(0));
            }
        }
    }

    /**
     * @notice Remove a strategy from the withdrawal queue. Fully divest from the strategy.
     * @param strategy The strategy to remove
     * @dev  removeStrategy MUST be called with harvest via multicall. This helps get the most accurate tvl numbers
     * and allows us to add any realized profits to our lockedProfit
     */
    function removeStrategy(Strategy strategy) external onlyGovernance {
        for (uint256 i = 0; i < MAX_STRATEGIES; i = uncheckedInc(i)) {
            if (strategy != withdrawalQueue[i]) {
                continue;
            }

            strategies[strategy].isActive = false;

            // The vault can re-allocate bps to a new strategy
            totalBps -= strategies[strategy].tvlBps;
            strategies[strategy].tvlBps = 0;

            // Remove strategy from withdrawal queue
            withdrawalQueue[i] = Strategy(address(0));
            emit StrategyRemoved(strategy);
            _organizeWithdrawalQueue();

            // Take all money out of strategy.
            _withdrawFromStrategy(strategy, strategy.totalLockedValue());
            break;
        }
    }

    /**
     * @notice Update tvl bps assigned to the given list of strategies
     * @param strategyList The list of strategies
     * @param strategyBps The new bps
     */
    function updateStrategyAllocations(Strategy[] calldata strategyList, uint16[] calldata strategyBps)
        external
        onlyRole(HARVESTER)
    {
        for (uint256 i = 0; i < strategyList.length; i = uncheckedInc(i)) {
            // Get the strategy at the current index.
            Strategy strategy = strategyList[i];

            // Ignore inactive (removed) strategies
            if (!strategies[strategy].isActive) continue;

            // update tvl bps
            totalBps -= strategies[strategy].tvlBps;
            _increaseTVLBps(strategyBps[i]);
            strategies[strategy].tvlBps = strategyBps[i];
        }
        emit StrategyAllocsUpdated(strategyList, strategyBps);
    }

    /**
     * @notice Emitted when we update tvl bps for a list of strategies.
     * @param strategyList The list of strategies.
     * @param strategyBps The new tvl bps for the strategies
     */
    event StrategyAllocsUpdated(Strategy[] strategyList, uint16[] strategyBps);

    /*//////////////////////////////////////////////////////////////
                      STRATEGY DEPOSIT/WITHDRAWAL
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted after the Vault deposits into a strategy contract.
     * @param strategy The strategy that was deposited into.
     * @param assets The amount of assets deposited.
     */
    event StrategyDeposit(Strategy indexed strategy, uint256 assets);

    /**
     * @notice Emitted after the Vault withdraws funds from a strategy contract.
     * @param strategy The strategy that was withdrawn from.
     * @param assetsRequested The amount of assets we tried to divest from the strategy.
     * @param assetsReceived The amount of assets actually withdrawn.
     */
    event StrategyWithdrawal(Strategy indexed strategy, uint256 assetsRequested, uint256 assetsReceived);

    /// @notice Deposit `assetAmount` amount of `asset` into strategies according to each strategy's `tvlBps`.
    function _depositIntoStrategies(uint256 assetAmount) internal {
        // All non-zero strategies are active
        for (uint256 i = 0; i < MAX_STRATEGIES; i = uncheckedInc(i)) {
            Strategy strategy = withdrawalQueue[i];
            if (address(strategy) == address(0)) {
                break;
            }
            _depositIntoStrategy(strategy, (assetAmount * strategies[strategy].tvlBps) / MAX_BPS);
        }
    }

    function _depositIntoStrategy(Strategy strategy, uint256 assets) internal {
        // Don't allow empty investments
        if (assets == 0) return;

        // Increase totalStrategyHoldings to account for the deposit.
        totalStrategyHoldings += assets;

        unchecked {
            // Without this the next harvest would count the deposit as profit.
            // Cannot overflow as the balance of one strategy can't exceed the sum of all.
            strategies[strategy].balance += uint232(assets);
        }

        // Approve assets to the strategy so we can deposit.
        _asset.safeApprove(address(strategy), assets);

        // Deposit into the strategy, will revert upon failure
        strategy.invest(assets);
        emit StrategyDeposit(strategy, assets);
    }

    /**
     * @notice Withdraw a specific amount of underlying tokens from a strategy.
     * @dev This is a "best effort" withdrawal. It could potentially withdraw nothing.
     * @param strategy The strategy to withdraw from.
     * @param assets  The amount of underlying tokens to withdraw.
     * @return The amount of assets actually received.
     */
    function _withdrawFromStrategy(Strategy strategy, uint256 assets) internal returns (uint256) {
        // Withdraw from the strategy
        uint256 amountWithdrawn = _divest(strategy, assets);

        // Without this the next harvest would count the withdrawal as a loss.
        // We update the balance to the current tvl because a withdrawal can reduce the tvl by more than the amount
        // withdrawn (e.g. fees during a swap)
        uint256 oldStratTVL = strategies[strategy].balance;
        uint256 newStratTvl = strategy.totalLockedValue();
        strategies[strategy].balance = uint232(newStratTvl);

        // Decrease totalStrategyHoldings to account for the withdrawal.
        // If we haven't harvested in a long time, newStratTvl could be bigger than oldStratTvl
        totalStrategyHoldings -= oldStratTVL > newStratTvl ? oldStratTVL - newStratTvl : 0;
        emit StrategyWithdrawal({strategy: strategy, assetsRequested: assets, assetsReceived: amountWithdrawn});
        return amountWithdrawn;
    }

    /// @dev A small wrapper around divest(). We try-catch to make sure that a bad strategy does not pause withdrawals.
    function _divest(Strategy strategy, uint256 assets) internal returns (uint256) {
        try strategy.divest(assets) returns (uint256 amountDivested) {
            return amountDivested;
        } catch {
            return 0;
        }
    }

    /*//////////////////////////////////////////////////////////////
                               HARVESTING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice A timestamp representing when the most recent harvest occurred.
     * @dev Since the time since the last harvest is used to calculate management fees, this is set
     * to `block.timestamp` (instead of 0) during initialization.
     */
    uint128 public lastHarvest;
    /// @notice The amount of profit *originally* locked after harvesting from a strategy
    uint128 public maxLockedProfit;
    /// @notice Amount of time in seconds that profit takes to fully unlock. See lockedProfit().
    uint256 public constant LOCK_INTERVAL = 24 hours;

    /**
     * @notice Emitted after a successful harvest.
     * @param user The authorized user who triggered the harvest.
     * @param strategies The trusted strategies that were harvested.
     */
    event Harvest(address indexed user, Strategy[] strategies);

    /**
     * @notice Harvest a set of trusted strategies.
     * @param strategyList The trusted strategies to harvest.
     * @dev Will always revert if profit from last harvest has not finished unlocking.
     */
    function harvest(Strategy[] calldata strategyList) external onlyRole(HARVESTER) {
        // Profit must not be unlocking
        require(block.timestamp >= lastHarvest + LOCK_INTERVAL, "BV: profit unlocking");

        // Get the Vault's current total strategy holdings.
        uint256 oldTotalStrategyHoldings = totalStrategyHoldings;

        // Used to store the new total strategy holdings after harvesting.
        uint256 newTotalStrategyHoldings = oldTotalStrategyHoldings;

        // Used to store the total profit accrued by the strategies.
        uint256 totalProfitAccrued;

        // Will revert if any of the specified strategies are untrusted.
        for (uint256 i = 0; i < strategyList.length; i = uncheckedInc(i)) {
            // Get the strategy at the current index.
            Strategy strategy = strategyList[i];

            // Ignore inactive (removed) strategies
            if (!strategies[strategy].isActive) {
                continue;
            }

            // Get the strategy's previous and current balance.
            uint232 balanceLastHarvest = strategies[strategy].balance;
            uint256 balanceThisHarvest = strategy.totalLockedValue();

            // Update the strategy's stored balance.
            strategies[strategy].balance = uint232(balanceThisHarvest);

            // Increase/decrease newTotalStrategyHoldings based on the profit/loss registered.
            // We cannot wrap the subtraction in parenthesis as it would underflow if the strategy had a loss.
            newTotalStrategyHoldings = newTotalStrategyHoldings + balanceThisHarvest - balanceLastHarvest;

            unchecked {
                // Update the total profit accrued while counting losses as zero profit.
                // Cannot overflow as we already increased total holdings without reverting.
                totalProfitAccrued += balanceThisHarvest > balanceLastHarvest
                    ? balanceThisHarvest - balanceLastHarvest // Profits since last harvest.
                    : 0; // If the strategy registered a net loss we don't have any new profit.
            }
        }

        // Update max unlocked profit based on any remaining locked profit plus new profit.
        maxLockedProfit = uint128(lockedProfit() + totalProfitAccrued);

        // Set strategy holdings to our new total.
        totalStrategyHoldings = newTotalStrategyHoldings;

        // Assess fees (using old lastHarvest) and update the last harvest timestamp.
        _assessFees();
        lastHarvest = uint128(block.timestamp);

        emit Harvest(msg.sender, strategyList);
    }

    /**
     * @notice Current locked profit amount.
     * @dev Profit unlocks uniformly over `LOCK_INTERVAL` seconds after the last harvest
     */
    function lockedProfit() public view virtual returns (uint256) {
        if (block.timestamp >= lastHarvest + LOCK_INTERVAL) {
            return 0;
        }

        uint256 unlockedProfit = (maxLockedProfit * (block.timestamp - lastHarvest)) / LOCK_INTERVAL;
        return maxLockedProfit - unlockedProfit;
    }

    /*//////////////////////////////////////////////////////////////
                        LIQUIDATION/REBALANCING
    //////////////////////////////////////////////////////////////*/

    /// @notice The total amount of the underlying asset the vault has.
    function vaultTVL() public view returns (uint256) {
        return _asset.balanceOf(address(this)) + totalStrategyHoldings;
    }

    /**
     * @notice Emitted when the vault must make a certain amount of assets available
     * @dev We liquidate during cross chain rebalancing or withdrawals.
     * @param assetsRequested The amount we wanted to make available for withdrawal.
     * @param assetsLiquidated The amount we actually liquidated.
     */
    event Liquidation(uint256 assetsRequested, uint256 assetsLiquidated);

    /**
     * @notice Withdraw `amount` of underlying asset from strategies.
     * @dev Always check the return value when using this function, we might not liquidate anything!
     * @param amount The amount we want to liquidate
     * @return The amount we actually liquidated
     */
    function _liquidate(uint256 amount) internal returns (uint256) {
        uint256 amountLiquidated;
        for (uint256 i = 0; i < MAX_STRATEGIES; i = uncheckedInc(i)) {
            Strategy strategy = withdrawalQueue[i];
            if (address(strategy) == address(0)) {
                break;
            }

            uint256 balance = _asset.balanceOf(address(this));
            if (balance >= amount) {
                break;
            }

            uint256 amountNeeded = amount - balance;
            amountNeeded = Math.min(amountNeeded, strategies[strategy].balance);

            // Force withdraw of token from strategy
            uint256 withdrawn = _withdrawFromStrategy(strategy, amountNeeded);
            amountLiquidated += withdrawn;
        }
        emit Liquidation({assetsRequested: amount, assetsLiquidated: amountLiquidated});
        return amountLiquidated;
    }

    /**
     * @notice Assess fees.
     * @dev This is called during harvest() to assess management fees.
     */
    function _assessFees() internal virtual {}

    /**
     * @notice Emitted when we do a strategy rebalance, i.e. when we make the strategy tvls match their tvl bps
     * @param caller The caller
     */
    event Rebalance(address indexed caller);

    /// @notice  Rebalance strategies according to given tvl bps
    function rebalance() external onlyRole(HARVESTER) {
        uint256 tvl = vaultTVL();

        // Loop through all strategies. Divesting from those whose tvl is too high,
        // Invest in those whose tvl is too low
        uint256[MAX_STRATEGIES] memory amountsToInvest;

        for (uint256 i = 0; i < MAX_STRATEGIES; i = uncheckedInc(i)) {
            Strategy strategy = withdrawalQueue[i];
            if (address(strategy) == address(0)) {
                break;
            }

            uint256 idealStrategyTVL = (tvl * strategies[strategy].tvlBps) / MAX_BPS;
            uint256 currStrategyTVL = strategy.totalLockedValue();
            if (idealStrategyTVL < currStrategyTVL) {
                _withdrawFromStrategy(strategy, currStrategyTVL - idealStrategyTVL);
            }
            if (idealStrategyTVL > currStrategyTVL) {
                amountsToInvest[i] = idealStrategyTVL - currStrategyTVL;
            }
        }

        // Loop through the strategies to invest in, and invest in them
        for (uint256 i = 0; i < MAX_STRATEGIES; i = uncheckedInc(i)) {
            uint256 amountToInvest = amountsToInvest[i];
            if (amountToInvest == 0) {
                continue;
            }

            // We aren't guaranteed that the vault has `amountToInvest` since there can be slippage
            // when divesting from strategies
            // NOTE: Strategies closer to the start of the queue are more likely to get the exact
            // amount of money needed
            amountToInvest = Math.min(amountToInvest, _asset.balanceOf(address(this)));
            if (amountToInvest == 0) {
                break;
            }
            // Deposit into strategy, making sure to not count this investment as a profit
            _depositIntoStrategy(withdrawalQueue[i], amountToInvest);
        }

        emit Rebalance(msg.sender);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {L2Vault} from "./L2Vault.sol";
import {uncheckedInc} from "src/libs/Unchecked.sol";

contract EmergencyWithdrawalQueue {
    /// @notice Address of Alpine vault.
    L2Vault public immutable vault;

    constructor(L2Vault _vault) {
        vault = _vault;
    }

    /*//////////////////////////////////////////////////////////////
                              QUEUE STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct representing withdrawalRequest stored in each queue node.
    struct WithdrawalRequest {
        address owner;
        address receiver;
        uint256 shares;
        uint256 pushTime;
    }
    /// @notice Mapping representing the queue.

    mapping(uint256 => WithdrawalRequest) queue;

    /**
     * @dev The tailPtr is to the right of the headPtr on a number line
     * We start with tail(0) -> head(1)
     * After an enqueue we have tail(1) == head(1)
     */
    /// @notice Pointer to head of the queue.
    uint128 public headPtr = 1;
    /// @notice Pointer to tail of the queue.
    uint128 public tailPtr = 0;

    /// @notice current size of the queue
    function size() public view returns (uint256) {
        return (tailPtr + 1) - headPtr;
    }

    /*//////////////////////////////////////////////////////////////
                                  DEBT
    //////////////////////////////////////////////////////////////*/

    /// @notice Debt in shares unit.
    uint256 public shareDebt;

    /// @notice Total debt
    function totalDebt() public view returns (uint256) {
        return vault.convertToAssets(shareDebt);
    }

    // @notice User debts in share unit
    mapping(address => uint256) public ownerToDebt;

    /*//////////////////////////////////////////////////////////////
                                PUSH/POP
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Emitted when we push onto the queue.
     * @param pos The users position in the queue.
     * @param owner The owner of the shares.
     * @param receiver The user who will receive the assets during share redemption
     * @param shares The number of shares to redeem.
     */
    event Push(uint256 indexed pos, address indexed owner, address indexed receiver, uint256 shares);
    /// @notice Emitted when we pop a request from the queue. See `Push` for the parameter info
    /// @dev This is only emitted when we successfully burn the user's shares. Invalid requests are skipped.
    event Pop(uint256 indexed pos, address indexed owner, address indexed receiver, uint256 shares);

    /// @notice Enqueue user withdrawal requests to the queue.
    function enqueue(address owner, address receiver, uint256 shares) external {
        require(msg.sender == address(vault), "EWQ: only vault");
        tailPtr += 1;
        queue[tailPtr] = WithdrawalRequest(owner, receiver, shares, block.timestamp);
        shareDebt += shares;
        ownerToDebt[owner] += shares;
        emit Push(tailPtr, owner, receiver, shares);
    }

    /// @notice Dequeue user withdrawal requests.
    function dequeue() external {
        require(tailPtr >= headPtr, "EWQ: queue is empty");
        WithdrawalRequest memory withdrawalRequest = queue[headPtr];
        delete queue[headPtr];
        shareDebt -= withdrawalRequest.shares;
        ownerToDebt[withdrawalRequest.owner] -= withdrawalRequest.shares;

        try vault.redeem(withdrawalRequest.shares, withdrawalRequest.receiver, withdrawalRequest.owner) {
            emit Pop(headPtr, withdrawalRequest.owner, withdrawalRequest.receiver, withdrawalRequest.shares);
            headPtr += 1;
        } catch Error(string memory reason) {
            if (keccak256(bytes(reason)) == keccak256("L2Vault: bad dequeue")) {
                // Do nothing while we wait for the vault to get enough assets
                revert("Ewq: assets pending");
            } else {
                // The request is invalid for some reason
                // (e.g. the user has a lower balance than they did when making request)
                headPtr += 1;
            }
        }
    }

    /// @notice Dequeue user withdrawal requests in a batch.
    function dequeueBatch(uint256 batchSize) external {
        require(size() >= batchSize, "EWQ: batch too big");

        uint256 batchTailPtr = headPtr + batchSize;
        uint256 shareDebtReduction;

        for (uint256 ptr = headPtr; ptr < batchTailPtr; ptr = uncheckedInc(ptr)) {
            WithdrawalRequest memory withdrawalRequest = queue[ptr];
            delete queue[ptr];
            shareDebtReduction += withdrawalRequest.shares;
            ownerToDebt[withdrawalRequest.owner] -= withdrawalRequest.shares;

            try vault.redeem(withdrawalRequest.shares, withdrawalRequest.receiver, withdrawalRequest.owner) {
                emit Pop(ptr, withdrawalRequest.owner, withdrawalRequest.receiver, withdrawalRequest.shares);
            } catch Error(string memory reason) {
                if (keccak256(bytes(reason)) == keccak256("L2Vault: bad dequeue")) {
                    // Not enough assets
                    revert("Ewq: assets pending");
                } else {
                    // The request is invalid for some reason
                    // (e.g. the user has a lower balance than they did when making request)
                }
            }
        }
        shareDebt -= shareDebtReduction;
        headPtr += uint128(batchSize);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {BaseRelayRecipient} from "@opengsn/contracts/src/BaseRelayRecipient.sol";

import {BaseVault} from "src/vaults/cross-chain-vault/BaseVault.sol";
import {L2BridgeEscrow} from "./escrow/L2BridgeEscrow.sol";
import {DetailedShare} from "src/utils/Detailed.sol";
import {L2WormholeRouter} from "./wormhole/L2WormholeRouter.sol";
import {IERC4626} from "src/interfaces/IERC4626.sol";
import {EmergencyWithdrawalQueue} from "./EmergencyWithdrawalQueue.sol";

/**
 * @notice An L2 vault. This is a cross-chain vault, i.e. some funds deposited here will be moved to L1 for investment.
 * @dev This vault is ERC4626 compliant. See the EIP description here: https://eips.ethereum.org/EIPS/eip-4626.
 * @author Affine Devs. Inspired by OpenZeppelin and Rari-Capital.
 */
contract L2Vault is
    ERC20Upgradeable,
    UUPSUpgradeable,
    PausableUpgradeable,
    BaseVault,
    BaseRelayRecipient,
    DetailedShare,
    IERC4626
{
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                             INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function initialize(
        address _governance,
        ERC20 _vaultAsset,
        address _wormholeRouter,
        L2BridgeEscrow _bridgeEscrow,
        EmergencyWithdrawalQueue _emergencyWithdrawalQueue,
        address forwarder,
        uint8[2] memory layerRatios,
        uint256[2] memory fees,
        uint256[2] memory ewqParams
    ) public initializer {
        __ERC20_init("USD Earn", "usdEarn");
        __UUPSUpgradeable_init();
        __Pausable_init();
        baseInitialize(_governance, _vaultAsset, _wormholeRouter, _bridgeEscrow);

        emergencyWithdrawalQueue = _emergencyWithdrawalQueue;
        l1Ratio = layerRatios[0];
        l2Ratio = layerRatios[1];
        rebalanceDelta = 10_000 * _asset.decimals();
        canTransferToL1 = true;
        canRequestFromL1 = true;
        lastTVLUpdate = uint128(block.timestamp);

        _grantRole(GUARDIAN_ROLE, _governance);
        _setTrustedForwarder(forwarder);

        withdrawalFee = fees[0];
        managementFee = fees[1];

        ewqMinAssets = ewqParams[0];
        ewqMinFee = ewqParams[1];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGovernance {}

    /*//////////////////////////////////////////////////////////////
                        META-TRANSACTION SUPPORT
    //////////////////////////////////////////////////////////////*/

    function _msgSender() internal view override(ContextUpgradeable, BaseRelayRecipient) returns (address) {
        return BaseRelayRecipient._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, BaseRelayRecipient) returns (bytes calldata) {
        return BaseRelayRecipient._msgData();
    }

    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }

    /**
     * @notice Set the trusted forwarder address
     * @param forwarder The new forwarder address
     */
    function setTrustedForwarder(address forwarder) external onlyGovernance {
        _setTrustedForwarder(forwarder);
    }

    /*//////////////////////////////////////////////////////////////
                             ERC4626 BASICS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseVault
    function asset() public view override(BaseVault, IERC4626) returns (address assetTokenAddress) {
        return address(_asset);
    }

    function decimals() public view override returns (uint8) {
        // E.g. for USDC, we want the initial price of a share to be $100.
        // For an initial price of 1 USDC / share we would have 1e6 * 1e8 / 1 = 1e14 shares given that we have 14 (6 + 8) decimals
        // in our share token. But since we want 100 USDC / share for the initial price, we add an extra two decimal places
        return _asset.decimals() + 10;
    }

    /*//////////////////////////////////////////////////////////////
                             AUTHENTICATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Accounts with thiss role can pause and unpause the contract.
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN");

    /// @notice Pause the contract.
    function pause() external onlyRole(GUARDIAN_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract.
    function unpause() external onlyRole(GUARDIAN_ROLE) {
        _unpause();
    }

    /*//////////////////////////////////////////////////////////////
                                  FEES
    //////////////////////////////////////////////////////////////*/

    /// @notice Fee charged to vault over a year, number is in bps.
    uint256 public managementFee;
    /// @notice  Fee charged on redemption of shares, number is in bps.
    uint256 public withdrawalFee;
    /// @notice Minimal fee charged if withdrawal or redeem request is added to ewq, number is in `asset`.
    uint256 public ewqMinFee;
    /// @notice Minimal amount needed to enqueue a request to ewq, number is in `asset`.
    uint256 public ewqMinAssets;

    event ManagementFeeSet(uint256 oldFee, uint256 newFee);
    event WithdrawalFeeSet(uint256 oldFee, uint256 newFee);

    function setManagementFee(uint256 feeBps) external onlyGovernance {
        emit ManagementFeeSet({oldFee: managementFee, newFee: feeBps});
        managementFee = feeBps;
    }

    function setWithdrawalFee(uint256 feeBps) external onlyGovernance {
        emit WithdrawalFeeSet({oldFee: withdrawalFee, newFee: feeBps});
        withdrawalFee = feeBps;
    }

    function setEwqParams(uint256 _ewqMinFee, uint256 _ewqMinAssets) external onlyGovernance {
        ewqMinFee = _ewqMinFee;
        ewqMinAssets = _ewqMinAssets;
    }

    uint256 constant SECS_PER_YEAR = 365 days;

    /// @dev Collect management fees during calls to `harvest`.
    function _assessFees() internal override {
        // duration / SECS_PER_YEAR * feebps / MAX_BPS * totalSupply
        uint256 duration = block.timestamp - lastHarvest;

        uint256 feesBps = (duration * managementFee) / SECS_PER_YEAR;
        uint256 numSharesToMint = (feesBps * totalSupply()) / MAX_BPS;

        if (numSharesToMint == 0) {
            return;
        }
        _mint(governance, numSharesToMint);
    }

    /*//////////////////////////////////////////////////////////////
                                DEPOSITS
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) external whenNotPaused returns (uint256 shares) {
        shares = previewDeposit(assets);
        _deposit(assets, shares, receiver);
    }

    function mint(uint256 shares, address receiver) external whenNotPaused returns (uint256 assets) {
        assets = previewMint(shares);
        _deposit(assets, shares, receiver);
    }

    /// @dev Deposit helper used in deposit/mint.
    function _deposit(uint256 assets, uint256 shares, address receiver) internal {
        require(shares > 0, "L2Vault: zero shares");
        address caller = _msgSender();

        _asset.safeTransferFrom(caller, address(this), assets);
        _mint(receiver, shares);
        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @notice Deposit `asset` into strategies
     * @param amount The amount of `asset` to deposit
     */
    function depositIntoStrategies(uint256 amount) external whenNotPaused onlyRole(HARVESTER) {
        // Deposit entire balance of `_asset` into strategies
        _depositIntoStrategies(amount);
    }

    /*//////////////////////////////////////////////////////////////
                              WITHDRAWALS
    //////////////////////////////////////////////////////////////*/

    /// @notice A withdrawal registry. When this vault has no liquidity, requests go here.
    EmergencyWithdrawalQueue public emergencyWithdrawalQueue;

    event EwqSet(EmergencyWithdrawalQueue indexed oldQ, EmergencyWithdrawalQueue indexed newQ);

    /**
     * @notice Update the address of the emergency withdrawal queue.
     * @param _ewq The new queue.
     */
    function setEwq(EmergencyWithdrawalQueue _ewq) external onlyGovernance {
        emit EwqSet({oldQ: emergencyWithdrawalQueue, newQ: _ewq});
        emergencyWithdrawalQueue = _ewq;
    }

    function redeem(uint256 shares, address receiver, address owner) external whenNotPaused returns (uint256 assets) {
        assets = _redeem(_convertToAssets(shares, Rounding.Down), shares, receiver, owner);
    }

    function withdraw(uint256 assets, address receiver, address owner)
        external
        whenNotPaused
        returns (uint256 shares)
    {
        shares = previewWithdraw(assets);
        _redeem(assets, shares, receiver, owner);
    }

    /// @dev A withdraw helper used in withdraw/redeem.
    function _redeem(uint256 assets, uint256 shares, address receiver, address owner)
        internal
        returns (uint256 assetsToUser)
    {
        EmergencyWithdrawalQueue ewq = emergencyWithdrawalQueue;
        // Only real share amounts are allowed since we might create an ewq request
        require(shares <= balanceOf(owner) + ewq.ownerToDebt(owner), "L2Vault: min shares");

        uint256 assetsFee = _getWithdrawalFee(assets);
        assetsToUser = assets - assetsFee;

        // We must be able to repay all queued users and the current user.
        uint256 assetDemand = assets + ewq.totalDebt();
        _liquidate(assetDemand);

        // The ewq does not need approval to burn shares.
        address caller = _msgSender();
        if (caller != owner && caller != address(ewq)) _spendAllowance(owner, caller, shares);

        // Add to emergency withdrawal queue if there is not enough liquidity to satify requests.
        if (_asset.balanceOf(address(this)) < assetDemand) {
            if (caller != address(ewq)) {
                // We need to enqueue, make sure that the requested amount is large enough.
                if (assets < ewqMinAssets) {
                    revert("L2Vault: bad enqueue, min assets");
                }
                ewq.enqueue(owner, receiver, shares);
                return 0;
            } else {
                revert("L2Vault: bad dequeue");
            }
        }

        // Burn shares and give user equivalent value in `asset` (minus withdrawal fees).
        _burn(owner, shares);
        emit Withdraw(caller, receiver, owner, assets, shares);

        _asset.safeTransfer(receiver, assetsToUser);
        _asset.safeTransfer(governance, assetsFee);
    }

    /*//////////////////////////////////////////////////////////////
                             EXCHANGE RATES
    //////////////////////////////////////////////////////////////*/

    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    function totalAssets() public view returns (uint256 totalManagedAssets) {
        return vaultTVL() + l1TotalLockedValue - lockedProfit() - lockedTVL();
    }

    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        shares = _convertToShares(assets, Rounding.Down);
    }

    /// @dev In previewDeposit we want to round down, but in previewWithdraw we want to round up
    function _convertToShares(uint256 assets, Rounding roundingDirection) internal view returns (uint256 shares) {
        // Even if there are no shares or assets in the vault, we start with 1 wei of asset and 1e8 shares
        // This helps mitigate price inflation attacks: https://github.com/transmissions11/solmate/issues/178
        // See https://www.rileyholterhus.com/writing/bunni as well.
        // The solution is inspired by YieldBox
        uint256 totalShares = totalSupply() + 1e8;
        uint256 _totalAssets = totalAssets() + 1;

        if (roundingDirection == Rounding.Up) {
            shares = assets.mulDivUp(totalShares, _totalAssets);
        } else {
            shares = assets.mulDivDown(totalShares, _totalAssets);
        }
    }

    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        assets = _convertToAssets(shares, Rounding.Down);
    }

    /// @dev In previewMint, we want to round up, but in previewRedeem we want to round down
    function _convertToAssets(uint256 shares, Rounding roundingDirection) internal view returns (uint256 assets) {
        uint256 totalShares = totalSupply() + 1e8;
        uint256 _totalAssets = totalAssets() + 1;

        if (roundingDirection == Rounding.Up) {
            assets = shares.mulDivUp(_totalAssets, totalShares);
        } else {
            assets = shares.mulDivDown(_totalAssets, totalShares);
        }
    }

    function previewDeposit(uint256 assets) public view returns (uint256 shares) {
        return _convertToShares(assets, Rounding.Down);
    }

    function previewMint(uint256 shares) public view returns (uint256 assets) {
        assets = _convertToAssets(shares, Rounding.Up);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256 shares) {
        shares = _convertToShares(assets, Rounding.Up);
    }

    function previewRedeem(uint256 shares) public view returns (uint256 assets) {
        uint256 rawAssets = _convertToAssets(shares, Rounding.Down);
        uint256 assetsFee = _getWithdrawalFee(rawAssets);
        assets = rawAssets - assetsFee;
    }

    /// @dev  Return amount of `asset` to be given to user after applying withdrawal fee
    function _getWithdrawalFee(uint256 tokenAmount) internal view returns (uint256) {
        uint256 feeAmount = tokenAmount.mulDivUp(withdrawalFee, MAX_BPS);
        if (_msgSender() == address(emergencyWithdrawalQueue)) {
            feeAmount = Math.max(feeAmount, ewqMinFee);
        }
        return feeAmount;
    }

    /*//////////////////////////////////////////////////////////////
                       DEPOSIT/WITHDRAWAL LIMITS
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address receiver) public pure returns (uint256 maxAssets) {
        receiver;
        maxAssets = type(uint256).max;
    }

    function maxMint(address receiver) public pure returns (uint256 maxShares) {
        receiver;
        maxShares = type(uint256).max;
    }

    function maxRedeem(address owner) public view returns (uint256 maxShares) {
        maxShares = balanceOf(owner);
    }

    function maxWithdraw(address owner) public view returns (uint256 maxAssets) {
        maxAssets = _convertToAssets(balanceOf(owner), Rounding.Down);
    }

    /*//////////////////////////////////////////////////////////////
                        CROSS-CHAIN REBALANCING
    //////////////////////////////////////////////////////////////*/

    /// @notice TVL of L1 denominated in `asset` (e.g. USDC). This value will be updated by wormhole messages.
    uint256 public l1TotalLockedValue;

    /// @notice Represents the amount of tvl (in `asset`) that should exist on L1
    uint8 public l1Ratio;
    /// @notice Represents the amount of tvl (in `asset`) that should exist on L2
    uint8 public l2Ratio;

    /// @notice If true, we can send assets to L1.
    bool public canTransferToL1;
    /// @notice If false, we can requests assets from L1.
    bool public canRequestFromL1;

    /**
     * @notice The delta required to trigger a rebalance. The delta is the difference between current and ideal tvl
     * on a given layer.
     * @dev Fits into the same slot as the four above variables.
     */
    uint224 public rebalanceDelta;

    /**
     * @notice Set the layer ratios
     * @param _l1Ratio The layer 1 ratio
     * @param _l2Ratio The layer 2 ratio
     */
    function setLayerRatios(uint8 _l1Ratio, uint8 _l2Ratio) external onlyGovernance {
        l1Ratio = _l1Ratio;
        l2Ratio = _l2Ratio;
        emit LayerRatiosSet({l1Ratio: l1Ratio, l2Ratio: l2Ratio});
    }

    event LayerRatiosSet(uint8 l1Ratio, uint8 l2Ratio);

    /**
     * @notice Set the rebalance delta
     * @param _rebalanceDelta The new rebalance delta
     */
    function setRebalanceDelta(uint224 _rebalanceDelta) external onlyGovernance {
        emit RebalanceDeltaSet({oldDelta: rebalanceDelta, newDelta: _rebalanceDelta});
        rebalanceDelta = _rebalanceDelta;
    }

    event RebalanceDeltaSet(uint224 oldDelta, uint224 newDelta);

    /// @notice The last time the tvl was updated. We need this to let L1 tvl updates unlock over time.
    uint128 lastTVLUpdate;

    /// @notice See maxLockedProfit
    uint128 maxLockedTVL;

    /// @notice See lockedProfit. This is the same, except we are profiting from L1 tvl info.
    function lockedTVL() public view returns (uint256) {
        uint256 _maxLockedTVL = maxLockedTVL;
        uint256 _lastTVLUpdate = lastTVLUpdate;
        if (block.timestamp >= _lastTVLUpdate + LOCK_INTERVAL) {
            return 0;
        }

        uint256 unlockedTVL = (_maxLockedTVL * (block.timestamp - _lastTVLUpdate)) / LOCK_INTERVAL;
        return _maxLockedTVL - unlockedTVL;
    }

    /**
     * @notice Receive a tvl message from the womhole router.
     * @param tvl The L1 tvl.
     * @param received True if L1 has received our last transfer.
     */
    function receiveTVL(uint256 tvl, bool received) external {
        require(msg.sender == wormholeRouter, "L2Vault: only router");

        // If L1 has received the last transfer we sent it, unlock the L2->L1 bridge
        if (received && !canTransferToL1) {
            canTransferToL1 = true;
        }

        // Only rebalance if all cross chain transfers have been settled.
        // If the L1 vault is sending assets (!canRequestFromL1), then its TVL could be wrong. Also
        // we don't to accidentally request assets again. If (!canTransferToL1), we don't want to accidentally
        // send assets when one transfer to L1 is already in progress
        if (!canTransferToL1 || !canRequestFromL1) {
            revert("Rebalance in progress");
        }

        // Update l1TotalLockedValue to match what we received from L1
        // Any increase in L1's tvl will unlock linearly, just as when harvesting from strategies
        uint256 oldL1TVL = l1TotalLockedValue;
        uint256 totalProfit = tvl > oldL1TVL ? tvl - oldL1TVL : 0;
        maxLockedTVL = uint128(totalProfit + lockedTVL());
        lastTVLUpdate = uint128(block.timestamp);
        l1TotalLockedValue = tvl;

        (bool invest, uint256 delta) = _computeRebalance();
        if (delta < rebalanceDelta) {
            return;
        }
        _l1L2Rebalance(invest, delta);
    }

    /// @dev Compute the amount of assets to be sent to/from L1
    function _computeRebalance() internal view returns (bool, uint256) {
        uint256 numSlices = l1Ratio + l2Ratio;
        // Set aside assets for the withdrawal queue
        uint256 l1IdealAmount =
            (l1Ratio * (vaultTVL() + l1TotalLockedValue - emergencyWithdrawalQueue.totalDebt())) / numSlices;

        bool invest;
        uint256 delta;
        if (l1IdealAmount >= l1TotalLockedValue) {
            invest = true;
            delta = l1IdealAmount - l1TotalLockedValue;
        } else {
            delta = l1TotalLockedValue - l1IdealAmount;
        }
        return (invest, delta);
    }

    /// @dev Send/receive assets from L1
    function _l1L2Rebalance(bool invest, uint256 amount) internal {
        if (invest) {
            _liquidate(amount);
            uint256 amountToSend = Math.min(_asset.balanceOf(address(this)), amount);
            _transferToL1(amountToSend);
        } else {
            _divestFromL1(amount);
        }
    }

    /// @dev Transfer assets to L1 via Polygon Pos bridge
    function _transferToL1(uint256 amount) internal {
        // Send assets
        _asset.safeTransfer(address(bridgeEscrow), amount);
        L2BridgeEscrow(address(bridgeEscrow)).withdraw(amount);
        emit TransferToL1(amount);

        // Update bridge state and L1 TVL (value of totalAssets is unchanged)
        canTransferToL1 = false;
        l1TotalLockedValue += amount;

        // Let L1 know how much assets we sent
        L2WormholeRouter(wormholeRouter).reportFundTransfer(amount);
    }

    event TransferToL1(uint256 amount);

    /// @dev Request assets from L1
    function _divestFromL1(uint256 amount) internal {
        L2WormholeRouter(wormholeRouter).requestFunds(amount);
        canRequestFromL1 = false;
        emit RequestFromL1(amount);
    }

    event RequestFromL1(uint256 amount);

    /**
     * @notice Called by bridgeEscrow after assets are transferred to vault.
     * @param amount The amount of assets.
     */
    function afterReceive(uint256 amount) external {
        require(_msgSender() == address(bridgeEscrow), "L2Vault: only escrow");
        l1TotalLockedValue -= amount;
        canRequestFromL1 = true;
    }

    /*//////////////////////////////////////////////////////////////
                          DETAILED PRICE INFO
    //////////////////////////////////////////////////////////////*/

    function detailedTVL() external view override returns (Number memory tvl) {
        tvl = Number({num: totalAssets(), decimals: _asset.decimals()});
    }

    function detailedPrice() external view override returns (Number memory price) {
        price = Number({num: convertToAssets(10 ** decimals()), decimals: _asset.decimals()});
    }

    function detailedTotalSupply() external view override returns (Number memory supply) {
        supply = Number({num: totalSupply(), decimals: decimals()});
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

import {BaseVault} from "src/vaults/cross-chain-vault/BaseVault.sol";

abstract contract BridgeEscrow {
    using SafeTransferLib for ERC20;

    /// @notice The input asset.
    ERC20 public immutable asset;
    /// @notice The wormhole router contract.
    address public immutable wormholeRouter;
    /// @notice Governance address (shared with vault).
    address public immutable governance;

    /**
     * @notice Emitted whenever we transfer funds from this escrow to the vault
     * @param assets The amount of assets transferred
     */
    event TransferToVault(uint256 assets);

    constructor(BaseVault _vault) {
        wormholeRouter = _vault.wormholeRouter();
        asset = ERC20(_vault.asset());
        governance = _vault.governance();
    }

    /**
     * @notice Send assets to vault.
     * @param assets The amount of assets to send.
     * @param exitProof Proof needed by Polygon Pos bridge to unlock assets on Ethereum.
     */
    function clearFunds(uint256 assets, bytes calldata exitProof) external {
        require(msg.sender == wormholeRouter, "BE: Only wormhole router");
        _clear(assets, exitProof);
    }

    /// @notice Escape hatch for governance in an emergency.
    function rescueFunds(uint256 amount, bytes calldata exitProof) external {
        require(msg.sender == governance, "BE: Only Governance");
        _clear(amount, exitProof);
    }

    function _clear(uint256 assets, bytes calldata exitProof) internal virtual;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

import {BridgeEscrow} from "./BridgeEscrow.sol";
import {L2Vault} from "src/vaults/cross-chain-vault/L2Vault.sol";

interface IChildERC20 {
    function withdraw(uint256 amount) external;
}

contract L2BridgeEscrow is BridgeEscrow {
    using SafeTransferLib for ERC20;

    /// @notice The L2Vault.
    L2Vault public immutable vault;

    constructor(L2Vault _vault) BridgeEscrow(_vault) {
        vault = _vault;
    }

    /// @notice Send `amount` of `asset` to L1BridgeEscrow.
    function withdraw(uint256 amount) external {
        require(msg.sender == address(vault), "BE: Only vault");
        IChildERC20(address(asset)).withdraw(amount);
    }

    function _clear(uint256 amount, bytes calldata /* exitProof */ ) internal override {
        uint256 balance = asset.balanceOf(address(this));
        require(balance >= amount, "BE: Funds not received");
        asset.safeTransfer(address(vault), balance);

        emit TransferToVault(balance);
        vault.afterReceive(balance);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {IWormhole} from "src/interfaces/IWormhole.sol";
import {L2Vault} from "src/vaults/cross-chain-vault/L2Vault.sol";
import {WormholeRouter} from "./WormholeRouter.sol";
import {Constants} from "src/libs/Constants.sol";

contract L2WormholeRouter is WormholeRouter {
    function otherLayerWormholeId() public pure override returns (uint16) {
        return 2;
    }

    constructor(L2Vault _vault, IWormhole _wormhole) WormholeRouter(_vault, _wormhole) {}

    /// @notice Let L1 know that is should receive `amount` of `asset`.
    function reportFundTransfer(uint256 amount) external payable {
        require(msg.sender == address(vault), "WR: Only vault");
        bytes memory payload = abi.encode(Constants.L2_FUND_TRANSFER_REPORT, amount);
        uint64 sequence = wormhole.nextSequence(address(this));
        wormhole.publishMessage{value: msg.value}(uint32(sequence), payload, consistencyLevel);
    }

    /// @notice Request of `amount` of `asset` from L1Vault.
    function requestFunds(uint256 amount) external payable {
        require(msg.sender == address(vault), "WR: Only vault");
        bytes memory payload = abi.encode(Constants.L2_FUND_REQUEST, amount);
        uint64 sequence = wormhole.nextSequence(address(this));
        wormhole.publishMessage{value: msg.value}(uint32(sequence), payload, consistencyLevel);
    }

    /// @notice Receive `message` confirming transfer from L1Vault.
    function receiveFunds(bytes calldata message) external {
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole.parseAndVerifyVM(message);
        require(valid, reason);
        _validateWormholeMessageEmitter(vm);
        nextValidNonce = vm.nonce + 1;
        (bytes32 msgType, uint256 amount) = abi.decode(vm.payload, (bytes32, uint256));
        require(msgType == Constants.L1_FUND_TRANSFER_REPORT, "WR: bad msg type");
        vault.bridgeEscrow().clearFunds(amount, "");
    }

    /// @notice Receive `message` with L1Vault's tvl data.
    function receiveTVL(bytes calldata message) external {
        (IWormhole.VM memory vm, bool valid, string memory reason) = wormhole.parseAndVerifyVM(message);
        require(valid, reason);
        _validateWormholeMessageEmitter(vm);
        nextValidNonce = vm.nonce + 1;
        (bytes32 msgType, uint256 tvl, bool received) = abi.decode(vm.payload, (bytes32, uint256, bool));
        require(msgType == Constants.L1_TVL, "WR: bad msg type");
        L2Vault(address(vault)).receiveTVL(tvl, received);
    }
}

// SPDX-License-Identifier:MIT
pragma solidity =0.8.16;

import {IWormhole} from "src/interfaces/IWormhole.sol";
import {BaseVault} from "src/vaults/cross-chain-vault/BaseVault.sol";
import {AffineGovernable} from "src/utils/AffineGovernable.sol";

abstract contract WormholeRouter is AffineGovernable {
    /// @notice The vault that sends/receives messages.
    BaseVault public immutable vault;

    constructor(BaseVault _vault, IWormhole _wormhole) {
        vault = _vault;
        governance = vault.governance();
        wormhole = _wormhole;
    }
    /*//////////////////////////////////////////////////////////////
                         WORMHOLE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The address of the core wormhole contract.
    IWormhole public immutable wormhole;
    /**
     * @notice The number of blocks it takes to emit produce the VAA.
     * See https://book.wormholenetwork.com/wormhole/4_vaa.html
     * @dev This consistency level is actually being ignored on Polygon as of August 16, 2022. The minimum number of blocks
     * is actually hardcoded to 512. See https://github.com/certusone/wormhole/blob/9ba75ddb97162839e0cacd91851a9a0ef9b45496/node/cmd/guardiand/node.go#L969-L981
     */
    uint8 public consistencyLevel = 4;

    ///@notice Set the number of blocks needed for wormhole guardians to produce VAA
    function setConsistencyLevel(uint8 _consistencyLevel) external onlyGovernance {
        consistencyLevel = _consistencyLevel;
    }

    /*//////////////////////////////////////////////////////////////
                             WORMHOLE STATE
    //////////////////////////////////////////////////////////////*/

    function otherLayerWormholeId() public view virtual returns (uint16) {}

    uint256 public nextValidNonce;

    /*//////////////////////////////////////////////////////////////
                               VALIDATION
    //////////////////////////////////////////////////////////////*/

    function _validateWormholeMessageEmitter(IWormhole.VM memory vm) internal view {
        require(vm.emitterAddress == bytes32(uint256(uint160(address(this)))), "WR: bad emitter address");
        require(vm.emitterChainId == otherLayerWormholeId(), "WR: bad emitter chain");
        require(vm.nonce >= nextValidNonce, "WR: old transaction");
    }
}