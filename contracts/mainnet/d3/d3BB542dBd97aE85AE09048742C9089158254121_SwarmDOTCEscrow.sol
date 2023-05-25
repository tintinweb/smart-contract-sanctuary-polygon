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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "../structures/dOTCManagerStruct.sol";

/**
 * @title Interface for dOTCManager
 * @author Swarm
 */
interface IdOTC {
    /**
     * @dev Returns the address of the maker
     *
     * @param offerId uint256 the Id of the order
     *
     * @return maker address
     * @return cpk address
     */
    function getOfferOwner(uint256 offerId) external view returns (address maker, address cpk);

    /**
     * @dev Returns the dOTCOffer Struct of the offerId
     *
     * @param offerId uint256 the Id of the offer
     *
     * @return offer dOTCOffer
     */
    function getOffer(uint256 offerId) external view returns (dOTCOffer memory offer);

    /**
     * @dev Returns the address of the taker
     *
     * @param orderId uint256 the id of the order
     *
     * @return taker address
     */
    function getTaker(uint256 orderId) external view returns (address taker);

    /**
     * @dev Returns the Order Struct of the oreder_id
     *
     * @param orderId uint256
     *
     * @return order Order
     */
    function getTakerOrders(uint256 orderId) external view returns (Order memory order);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title Interface for Escrow
 * @author Swarm
 */
interface IEscrow {
    /**
     * @dev Sets initial the deposit of the maker.
     *
     * Requirements:
     * - sender must be assinged ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     * - escrow must not be frozen
     *
     * @param _offerId uint256 the offer ID
     */
    function setMakerDeposit(uint256 _offerId) external;

    /**
     * @dev Withdraws deposit from the Escrow to to the taker address
     *
     * Requirements:
     * - sender must be assinged ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     * - escrow must not be frozen
     *
     * @param offerId the Id of the offer
     * @param orderId the order id
     *
     * @return bool
     */
    function withdrawDeposit(uint256 offerId, uint256 orderId) external returns (bool);

    /**
     * @dev Makes the escrow smart contract unactive
     *
     *   Requirements:
     *   - sender must be assinged  ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     *
     * @param _account address that froze the escrow
     *
     * @return status bool
     */
    function freezeEscrow(address _account) external returns (bool);

    /**
     * @dev Sets dOTC Address
     *
     *   Requirements:
     *   - sender must be assinged  ESCROW_MANAGER_ROLE
     *   - `_dOTC` != 0
     *
     * @param _dOTC dOTC address
     *
     * @return status bool
     */
    function setdOTCAddress(address _dOTC) external returns (bool);

    /**
     * @dev Freezes a singular offer on the escrow smart contract
     *
     *   Requirements:
     *   - sender must be assinged  ESCROW_MANAGER_ROLE
     *
     * @param offerId uint256
     * @param frozenBy address
     *
     * @return status bool
     */
    function freezeOneDeposit(uint256 offerId, address frozenBy) external returns (bool);

    /**
     * @dev Unfreezes a singular offer on the escrow smart contract
     *
     *   Requirements:
     *   - sender must be assinged  ESCROW_MANAGER_ROLE
     *
     * @param offerId uint256
     * @param unFrozenBy address
     *
     * @return status bool
     */
    function unFreezeOneDeposit(uint256 offerId, address unFrozenBy) external returns (bool);

    /**
     * @dev Sets the escrow to active
     *
     *   Requirments:
     *   - sender must be assinged ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     *
     * @param _account address that unfroze the escrow
     *
     * @return status bool
     */
    function unFreezeEscrow(address _account) external returns (bool status);

    /**
     * @dev Cancels deposit to escrow
     *
     * Requirements:
     * - sender must be assinged ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     *
     * @param offerId the Id of the offer
     * @param token the token from deposit
     * @param makerCpk maker's CPK address
     * @param _amountToSend the amount to send
     *
     * @return status bool
     */
    function cancelDeposit(
        uint256 offerId,
        IERC20Metadata token,
        address makerCpk,
        uint256 _amountToSend
    ) external returns (bool status);

    /**
     * @dev Returns the funds from the escrow to the maker
     *
     *   Requirements:
     *   Sender must be assinged  ESCROW_MANAGER_ROLE
     *
     * @param offerId uint256
     * @param account address
     * @param removedBy address
     *
     * @return status bool
     */
    function removeOffer(uint256 offerId, address account, address removedBy) external returns (bool status);
}

// solhint-disable
//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "./OfferType.sol";

/**
 * @dev dOTC Offer stucture
 * @author Swarm
 */
struct dOTCOffer {
    address maker;
    address cpk;
    uint256 offerId;
    bool fullyTaken;
    address[2] tokenInTokenOut; // Tokens to exchange
    uint256[2] amountInAmountOut; // Amount of tokens
    uint256 availableAmount; // available amount
    uint256 unitPrice;
    OfferType offerType; // can be PARTIAL or FULL
    address specialAddress; // makes the offer avaiable for one account.
    uint256 expiryTime;
    uint256 timelockPeriod;
}

/**
 * @dev dOTC Order stucture
 * @author Swarm
 */
struct Order {
    uint256 offerId;
    uint256 amountToSend; // the amount the taker sends to the maker
    address takerAddress;
    uint256 amountToReceive;
    uint256 minExpectedAmount; // the amount the taker is to recieve
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @dev dOTC Order stucture
 * @author Swarm
 */
struct OfferDeposit {
    uint256 offerId;
    address maker;
    uint256 amountDeposited;
    bool isFrozen;
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

/**
 * @dev Offer enum
 * @author Swarm
 */
enum OfferType {
    PARTIAL,
    FULL
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IEscrow.sol";
import "./interfaces/IdOTC.sol";
import "./structures/EscrowDepositStructures.sol";

/**
 * @title Escrow contract
 * @author Swarm
 */
contract SwarmDOTCEscrow is ERC1155Holder, AccessControl, IEscrow {
    ///@dev Freeze escrow
    /**
     * @dev Emmited when escrow frozen
     */
    event EscrowFrozen(address indexed frozenBy, address calledBy);
    /**
     * @dev Emmited when escrow unfrozen
     */
    event UnFreezeEscrow(address indexed unFreezeBy, address calledBy);

    ///@dev Offer escrow
    /**
     * @dev Emmited when offer frozen
     */
    event OfferFrozen(uint256 indexed offerId, address indexed offerOwner, address frozenBy);
    /**
     * @dev Emmited when offer unfrozen
     */
    event OfferUnfrozen(uint256 indexed offerId, address indexed offerOwner, address frozenBy);

    ///@dev Offer actions
    /**
     * @dev Emmited when offer removed
     */
    event OfferRemove(uint256 indexed offerId, address indexed offerOwner, uint256 amountReverted, address removedBy);
    /**
     * @dev Emmited when offer withdrawn
     */
    event OfferWithdrawn(uint256 indexed offerId, uint256 indexed orderId, address indexed taker, uint256 amount);
    /**
     * @dev Emmited when offer cancelled
     */
    event OfferCancelled(
        uint256 indexed offerId,
        IERC20Metadata indexed token,
        address indexed maker,
        uint256 _amountToSend
    );

    /**
     * @dev ESCROW_MANAGER_ROLE hashed string
     */
    bytes32 public constant ESCROW_MANAGER_ROLE = keccak256("ESCROW_MANAGER_ROLE");
    /**
     * @dev BPSNUMBER used to standardize decimals
     */
    uint256 public constant BPSNUMBER = 10 ** 27;
    /**
     * @dev This  determine is the escrow is frozen
     */
    bool public isFrozen;

    // Private variables
    address internal dOTC;
    mapping(uint256 => OfferDeposit) private deposits;

    ///@dev Escrow need to be not frozen
    modifier escrowNotFrozen() {
        require(!isFrozen, "Escrow: escrow is Frozen");
        _;
    }

    ///@dev Only ESCROW_MANAGER_ROLE can call function with this modifier
    modifier onlyEscrowManager() {
        require(hasRole(ESCROW_MANAGER_ROLE, _msgSender()), "Escrow: must have escrow manager role");
        _;
    }

    ///@dev Offer need to be not frozen
    modifier depositNotFrozen(uint256 offerId) {
        require(!deposits[offerId].isFrozen, "Escrow: offer is frozen");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Grants ESCROW_MANAGER_ROLE to `_escrowManager`
     *
     * Requirements:
     * - the caller must have ``role``'s admin role
     */
    function setEscrowManager(address _escrowManager) public {
        grantRole(ESCROW_MANAGER_ROLE, _escrowManager);
    }

    /**
     * @dev Sets initial the deposit of the maker.
     *
     * Requirements:
     * - sender must be assinged ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     * - escrow must not be frozen
     *
     * @param _offerId uint256 the offer ID
     */
    function setMakerDeposit(uint256 _offerId) external onlyEscrowManager escrowNotFrozen {
        (, address cpk) = IdOTC(dOTC).getOfferOwner(_offerId);
        deposits[_offerId] = OfferDeposit(_offerId, cpk, IdOTC(dOTC).getOffer(_offerId).amountInAmountOut[0], false);
    }

    /**
     * @dev Withdraws deposit from the Escrow to to the taker address
     *
     * Requirements:
     * - sender must be assinged ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     * - escrow must not be frozen
     *
     * @param offerId the Id of the offer
     * @param orderId the order id
     *
     * @return bool
     */
    function withdrawDeposit(
        uint256 offerId,
        uint256 orderId
    ) external onlyEscrowManager escrowNotFrozen depositNotFrozen(offerId) returns (bool) {
        require(offerId == IdOTC(dOTC).getTakerOrders(orderId).offerId, "Escrow: offer and order ids are not correct");

        IERC20Metadata token = IERC20Metadata(IdOTC(dOTC).getOffer(offerId).tokenInTokenOut[0]);

        address _receiver = IdOTC(dOTC).getTakerOrders(orderId).takerAddress;
        uint256 standardAmount = IdOTC(dOTC).getTakerOrders(orderId).amountToReceive;
        uint256 minExpectedAmount = IdOTC(dOTC).getTakerOrders(orderId).minExpectedAmount;
        uint256 amount = unstandardisedNumber(standardAmount, token);
        require(amount > 0, "Escrow: Amount <= 0");

        require(
            deposits[offerId].amountDeposited >= standardAmount,
            "Escrow: Deposited amount must be >= standardAmount"
        );
        require(minExpectedAmount <= standardAmount, "Escrow: minExpectedAmount must be <= standardAmount");

        deposits[offerId].amountDeposited -= standardAmount;

        safeInternalTransfer(token, _receiver, amount);

        emit OfferWithdrawn(offerId, orderId, _receiver, amount);

        return true;
    }

    /**
     * @dev Cancels deposit to escrow
     *
     * Requirements:
     * - sender must be assinged ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     *
     * @param offerId the Id of the offer
     * @param token the token from deposit
     * @param makerCpk maker's CPK address
     * @param _amountToSend the amount to send
     *
     * @return status bool
     */
    function cancelDeposit(
        uint256 offerId,
        IERC20Metadata token,
        address makerCpk,
        uint256 _amountToSend
    ) external onlyEscrowManager returns (bool status) {
        require(makerCpk != address(0) && address(token) != address(0), "Escrow: Passed zero addresses");

        deposits[offerId].amountDeposited = 0;

        safeInternalTransfer(token, msg.sender, _amountToSend);

        emit OfferCancelled(offerId, token, makerCpk, _amountToSend);

        return true;
    }

    /**
     * @dev Makes the escrow smart contract unactive
     *
     *   Requirements:
     *   - sender must be assinged  ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     *
     * @param _account address that froze the escrow
     *
     * @return status bool
     */
    function freezeEscrow(address _account) external onlyEscrowManager returns (bool status) {
        isFrozen = true;

        emit EscrowFrozen(msg.sender, _account);

        return true;
    }

    /**
     * @dev Sets the escrow to active
     *
     *   Requirments:
     *   - sender must be assinged ESCROW_MANAGER_ROLE and Also DOTC_ADMIN_ROLE
     *
     * @param _account address that unfroze the escrow
     *
     * @return status bool
     */
    function unFreezeEscrow(address _account) external onlyEscrowManager returns (bool status) {
        isFrozen = false;

        emit UnFreezeEscrow(msg.sender, _account);

        return true;
    }

    /**
     * @dev Sets dOTC Address
     *
     *   Requirements:
     *   - sender must be assinged  ESCROW_MANAGER_ROLE
     *   - `_dOTC` != 0
     *
     * @param _dOTC dOTC address
     *
     * @return status bool
     */
    function setdOTCAddress(address _dOTC) external onlyEscrowManager returns (bool status) {
        require(_dOTC != address(0), "Escrow: Passed zero address");

        dOTC = _dOTC;

        return true;
    }

    /**
     * @dev Freezes a singular offer on the escrow smart contract
     *
     *   Requirements:
     *   - sender must be assinged  ESCROW_MANAGER_ROLE
     *
     * @param offerId uint256
     * @param frozenBy address
     *
     * @return status bool
     */
    function freezeOneDeposit(uint256 offerId, address frozenBy) external onlyEscrowManager returns (bool status) {
        deposits[offerId].isFrozen = true;

        emit OfferFrozen(offerId, deposits[offerId].maker, frozenBy);

        return true;
    }

    /**
     * @dev Unfreezes a singular offer on the escrow smart contract
     *
     *   Requirements:
     *   - sender must be assinged  ESCROW_MANAGER_ROLE
     *
     * @param offerId uint256
     * @param unFrozenBy address
     *
     * @return status bool
     */
    function unFreezeOneDeposit(uint256 offerId, address unFrozenBy) external onlyEscrowManager returns (bool status) {
        deposits[offerId].isFrozen = false;

        emit OfferUnfrozen(offerId, deposits[offerId].maker, unFrozenBy);

        return true;
    }

    /**
     * @dev Returns the funds from the escrow to the maker
     *
     *   Requirements:
     *   Sender must be assinged  ESCROW_MANAGER_ROLE
     *
     * @param offerId uint256
     * @param account address
     * @param removedBy address
     *
     * @return status bool
     */
    function removeOffer(
        uint256 offerId,
        address account,
        address removedBy
    ) external onlyEscrowManager returns (bool status) {
        IERC20Metadata token = IERC20Metadata(IdOTC(dOTC).getOffer(offerId).tokenInTokenOut[0]);
        uint256 _amount = unstandardisedNumber(deposits[offerId].amountDeposited, token);

        OfferDeposit storage deposit = deposits[offerId];
        deposit.isFrozen = true;
        deposit.amountDeposited = 0;

        safeInternalTransfer(token, account, _amount);

        emit OfferRemove(offerId, deposit.maker, _amount, removedBy);

        return true;
    }

    /**
     * @dev Checks interfaces support
     * @dev AccessControl, ERC1155Receiver overrided
     *
     * @return bool
     */
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function standardiseNumber(uint256 amount, IERC20Metadata _token) internal view returns (uint256) {
        uint8 decimal = _token.decimals();
        return (amount * BPSNUMBER) / 10 ** decimal;
    }

    function unstandardisedNumber(uint256 _amount, IERC20Metadata _token) internal view returns (uint256) {
        uint8 decimal = _token.decimals();
        return (_amount * 10 ** decimal) / BPSNUMBER;
    }

    /**
     * @dev safeInternalTransfer Asset from the escrow; revert transaction if failed
     * @param token address
     * @param _receiver address
     * @param _amount uint256
     */
    function safeInternalTransfer(IERC20Metadata token, address _receiver, uint256 _amount) internal {
        require(_amount > 0, "Escrow: Amount == 0");
        require(token.transfer(_receiver, _amount), "Escrow: Transfer failed and reverted");
    }
}