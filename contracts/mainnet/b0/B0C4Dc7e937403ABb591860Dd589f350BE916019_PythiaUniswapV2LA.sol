// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

pragma experimental ABIEncoderV2;

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin-v4/contracts/utils/math/SafeCast.sol";

import "../interfaces/IAccumulator.sol";

abstract contract AbstractAccumulator is IERC165, IAccumulator {
    uint256 public immutable override changePrecision = 10**8;

    uint256 public immutable override updateThreshold;

    constructor(uint256 updateThreshold_) {
        updateThreshold = updateThreshold_;
    }

    /// @inheritdoc IAccumulator
    function updateThresholdSurpassed(address token) public view virtual override returns (bool) {
        return changeThresholdSurpassed(token, updateThreshold);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccumulator).interfaceId;
    }

    function calculateChange(uint256 a, uint256 b) internal view virtual returns (uint256 change, bool isInfinite) {
        // Ensure a is never smaller than b
        if (a < b) {
            uint256 temp = a;
            a = b;
            b = temp;
        }

        // a >= b

        if (a == 0) {
            // a == b == 0 (since a >= b), therefore no change
            return (0, false);
        } else if (b == 0) {
            // (a > 0 && b == 0) => change threshold passed
            // Zero to non-zero always returns true
            return (0, true);
        }

        unchecked {
            uint256 delta = a - b; // a >= b, therefore no underflow
            uint256 preciseDelta = delta * changePrecision;

            // If the delta is so large that multiplying by CHANGE_PRECISION overflows, we assume that
            // the change threshold has been surpassed.
            // If our assumption is incorrect, the accumulator will be extra-up-to-date, which won't
            // really break anything, but will cost more gas in keeping this accumulator updated.
            if (preciseDelta < delta) return (0, true);

            change = preciseDelta / b;
            isInfinite = false;
        }
    }

    function changeThresholdSurpassed(
        uint256 a,
        uint256 b,
        uint256 changeThreshold
    ) internal view virtual returns (bool) {
        (uint256 change, bool isInfinite) = calculateChange(a, b);

        return isInfinite || change >= changeThreshold;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

pragma experimental ABIEncoderV2;

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin-v4/contracts/utils/math/SafeCast.sol";

import "./AbstractAccumulator.sol";
import "../interfaces/ILiquidityAccumulator.sol";
import "../interfaces/ILiquidityOracle.sol";
import "../libraries/ObservationLibrary.sol";
import "../libraries/AddressLibrary.sol";
import "../utils/SimpleQuotationMetadata.sol";

abstract contract LiquidityAccumulator is
    IERC165,
    ILiquidityAccumulator,
    ILiquidityOracle,
    AbstractAccumulator,
    SimpleQuotationMetadata
{
    using AddressLibrary for address;
    using SafeCast for uint256;

    uint256 public immutable minUpdateDelay;
    uint256 public immutable maxUpdateDelay;

    mapping(address => AccumulationLibrary.LiquidityAccumulator) public accumulations;
    mapping(address => ObservationLibrary.LiquidityObservation) public observations;

    constructor(
        address quoteToken_,
        uint256 updateThreshold_,
        uint256 minUpdateDelay_,
        uint256 maxUpdateDelay_
    ) AbstractAccumulator(updateThreshold_) SimpleQuotationMetadata(quoteToken_) {
        minUpdateDelay = minUpdateDelay_;
        maxUpdateDelay = maxUpdateDelay_;
    }

    /// @inheritdoc ILiquidityAccumulator
    function calculateLiquidity(
        AccumulationLibrary.LiquidityAccumulator calldata firstAccumulation,
        AccumulationLibrary.LiquidityAccumulator calldata secondAccumulation
    ) external pure virtual override returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity) {
        require(firstAccumulation.timestamp != 0, "LiquidityAccumulator: TIMESTAMP_CANNOT_BE_ZERO");

        uint32 deltaTime = secondAccumulation.timestamp - firstAccumulation.timestamp;
        require(deltaTime != 0, "LiquidityAccumulator: DELTA_TIME_CANNOT_BE_ZERO");

        unchecked {
            // Underflow is desired and results in correct functionality
            tokenLiquidity =
                (secondAccumulation.cumulativeTokenLiquidity - firstAccumulation.cumulativeTokenLiquidity) /
                deltaTime;
            quoteTokenLiquidity =
                (secondAccumulation.cumulativeQuoteTokenLiquidity - firstAccumulation.cumulativeQuoteTokenLiquidity) /
                deltaTime;
        }
    }

    /// @notice Determines whether the specified change threshold has been surpassed for the specified token.
    /// @dev Calculates the change from the stored observation to the current observation.
    /// @param token The token to check.
    /// @param changeThreshold The change threshold as a percentage multiplied by the change precision
    ///   (`changePrecision`). Ex: a 1% change is respresented as 0.01 * `changePrecision`.
    /// @return surpassed True if the update threshold has been surpassed; false otherwise.
    function changeThresholdSurpassed(address token, uint256 changeThreshold)
        public
        view
        virtual
        override
        returns (bool)
    {
        (uint256 tokenLiquidity, uint256 quoteTokenLiquidity) = fetchLiquidity(token);

        ObservationLibrary.LiquidityObservation storage lastObservation = observations[token];

        return
            changeThresholdSurpassed(tokenLiquidity, lastObservation.tokenLiquidity, changeThreshold) ||
            changeThresholdSurpassed(quoteTokenLiquidity, lastObservation.quoteTokenLiquidity, changeThreshold);
    }

    /// @notice Checks if this accumulator needs an update by checking the time since the last update and the change in
    ///   liquidities.
    /// @param data The encoded address of the token for which to perform the update.
    /// @inheritdoc IUpdateable
    function needsUpdate(bytes memory data) public view virtual override returns (bool) {
        uint256 deltaTime = timeSinceLastUpdate(data);
        if (deltaTime < minUpdateDelay) {
            // Ensures updates occur at most once every minUpdateDelay (seconds)
            return false;
        } else if (deltaTime >= maxUpdateDelay) {
            // Ensures updates occur (optimistically) at least once every maxUpdateDelay (seconds)
            return true;
        }

        /*
         * maxUpdateDelay > deltaTime >= minUpdateDelay
         *
         * Check if the % change in liquidity warrants an update (saves gas vs. always updating on change)
         */
        address token = abi.decode(data, (address));

        return updateThresholdSurpassed(token);
    }

    /// @param data The encoded address of the token for which to perform the update.
    /// @inheritdoc IUpdateable
    function canUpdate(bytes memory data) public view virtual override returns (bool) {
        return needsUpdate(data);
    }

    /// @notice Updates the accumulator for a specific token.
    /// @dev Must be called by an EOA to limit the attack vector, unless it's the first observation for a token.
    /// @param data Encoding of the token address followed by the expected token liquidity and quote token liquidity.
    /// @return updated True if anything was updated; false otherwise.
    function update(bytes memory data) public virtual override returns (bool) {
        if (needsUpdate(data)) return performUpdate(data);

        return false;
    }

    /// @param data The encoded address of the token for which the update relates to.
    /// @inheritdoc IUpdateable
    function lastUpdateTime(bytes memory data) public view virtual override returns (uint256) {
        address token = abi.decode(data, (address));

        return observations[token].timestamp;
    }

    /// @param data The encoded address of the token for which the update relates to.
    /// @inheritdoc IUpdateable
    function timeSinceLastUpdate(bytes memory data) public view virtual override returns (uint256) {
        return block.timestamp - lastUpdateTime(data);
    }

    /// @inheritdoc ILiquidityAccumulator
    function getLastAccumulation(address token)
        public
        view
        virtual
        override
        returns (AccumulationLibrary.LiquidityAccumulator memory)
    {
        return accumulations[token];
    }

    /// @inheritdoc ILiquidityAccumulator
    function getCurrentAccumulation(address token)
        public
        view
        virtual
        override
        returns (AccumulationLibrary.LiquidityAccumulator memory accumulation)
    {
        ObservationLibrary.LiquidityObservation storage lastObservation = observations[token];
        require(lastObservation.timestamp != 0, "LiquidityAccumulator: UNINITIALIZED");

        accumulation = accumulations[token]; // Load last accumulation

        uint32 deltaTime = (block.timestamp - lastObservation.timestamp).toUint32();

        if (deltaTime != 0) {
            // The last observation liquidities have existed for some time, so we add that
            unchecked {
                // Overflow is desired and results in correct functionality
                // We add the liquidites multiplied by the time those liquidities were present
                accumulation.cumulativeTokenLiquidity += lastObservation.tokenLiquidity * deltaTime;
                accumulation.cumulativeQuoteTokenLiquidity += lastObservation.quoteTokenLiquidity * deltaTime;

                accumulation.timestamp = block.timestamp.toUint32();
            }
        }
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, SimpleQuotationMetadata, AbstractAccumulator)
        returns (bool)
    {
        return
            interfaceId == type(ILiquidityAccumulator).interfaceId ||
            interfaceId == type(ILiquidityOracle).interfaceId ||
            interfaceId == type(IUpdateable).interfaceId ||
            SimpleQuotationMetadata.supportsInterface(interfaceId) ||
            AbstractAccumulator.supportsInterface(interfaceId);
    }

    /// @inheritdoc ILiquidityOracle
    function consultLiquidity(address token)
        public
        view
        virtual
        override
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity)
    {
        if (token == quoteTokenAddress()) return (0, 0);

        ObservationLibrary.LiquidityObservation storage observation = observations[token];

        require(observation.timestamp != 0, "LiquidityAccumulator: MISSING_OBSERVATION");

        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    /// @param maxAge The maximum age of the quotation, in seconds. If 0, fetches the real-time liquidity.
    /// @inheritdoc ILiquidityOracle
    function consultLiquidity(address token, uint256 maxAge)
        public
        view
        virtual
        override
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity)
    {
        if (token == quoteTokenAddress()) return (0, 0);

        if (maxAge == 0) return fetchLiquidity(token);

        ObservationLibrary.LiquidityObservation storage observation = observations[token];

        require(observation.timestamp != 0, "LiquidityAccumulator: MISSING_OBSERVATION");
        require(block.timestamp <= observation.timestamp + maxAge, "LiquidityAccumulator: RATE_TOO_OLD");

        tokenLiquidity = observation.tokenLiquidity;
        quoteTokenLiquidity = observation.quoteTokenLiquidity;
    }

    function performUpdate(bytes memory data) internal virtual returns (bool) {
        address token = abi.decode(data, (address));

        (uint112 tokenLiquidity, uint112 quoteTokenLiquidity) = fetchLiquidity(token);

        // If the observation fails validation, do not update anything
        if (!validateObservation(data, tokenLiquidity, quoteTokenLiquidity)) return false;

        ObservationLibrary.LiquidityObservation storage observation = observations[token];
        AccumulationLibrary.LiquidityAccumulator storage accumulation = accumulations[token];

        if (observation.timestamp == 0) {
            /*
             * Initialize
             */
            observation.tokenLiquidity = accumulation.cumulativeTokenLiquidity = tokenLiquidity;
            observation.quoteTokenLiquidity = accumulation.cumulativeQuoteTokenLiquidity = quoteTokenLiquidity;
            observation.timestamp = accumulation.timestamp = block.timestamp.toUint32();

            emit Updated(token, tokenLiquidity, quoteTokenLiquidity, block.timestamp);

            return true;
        }

        /*
         * Update
         */

        uint32 deltaTime = (block.timestamp - observation.timestamp).toUint32();

        if (deltaTime != 0) {
            unchecked {
                // Overflow is desired and results in correct functionality
                // We add the liquidites multiplied by the time those liquidities were present
                accumulation.cumulativeTokenLiquidity += observation.tokenLiquidity * deltaTime;
                accumulation.cumulativeQuoteTokenLiquidity += observation.quoteTokenLiquidity * deltaTime;

                observation.tokenLiquidity = tokenLiquidity;
                observation.quoteTokenLiquidity = quoteTokenLiquidity;

                observation.timestamp = accumulation.timestamp = block.timestamp.toUint32();
            }

            emit Updated(token, tokenLiquidity, quoteTokenLiquidity, block.timestamp);

            return true;
        }

        return false;
    }

    /// @notice Requires the message sender of an update to not be a smart contract.
    /// @dev Can be overridden to disable this requirement.
    function validateObservationRequireEoa() internal virtual {
        // Message sender should never be a smart contract. Smart contracts can use flash attacks to manipulate data.
        require(msg.sender == tx.origin, "LiquidityAccumulator: MUST_BE_EOA");
    }

    function validateObservationAllowedChange(address) internal virtual returns (uint256) {
        // Allow the liquidity levels to change by half of the update threshold
        return updateThreshold / 2;
    }

    function validateObservation(
        bytes memory updateData,
        uint112 tokenLiquidity,
        uint112 quoteTokenLiquidity
    ) internal virtual returns (bool) {
        validateObservationRequireEoa();

        // Extract provided tokenLiquidity and quoteTokenLiquidity
        // The message sender should call consultLiquidity immediately before calling the update function, passing
        //   the returned values into the update data.
        (address token, uint112 pTokenLiquidity, uint112 pQuoteTokenLiquidity) = abi.decode(
            updateData,
            (address, uint112, uint112)
        );

        uint256 allowedChangeThreshold = validateObservationAllowedChange(token);

        // We require liquidity levels to not change by more than the threshold above
        // This check limits the ability of MEV and flashbots from manipulating data
        return
            !changeThresholdSurpassed(tokenLiquidity, pTokenLiquidity, allowedChangeThreshold) &&
            !changeThresholdSurpassed(quoteTokenLiquidity, pQuoteTokenLiquidity, allowedChangeThreshold);
    }

    function fetchLiquidity(address token)
        internal
        view
        virtual
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity);
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

pragma experimental ABIEncoderV2;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "../../LiquidityAccumulator.sol";

contract UniswapV2LiquidityAccumulator is LiquidityAccumulator {
    using AddressLibrary for address;

    address public immutable uniswapFactory;

    bytes32 public immutable initCodeHash;

    constructor(
        address uniswapFactory_,
        bytes32 initCodeHash_,
        address quoteToken_,
        uint256 updateTheshold_,
        uint256 minUpdateDelay_,
        uint256 maxUpdateDelay_
    ) LiquidityAccumulator(quoteToken_, updateTheshold_, minUpdateDelay_, maxUpdateDelay_) {
        uniswapFactory = uniswapFactory_;
        initCodeHash = initCodeHash_;
    }

    /// @inheritdoc LiquidityAccumulator
    function canUpdate(bytes memory data) public view virtual override returns (bool) {
        address token = abi.decode(data, (address));

        if (token == address(0) || token == quoteToken) {
            // Invalid token
            return false;
        }

        address pairAddress = pairFor(uniswapFactory, initCodeHash, token, quoteToken);

        if (!pairAddress.isContract()) {
            // Pool doesn't exist
            return false;
        }

        return super.canUpdate(data);
    }

    function fetchLiquidity(address token)
        internal
        view
        virtual
        override
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity)
    {
        address pairAddress = pairFor(uniswapFactory, initCodeHash, token, quoteToken);

        require(pairAddress.isContract(), "UniswapV2LiquidityAccumulator: POOL_NOT_FOUND");

        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();

        if (token < quoteToken) {
            tokenLiquidity = reserve0;
            quoteTokenLiquidity = reserve1;
        } else {
            tokenLiquidity = reserve1;
            quoteTokenLiquidity = reserve0;
        }
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        bytes32 initCodeHash_,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(hex"ff", factory, keccak256(abi.encodePacked(token0, token1)), initCodeHash_)
                    )
                )
            )
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IAccumulator
 * @notice An interface that defines an accumulator - that is, a contract that updates cumulative value(s) when the
 *   underlying value(s) change by more than the update threshold.
 */
abstract contract IAccumulator {
    /// @notice Gets the scalar (as a power of 10) to be used for calculating changes in value.
    /// @return The scalar to be used for calculating changes in value.
    function changePrecision() external view virtual returns (uint256);

    /// @notice Gets the threshold at which an update to the cumulative value(s) should be performed.
    /// @return A percentage scaled by the change precision.
    function updateThreshold() external view virtual returns (uint256);

    /// @notice Determines whether the specified change threshold has been surpassed for the specified token.
    /// @dev Calculates the change from the stored observation to the current observation.
    /// @param token The token to check.
    /// @param changeThreshold The change threshold as a percentage multiplied by the change precision
    ///   (`changePrecision`). Ex: a 1% change is respresented as 0.01 * `changePrecision`.
    /// @return surpassed True if the update threshold has been surpassed; false otherwise.
    function changeThresholdSurpassed(address token, uint256 changeThreshold) public view virtual returns (bool);

    /// @notice Determines whether the update threshold has been surpassed for the specified token.
    /// @dev Calculates the change from the stored observation to the current observation.
    /// @param token The token to check.
    /// @return surpassed True if the update threshold has been surpassed; false otherwise.
    function updateThresholdSurpassed(address token) public view virtual returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

pragma experimental ABIEncoderV2;

import "./IAccumulator.sol";

import "../libraries/AccumulationLibrary.sol";
import "../libraries/ObservationLibrary.sol";

/**
 * @title ILiquidityAccumulator
 * @notice An interface that defines a "liquidity accumulator" - that is, cumulative liquidity levels - with a
 *   single quote token and many exchange tokens.
 * @dev Liquidity accumulators are used to calculate time-weighted average liquidity levels.
 */
abstract contract ILiquidityAccumulator is IAccumulator {
    /// @notice Emitted when the accumulator is updated.
    /// @dev The accumulator's observation and cumulative values are updated when this is emitted.
    /// @param token The address of the token that the update is for.
    /// @param tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
    /// @param quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
    /// @param timestamp The epoch timestamp of the update (in seconds).
    event Updated(address indexed token, uint256 tokenLiquidity, uint256 quoteTokenLiquidity, uint256 timestamp);

    /**
     * @notice Calculates a liquidity levels from two different cumulative liquidity levels.
     * @param firstAccumulation The first cumulative liquidity levels.
     * @param secondAccumulation The last cumulative liquidity levels.
     * @dev Reverts if the timestamp of the first accumulation is 0, or if it's not strictly less than the timestamp of
     *  the second.
     * @return tokenLiquidity A time-weighted average liquidity level for a token, in wei, derived from two cumulative
     *  liquidity levels.
     * @return quoteTokenLiquidity A time-weighted average liquidity level for the quote token, in wei, derived from two
     *  cumulative liquidity levels.
     */
    function calculateLiquidity(
        AccumulationLibrary.LiquidityAccumulator calldata firstAccumulation,
        AccumulationLibrary.LiquidityAccumulator calldata secondAccumulation
    ) external pure virtual returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity);

    /// @notice Gets the last cumulative liquidity levels for the token and quote token that was stored.
    /// @param token The address of the token to get the cumulative liquidity levels for (with the quote token).
    /// @return The last cumulative liquidity levels (in wei) along with the timestamp of those levels.
    function getLastAccumulation(address token)
        public
        view
        virtual
        returns (AccumulationLibrary.LiquidityAccumulator memory);

    /// @notice Gets the current cumulative liquidity levels for the token and quote token.
    /// @param token The address of the token to get the cumulative liquidity levels for (with the quote token).
    /// @return The current cumulative liquidity levels (in wei) along with the timestamp of those levels.
    function getCurrentAccumulation(address token)
        public
        view
        virtual
        returns (AccumulationLibrary.LiquidityAccumulator memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "./IUpdateable.sol";
import "./IQuoteToken.sol";

/**
 * @title ILiquidityOracle
 * @notice An interface that defines a liquidity oracle with a single quote token (or currency) and many exchange
 *  tokens.
 */
abstract contract ILiquidityOracle is IUpdateable, IQuoteToken {
    /// @notice Gets the liquidity levels of the token and the quote token in the underlying pool.
    /// @param token The token to get liquidity levels of (along with the quote token).
    /// @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
    /// @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
    function consultLiquidity(address token)
        public
        view
        virtual
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity);

    /**
     * @notice Gets the liquidity levels of the token and the quote token in the underlying pool, reverting if the
     *  quotation is older than the maximum allowable age.
     * @param token The token to get liquidity levels of (along with the quote token).
     * @param maxAge The maximum age of the quotation, in seconds.
     * @return tokenLiquidity The amount of the token that is liquid in the underlying pool, in wei.
     * @return quoteTokenLiquidity The amount of the quote token that is liquid in the underlying pool, in wei.
     */
    function consultLiquidity(address token, uint256 maxAge)
        public
        view
        virtual
        returns (uint112 tokenLiquidity, uint112 quoteTokenLiquidity);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/**
 * @title IQuoteToken
 * @notice An interface that defines a contract containing a quote token (or currency), providing the associated
 *  metadata.
 */
abstract contract IQuoteToken {
    /// @notice Gets the quote token (or currency) name.
    /// @return The name of the quote token (or currency).
    function quoteTokenName() public view virtual returns (string memory);

    /// @notice Gets the quote token address (if any).
    /// @dev This may return address(0) if no specific quote token is used (such as an aggregate of quote tokens).
    /// @return The address of the quote token, or address(0) if no specific quote token is used.
    function quoteTokenAddress() public view virtual returns (address);

    /// @notice Gets the quote token (or currency) symbol.
    /// @return The symbol of the quote token (or currency).
    function quoteTokenSymbol() public view virtual returns (string memory);

    /// @notice Gets the number of decimal places that quote prices have.
    /// @return The number of decimals of the quote token (or currency) that quote prices have.
    function quoteTokenDecimals() public view virtual returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

/// @title IUpdateByToken
/// @notice An interface that defines a contract that is updateable as per the input data.
abstract contract IUpdateable {
    /// @notice Performs an update as per the input data.
    /// @param data Any data needed for the update.
    /// @return b True if anything was updated; false otherwise.
    function update(bytes memory data) public virtual returns (bool b);

    /// @notice Checks if an update needs to be performed.
    /// @param data Any data relating to the update.
    /// @return b True if an update needs to be performed; false otherwise.
    function needsUpdate(bytes memory data) public view virtual returns (bool b);

    /// @notice Check if an update can be performed by the caller (if needed).
    /// @dev Tries to determine if the caller can call update with a valid observation being stored.
    /// @dev This is not meant to be called by state-modifying functions.
    /// @param data Any data relating to the update.
    /// @return b True if an update can be performed by the caller; false otherwise.
    function canUpdate(bytes memory data) public view virtual returns (bool b);

    /// @notice Gets the timestamp of the last update.
    /// @param data Any data relating to the update.
    /// @return A unix timestamp.
    function lastUpdateTime(bytes memory data) public view virtual returns (uint256);

    /// @notice Gets the amount of time (in seconds) since the last update.
    /// @param data Any data relating to the update.
    /// @return Time in seconds.
    function timeSinceLastUpdate(bytes memory data) public view virtual returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

pragma experimental ABIEncoderV2;

/**
 * @notice A library for calculating and storing accumulations of time-weighted average values in the form of sumations
 *   of (value * time).
 */
library AccumulationLibrary {
    /**
     * @notice A struct for storing a snapshot of liquidity accumulations.
     * @dev The difference of a newer snapshot against an older snapshot can be used to derive time-weighted average
     *   liquidities by dividing the difference in value by the difference in time.
     */
    struct LiquidityAccumulator {
        /*
         * @notice Accumulates time-weighted average liquidity of the token in the form of a sumation of (price * time),
         *   with time measured in seconds.
         * @dev Overflow is desired and results in correct behavior as long as the difference between two snapshots
         *   is less than or equal to 2^112.
         */
        uint112 cumulativeTokenLiquidity;
        /*
         * @notice Accumulates time-weighted average liquidity of the quote token in the form of a sumation of
         *   (price * time), with time measured in seconds..
         * @dev Overflow is desired and results in correct behavior as long as the difference between two snapshots
         *   is less than or equal to 2^112.
         */
        uint112 cumulativeQuoteTokenLiquidity;
        /*
         * @notice The unix timestamp (in seconds) of the last update of (addition to) the cumulative price.
         */
        uint32 timestamp;
    }

    /**
     * @notice A struct for storing a snapshot of price accumulations.
     * @dev The difference of a newer snapshot against an older snapshot can be used to derive a time-weighted average
     *   price by dividing the difference in value by the difference in time.
     */
    struct PriceAccumulator {
        /*
         * @notice Accumulates time-weighted average prices in the form of a sumation of (price * time), with time
         *   measured in seconds.
         * @dev Overflow is desired and results in correct behavior as long as the difference between two snapshots
         *   is less than or equal to 2^112.
         */
        uint112 cumulativePrice;
        /*
         * @notice The unix timestamp (in seconds) of the last update of (addition to) the cumulative price.
         */
        uint32 timestamp;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

pragma experimental ABIEncoderV2;

library AddressLibrary {
    /**
     * @notice Determines whether an address contains code (i.e. is a smart contract).
     * @dev Use with caution: if called within a constructor, will return false.
     * @param self The address to check.
     * @return b True if the address contains code, false otherwise.
     */
    function isContract(address self) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(self)
        }
        return size > 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

pragma experimental ABIEncoderV2;

library ObservationLibrary {
    struct Observation {
        uint112 price;
        uint112 tokenLiquidity;
        uint112 quoteTokenLiquidity;
        uint32 timestamp;
    }

    struct LiquidityObservation {
        uint112 tokenLiquidity;
        uint112 quoteTokenLiquidity;
        uint32 timestamp;
    }

    struct PriceObservation {
        uint112 price;
        uint32 timestamp;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "@openzeppelin-v4/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin-v4/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../interfaces/IQuoteToken.sol";

contract SimpleQuotationMetadata is IQuoteToken, IERC165 {
    address public immutable quoteToken;

    constructor(address quoteToken_) {
        quoteToken = quoteToken_;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenName() public view virtual override returns (string memory) {
        return getStringOrBytes32(quoteToken, IERC20Metadata.name.selector);
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenAddress() public view virtual override returns (address) {
        return quoteToken;
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenSymbol() public view virtual override returns (string memory) {
        return getStringOrBytes32(quoteToken, IERC20Metadata.symbol.selector);
    }

    /// @inheritdoc IQuoteToken
    function quoteTokenDecimals() public view virtual override returns (uint8) {
        (bool success, bytes memory result) = quoteToken.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );
        if (!success) return 18; // Return 18 by default

        return abi.decode(result, (uint8));
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IQuoteToken).interfaceId;
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        // Calculate string length
        uint256 i = 0;
        while (i < 32 && _bytes32[i] != 0) ++i;

        bytes memory bytesArray = new bytes(i);

        // Extract characters
        for (i = 0; i < 32 && _bytes32[i] != 0; ++i) bytesArray[i] = _bytes32[i];

        return string(bytesArray);
    }

    function getStringOrBytes32(address contractAddress, bytes4 selector) internal view returns (string memory) {
        (bool success, bytes memory result) = contractAddress.staticcall(abi.encodeWithSelector(selector));
        if (!success) return "";

        return result.length == 32 ? bytes32ToString(bytes32(result)) : abi.decode(result, (string));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

library Roles {
    bytes32 public constant ADMIN = keccak256("ADMIN_ROLE");

    bytes32 public constant ORACLE_UPDATER = keccak256("ORACLE_UPDATER_ROLE");
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "@pythia-oracle/pythia-core/contracts/accumulators/proto/uniswap/UniswapV2LiquidityAccumulator.sol";

import "@openzeppelin-v4/contracts/access/AccessControl.sol";

import "../../../access/Roles.sol";

contract ManagedUniswapV2LiquidityAccumulator is AccessControl, UniswapV2LiquidityAccumulator {
    constructor(
        address uniswapFactory_,
        bytes32 initCodeHash_,
        address quoteToken_,
        uint256 updateTheshold_,
        uint256 minUpdateDelay_,
        uint256 maxUpdateDelay_
    )
        UniswapV2LiquidityAccumulator(
            uniswapFactory_,
            initCodeHash_,
            quoteToken_,
            updateTheshold_,
            minUpdateDelay_,
            maxUpdateDelay_
        )
    {
        initializeRoles();
    }

    /**
     * @notice Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            require(hasRole(role, msg.sender), "ManagedUniswapV2LiquidityAccumulator: MISSING_ROLE");
        }
        _;
    }

    function canUpdate(bytes memory data) public view virtual override returns (bool) {
        // Return false if the message sender is missing the required role
        if (!hasRole(Roles.ORACLE_UPDATER, address(0)) && !hasRole(Roles.ORACLE_UPDATER, msg.sender)) return false;

        return super.canUpdate(data);
    }

    function update(bytes memory data) public virtual override onlyRoleOrOpenRole(Roles.ORACLE_UPDATER) returns (bool) {
        return super.update(data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, LiquidityAccumulator)
        returns (bool)
    {
        return interfaceId == type(IAccessControl).interfaceId || LiquidityAccumulator.supportsInterface(interfaceId);
    }

    function initializeRoles() internal virtual {
        // Setup admin role, setting msg.sender as admin
        _setupRole(Roles.ADMIN, msg.sender);
        _setRoleAdmin(Roles.ADMIN, Roles.ADMIN);

        // Set admin of ORACLE_UPDATER as ADMIN
        _setRoleAdmin(Roles.ORACLE_UPDATER, Roles.ADMIN);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

contract PythiaVersioning {
    string public constant PYTHIA_CORE_VERSION = "v1.0.0-rc.8";
    string public constant PYTHIA_PERIPHERY_VERSION = "v1.0.0-rc.5";
    string public constant PYTHIA_PROTOCOL_VERSION = "v0.0.4";
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.11;

import "@pythia-oracle/pythia-periphery/contracts/accumulators/proto/uniswap/ManagedUniswapV2LiquidityAccumulator.sol";

import "../PythiaVersioning.sol";

contract PythiaUniswapV2LA is PythiaVersioning, ManagedUniswapV2LiquidityAccumulator {
    string public name;

    constructor(
        string memory name_,
        address uniswapFactory_,
        bytes32 initCodeHash_,
        address quoteToken_,
        uint256 updateTheshold_,
        uint256 minUpdateDelay_,
        uint256 maxUpdateDelay_
    )
        ManagedUniswapV2LiquidityAccumulator(
            uniswapFactory_,
            initCodeHash_,
            quoteToken_,
            updateTheshold_,
            minUpdateDelay_,
            maxUpdateDelay_
        )
    {
        name = name_;
    }
}