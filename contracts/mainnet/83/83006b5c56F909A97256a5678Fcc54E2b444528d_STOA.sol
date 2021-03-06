// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IStoaToken.sol";
import "./interfaces/ISTOA.sol";

/// @title STOA guiding you on the path to sageness
/// @author bitbeckers
/// @notice MVP release
/// @custom:experimental This is an experimental contract.
contract STOA is ReentrancyGuard, ISTOA, AccessControl {
    bytes32 public constant REWARDER_ROLE = keccak256("REWARDER_ROLE");
    bytes32 public constant CONFIG_ROLE = keccak256("CONFIG_ROLE");

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 private genesis;

    /// @notice Address of STOA token
    address public token;

    /// @notice Address of Rewarder contract
    /// @dev The rewarder informs STOA that rewards are paid
    address public rewarder;

    /// @notice Address of the treasury
    /// @dev Funded with unused rewards funds and token swapping fees
    address public treasury;

    /// @notice Mapping to get User profile based on address
    mapping(address => User) public users;

    /// @notice Mapping storing season related user metrics based on address and periodIndex
    mapping(address => mapping(uint256 => UserSeason)) public userSeasons;

    /// @notice Keeps track of the past periods. When season is updated, current season is added to mapping
    mapping(uint256 => Period) public periodHistory;

    uint256[4] public rewardRates;
    uint256[10] public yearRates;
    uint256[4] public quarterRates;
    uint256 public periodDuration;

    Period public currentPeriod;

    struct UserSeason {
        uint256 secondsMeditated;
        uint256 accomplishmentLevel;
        Meditation[] meditations;
    }

    struct Period {
        uint256 index;
        uint256 start;
        uint256 end;
        uint256 totalSupply;
        uint256 rewardsPaid;
        uint256 baseRate;
        uint256 stakeRate;
        uint256 commitmentRewards;
        uint256 accomplishmentRewards;
        Counters.Counter bronze;
        Counters.Counter silver;
        Counters.Counter gold;
        Counters.Counter userCount;
    }

    /// @notice Creates the STOA instance, stores user performance and period/reward settings
    /// @param _owner The owner of STOA
    /// @param _stoaToken Address of the STOA ERC20 used for staking and rewards
    constructor(
        address _owner,
        address _stoaToken,
        address _treasuryAddress,
        uint256[10] memory _yearRates,
        uint256[4] memory _quarterRates,
        uint256[4] memory _rewardRates,
        uint256 _periodDuration
    ) {
        token = _stoaToken;
        treasury = _treasuryAddress;
        periodDuration = _periodDuration * 1 days;
        yearRates = _yearRates;
        quarterRates = _quarterRates;
        rewardRates = _rewardRates;
        genesis = block.timestamp;
        uint256 rewardsForNextPeriod = _calculateRewardForPeriod();
        Counters.Counter memory bronze;
        Counters.Counter memory silver;
        Counters.Counter memory gold;
        currentPeriod = Period({
            index: 1,
            start: block.timestamp,
            end: block.timestamp + periodDuration,
            totalSupply: rewardsForNextPeriod, //TODO no hardcoded magic number
            rewardsPaid: 0,
            baseRate: _calculateRewardsRateForPeriod(rewardsForNextPeriod, rewardRates[0], periodDuration),
            stakeRate: _calculateRewardsRateForPeriod(rewardsForNextPeriod, rewardRates[1], periodDuration),
            accomplishmentRewards: rewardsForNextPeriod.mul(rewardRates[2]).div(1e18),
            commitmentRewards: rewardsForNextPeriod.mul(rewardRates[3]).div(1e18),
            bronze: bronze,
            silver: silver,
            gold: gold,
            userCount: currentPeriod.userCount
        });
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    // Events
    /// @notice Emitted when user is created
    event UserCreated(uint256 userCount);

    /// @notice Emitted when user is deleted
    event UserDeleted(uint256 userCount);

    /// @notice Emitted when a (new) user stores a meditation session
    /// @dev Duration is in seconds, season equals currentPeriod.periodIndex
    event MeditationStored(address user, uint256 duration, uint256 season);

    /// @notice Emitted when an user achieves a milestone marked by time meditated
    /// @dev Level 1 == Bronze
    /// @dev Level 2 == Silver
    /// @dev Level 3 == Gold
    event AccomplishmentAchieved(address user, uint256 level, uint256 season);

    /// @notice Emitted when a new period is created.
    /// @dev Updated currentPeriod.
    /// @dev Pushes previous currentperiod to periodHistory[].
    event PeriodUpdated(uint256 periodCounter, uint256 start, uint256 end);

    /// @notice Emitted when reward rates are updated
    /// @dev Check whether rates sum to 1
    /// @dev Rates are expressed in 1e18
    event RewardRatesUpdated(uint256[4] newRates);

    // Views
    // External
    /// @notice Returns the user for the given address.
    /// @dev Will return a default object when user does not exist.
    /// @dev check on user/exists.
    function getUser(address account) external view returns (User memory) {
        return users[account];
    }

    /// @notice Returns the duration and timestamp of the lates meditation
    /// @dev Require user to have a meditation in given period
    /// @dev Duration expressed in seconds
    function getMeditation(
        address user,
        uint256 periodIndex,
        uint256 index
    ) external view isUser(user) returns (uint256 duration, uint256 timestamp) {
        require(userSeasons[user][periodIndex].meditations.length >= index, "Meditation not found");
        Meditation storage meditation = userSeasons[user][periodIndex].meditations[index];
        return (meditation.duration, meditation.timestamp);
    }

    /// @notice Returns the total available rewards given the current period
    /// @dev See _calculateRewardForPeriod();
    function getRewardForPeriod() external view returns (uint256 totalRewards) {
        return _calculateRewardForPeriod();
    }

    /// @notice Returns index for current period.
    /// @dev Periods are indexed starting with 1
    function getPeriodIndex() external view returns (uint256 currentIndex) {
        return currentPeriod.index;
    }

    /// @notice Stores meditation session for (a) user.
    /// @notice If user does not exists, create user.
    /// @notice If period has ended, update period.
    /// @notice If accomplishment achieved, update accomplishmentLevel
    function storeMeditation(uint256 _duration) external meditationWithinLimits(_duration) updatePeriod {
        // Store meditation and create user if necessary
        User storage user = users[msg.sender];
        if (!user.exists) {
            users[msg.sender] = User(
                block.timestamp,
                false,
                _duration,
                block.timestamp,
                block.timestamp,
                block.timestamp,
                true
            );
            currentPeriod.userCount.increment();
            emit UserCreated(currentPeriod.userCount.current());
        } else {
            user.totalMeditation += _duration;
            user.lastMeditated = block.timestamp;
        }
        UserSeason storage season = userSeasons[msg.sender][currentPeriod.index];
        season.secondsMeditated += _duration;
        season.meditations.push(Meditation({ timestamp: block.timestamp, duration: _duration }));

        // Update accomplishment level
        uint256 accomplishment = getAccomplishmentLevel(season.secondsMeditated);
        if (accomplishment != season.accomplishmentLevel) {
            _updateAccomplishmentLevel(accomplishment);
        }

        emit MeditationStored(msg.sender, _duration, currentPeriod.index);
    }

    /// @notice Returns user count for given period
    function getUserCount(uint256 periodIndex) external view returns (uint256 count) {
        if (periodIndex == currentPeriod.index) {
            return currentPeriod.userCount.current();
        }
        return periodHistory[periodIndex].userCount.current();
    }

    /// @notice Returns duration and timestamp for latest meditation
    /// @dev Returns 0, 0 if user has not meditated
    function getLatestMeditation(address user, uint256 periodIndex)
        external
        view
        returns (uint256 duration, uint256 timestamp)
    {
        UserSeason storage season = userSeasons[user][periodIndex];
        uint256 count = season.meditations.length;
        if (count == 0) {
            return (0, 0);
        }
        Meditation storage meditation = season.meditations[season.meditations.length - 1];
        return (meditation.duration, meditation.timestamp);
    }

    /// @notice Returns total meditation time for given period
    function getSecondsMeditatedForPeriod(address user, uint256 periodIndex)
        external
        view
        isUser(user)
        returns (uint256 secondsForPeriod)
    {
        secondsForPeriod = userSeasons[user][periodIndex].secondsMeditated;
    }

    /// @notice Returns accomplishement level as 0, 1, 2, 3 for none, bronze, silver, gold
    /// @dev Thresholds hardcoded in contract
    function getAccomplishmentLevel(address user, uint256 periodIndex)
        public
        view
        isUser(user)
        returns (uint256 accomplishmentLevel)
    {
        accomplishmentLevel = getAccomplishmentLevel(userSeasons[user][periodIndex].secondsMeditated);
    }

    /// @notice Returns accomplishment level for given time meditated
    function getAccomplishmentLevel(uint256 secondsMeditated) public pure returns (uint256 accomplishmentLevel) {
        if (secondsMeditated >= 3000 * 60) {
            return accomplishmentLevel = 3;
        }
        if (secondsMeditated >= 1800 * 60) {
            return accomplishmentLevel = 2;
        }
        if (secondsMeditated >= 600 * 60) {
            return accomplishmentLevel = 1;
        }
        return accomplishmentLevel = 0;
    }

    /// @notice Returns counter for bronze, silver, gold accomplishments
    /// @notice Accomplishments reset each period
    function getAccomplishments(uint256 periodIndex)
        external
        view
        returns (
            uint256 bronze,
            uint256 silver,
            uint256 gold
        )
    {
        if (periodIndex == currentPeriod.index) {
            return (currentPeriod.bronze.current(), currentPeriod.silver.current(), currentPeriod.gold.current());
        } else {
            Period storage period = periodHistory[periodIndex];
            return (period.bronze.current(), period.silver.current(), period.gold.current());
        }
    }

    /// @notice Returns timestamp in seconds when user last claimed
    function getLastClaimed(address account) external view isUser(account) returns (uint256 timestamp) {
        timestamp = users[account].lastClaimed;
    }

    /// @notice Get period duration set for next period and period calculation
    function getPeriodDuration() external view returns (uint256 durationInSeconds) {
        durationInSeconds = periodDuration;
    }

    /// @notice Returns timestamp for end of period
    function getPeriodEnd() external view returns (uint256 timestamp) {
        timestamp = currentPeriod.end;
    }

    // Rates
    function getBaseRate() external view returns (uint256 baseRate) {
        baseRate = rewardRates[0];
    }

    function getStakingRate() external view returns (uint256 stakingRate) {
        stakingRate = rewardRates[1];
    }

    function getCommitmentRate() external view returns (uint256 commitmentRate) {
        commitmentRate = rewardRates[2];
    }

    function getAccomplishmentRate() external view returns (uint256 accomplishmentRate) {
        accomplishmentRate = rewardRates[3];
    }

    /// @notice Registers paid reward
    /// @dev Callable by rewarder contract when paying staking or accomplishment rewards
    function notifyRewardsPaid(
        address user,
        uint256 amount,
        uint256 periodIndex
    ) external nonReentrant onlyRole(REWARDER_ROLE) {
        User storage _user = users[user];
        _user.rewardsPaid += amount;
        _user.lastClaimed = block.timestamp;

        periodHistory[periodIndex].rewardsPaid += amount;
        if (block.timestamp >= currentPeriod.end) {
            _updatePeriodExpires();
        }
    }

    // Public
    /// @notice Creates a new user based on address
    /// @dev Reverts if user already exists
    function createUser() public {
        require(!_isUser(msg.sender), "User already exists");
        users[msg.sender] = User(block.timestamp, false, 0, block.timestamp, 0, 0, true);
        currentPeriod.userCount.increment();
        emit UserCreated(currentPeriod.userCount.current());
    }

    /// @notice Deletes user from mapping
    function deleteUser() public isUser(msg.sender) {
        delete users[msg.sender];
        currentPeriod.userCount.decrement();
        emit UserDeleted(currentPeriod.userCount.current());
    }

    // Amounts
    function getBaseRewardRateForPeriod(uint256 periodIndex)
        external
        view
        periodExists(periodIndex)
        returns (uint256 rewardRate)
    {
        if (periodIndex == currentPeriod.index) {
            return currentPeriod.baseRate;
        }
        return periodHistory[periodIndex].baseRate;
    }

    function getStakingRewardRateForPeriod(uint256 periodIndex)
        external
        view
        periodExists(periodIndex)
        returns (uint256 rewardRate)
    {
        if (periodIndex == currentPeriod.index) {
            return currentPeriod.stakeRate;
        }
        return periodHistory[periodIndex].stakeRate;
    }

    function getAccomplishmentRewardsForPeriod(uint256 periodIndex)
        external
        view
        periodExists(periodIndex)
        returns (uint256 rewardAmount)
    {
        if (periodIndex == currentPeriod.index) {
            return currentPeriod.accomplishmentRewards;
        }
        return periodHistory[periodIndex].accomplishmentRewards;
    }

    function getCommitmentRewardsForPeriod(uint256 periodIndex)
        external
        view
        periodExists(periodIndex)
        returns (uint256 rewardAmount)
    {
        if (periodIndex == currentPeriod.index) {
            return currentPeriod.commitmentRewards;
        }
        return periodHistory[periodIndex].commitmentRewards;
    }

    // Internal
    function _isUser(address userAddress) internal view returns (bool isIndeed) {
        return users[userAddress].exists;
    }

    //TODO update leftover reward accounting
    function _updatePeriodExpires() internal {
        periodHistory[currentPeriod.index] = currentPeriod;
        if (currentPeriod.index > 40) {
            return;
        }
        uint256 leftoverAccomplishmentRewards = _calculateLeftoverAccomplishmentRewards();
        uint256 rewardsForNextPeriod = _calculateRewardForPeriod();
        Counters.Counter memory bronze;
        Counters.Counter memory silver;
        Counters.Counter memory gold;
        Period memory newPeriod = Period({
            index: currentPeriod.index + 1,
            start: currentPeriod.end,
            end: currentPeriod.end + periodDuration,
            totalSupply: rewardsForNextPeriod,
            rewardsPaid: 0,
            baseRate: _calculateRewardsRateForPeriod(rewardsForNextPeriod, rewardRates[0], periodDuration),
            stakeRate: _calculateRewardsRateForPeriod(rewardsForNextPeriod, rewardRates[1], periodDuration),
            accomplishmentRewards: rewardsForNextPeriod.mul(rewardRates[2]).div(1e18),
            commitmentRewards: rewardsForNextPeriod.mul(rewardRates[3]).div(1e18),
            bronze: bronze,
            silver: silver,
            gold: gold,
            userCount: currentPeriod.userCount
        });
        currentPeriod = newPeriod;

        _token().mintReward(_treasury(), leftoverAccomplishmentRewards.div(10));

        emit PeriodUpdated(currentPeriod.index, currentPeriod.start, currentPeriod.end);
    }

    function _updateAccomplishmentLevel(uint256 level) internal {
        UserSeason storage season = userSeasons[msg.sender][currentPeriod.index];
        uint256 oldLvl = season.accomplishmentLevel;
        if (level == 1) {
            currentPeriod.bronze.increment();
            season.accomplishmentLevel = 1;
        }
        if (level == 2) {
            currentPeriod.silver.increment();
            season.accomplishmentLevel = 2;
        }
        if (level == 3) {
            currentPeriod.gold.increment();
            season.accomplishmentLevel = 3;
        }

        if (oldLvl == 1) {
            currentPeriod.bronze.decrement();
        }
        if (oldLvl == 2) {
            currentPeriod.silver.decrement();
        }
        if (oldLvl == 3) {
            currentPeriod.gold.decrement();
        }
        emit AccomplishmentAchieved(msg.sender, level, currentPeriod.index);
    }

    function _getYearIndex() internal view returns (uint256 yearIndex) {
        return (block.timestamp - genesis).div(90 days * 4);
    }

    function _getQuarterIndex() internal view returns (uint256 quarterIndex) {
        return (block.timestamp - genesis).div(periodDuration).mod(4);
    }

    function _calculateRewardForPeriod() internal view returns (uint256 rewardForPeriod) {
        uint256 rewardForYear = _token().getRewardCap().mul(yearRates[_getYearIndex()]).div(1e18);

        rewardForPeriod = rewardForYear.mul(quarterRates[_getQuarterIndex()]).div(1e18);
    }

    function _calculateRewardsRateForPeriod(
        uint256 rewardForPeriod,
        uint256 rewardRatio,
        uint256 _periodDuration
    ) internal pure returns (uint256 rewardRate) {
        return rewardForPeriod.mul(rewardRatio).div(1e18).div(_periodDuration);
    }

    function _calculateLeftoverAccomplishmentRewards() internal view returns (uint256 leftoverRewards) {
        uint256 leftoverBronze = currentPeriod.bronze.current() > 0
            ? 0
            : currentPeriod.accomplishmentRewards.mul(15).div(100);
        uint256 leftoverSilver = currentPeriod.silver.current() > 0
            ? 0
            : currentPeriod.accomplishmentRewards.mul(30).div(100);
        uint256 leftoverGold = currentPeriod.gold.current() > 0
            ? 0
            : currentPeriod.accomplishmentRewards.mul(55).div(100);
        leftoverRewards = leftoverBronze + leftoverSilver + leftoverGold;
    }

    function _meditationsDuringLastDay() internal view returns (uint256 meditationDuration) {
        uint256 cutOff = block.timestamp - 1 days;
        meditationDuration = 0;
        Meditation[] storage meditationsForSeason = userSeasons[msg.sender][currentPeriod.index].meditations;
        if (meditationsForSeason.length == 0) {
            return meditationDuration;
        }

        for (uint256 i = meditationsForSeason.length; i > 1; --i) {
            Meditation storage meditation = meditationsForSeason[i - 1];
            if (meditation.timestamp >= cutOff) {
                meditationDuration += meditation.duration;
            }
        }

        return meditationDuration;
    }

    function getPeriodsSince(uint256 timestamp) public view returns (uint256 periodCount) {
        uint256 diff = block.timestamp - timestamp;
        periodCount = (diff / periodDuration);
    }

    // Config
    function setRewardRates(uint256[4] calldata _rewardRates) external onlyRole(CONFIG_ROLE) {
        require(
            _rewardRates[0] + _rewardRates[1] + _rewardRates[2] + _rewardRates[3] == 1 * 1e18,
            "Rates not matching to 1"
        );
        rewardRates = _rewardRates;
        emit RewardRatesUpdated(rewardRates);
    }

    // Modifiers
    modifier isUser(address account) {
        require(_isUser(account), "User does not exist");
        _;
    }

    modifier periodExists(uint256 periodIndex) {
        require(periodIndex <= currentPeriod.index, "Period out of range");
        _;
    }

    modifier updatePeriod() {
        if (block.timestamp >= currentPeriod.end) {
            _updatePeriodExpires();
        }
        _;
    }

    modifier meditationWithinLimits(uint256 duration) {
        require(_meditationsDuringLastDay() < 4 hours, "Daily meditation limit has been reached.");
        require(duration == 300 || duration == 600 || duration == 900, "Invalid meditation period duration");
        _;
    }

    // System
    function _token() internal view returns (IStoaToken) {
        return IStoaToken(token);
    }

    function _treasury() internal view returns (address) {
        return treasury;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISTOA {
    struct User {
        uint256 created;
        bool sagePath;
        uint256 totalMeditation;
        uint256 lastClaimed;
        uint256 lastMeditated;
        uint256 rewardsPaid;
        bool exists;
    }

    struct Meditation {
        uint256 timestamp;
        uint256 duration;
    }

    // User
    function createUser() external;

    function deleteUser() external;

    function storeMeditation(uint256 _duration) external;

    function getUser(address account) external view returns (User memory);

    function getMeditation(
        address user,
        uint256 periodIndex,
        uint256 index
    ) external view returns (uint256 duration, uint256 timestamp);

    function getLatestMeditation(address user, uint256 periodIndex)
        external
        view
        returns (uint256 duration, uint256 timestamp);

    function getRewardForPeriod() external view returns (uint256 totalRewards);

    function getUserCount(uint256 periodIndex) external view returns (uint256 count);

    function getSecondsMeditatedForPeriod(address user, uint256 periodIndex) external view returns (uint256);

    function getAccomplishmentLevel(address user, uint256 minutesMeditated) external view returns (uint256);

    function getAccomplishments(uint256 periodIndex)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getLastClaimed(address account) external view returns (uint256 timestamp);

    //Periods
    function getPeriodDuration() external view returns (uint256 durationInSeconds);

    function getPeriodEnd() external view returns (uint256 timestamp);

    function getPeriodIndex() external view returns (uint256 index);

    function getPeriodsSince(uint256 timestamp) external view returns (uint256 periodCount);

    // Rates
    function getBaseRate() external view returns (uint256 baseRate);

    function getStakingRate() external view returns (uint256 stakingRate);

    function getAccomplishmentRate() external view returns (uint256 getAccomplishmentRate);

    function getCommitmentRate() external view returns (uint256 commitmentRate);

    function notifyRewardsPaid(
        address user,
        uint256 amount,
        uint256 periodIndex
    ) external;

    // Amounts
    function getBaseRewardRateForPeriod(uint256 periodIndex) external view returns (uint256 rewardRate);

    function getStakingRewardRateForPeriod(uint256 periodIndex) external view returns (uint256 rewardRate);

    function getAccomplishmentRewardsForPeriod(uint256 periodIndex) external view returns (uint256 rewardAmount);

    function getCommitmentRewardsForPeriod(uint256 periodIndex) external view returns (uint256 rewardAmount);

    // function getSecondsMeditatedSince(address user, uint256 timestamp) external view returns (uint256 sumDuration);

    // Config
    function setRewardRates(uint256[4] memory _rewardRates) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IStoaToken {
    function getTotalCap() external view returns (uint256);

    function getRewardCap() external view returns (uint256);

    function getRewardMinted() external view returns (uint256);

    function mintReward(address account, uint256 rewardAmount) external;

    function mint(address account, uint256 amount) external;
}