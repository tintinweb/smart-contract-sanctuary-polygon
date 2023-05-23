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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     *
     * Some precompiled contracts will falsely indicate support for a given interface, so caution
     * should be exercised when using this function.
     *
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "./TimedTokenSplitter.sol";
import "./interfaces/IFeeManager.sol";

/**
 * @title AltrFractionsBuyout
 * @author Lucidao Developer
 * @dev This contract allows for the buyout of fractional token sales on the Altr platform.
 */
contract AltrFractionsBuyout is AccessControl, ReentrancyGuard {
	using Counters for Counters.Counter;
	using SafeERC20 for IERC20;
	using ERC165Checker for address;

	/**
	 * @dev The struct for a buyout, containing the initiator, fraction sale ID, buyout token manager, buyout token, buyout price, opening and closing time, and success status
	 */
	struct Buyout {
		address initiator;
		uint256 fractionSaleId;
		address buyoutTokenManager;
		IERC20 buyoutToken;
		uint256 buyoutPrice;
		uint256 openingTime;
		uint256 closingTime;
		uint256 fractionsToBuyout;
		bool isSuccessful;
	}
	/**
	 * @dev BURN_MANAGER_ROLE is the role assigned to the address that can call the burn function
	 */
	bytes32 public constant BURN_MANAGER_ROLE = keccak256("BURN_MANAGER_ROLE");

	/**
	 * @dev The AltrFractions contract
	 */
	IFractions public immutable altrFractions;
	/**
	 * @dev The AltrFractionsSale contract
	 */
	IFractionsSale public immutable altrFractionsSale;

	/**
	 * @dev The minimum number of fractions required to initiate a buyout
	 */
	uint256 public buyoutMinFractions;

	/**
	 * @dev The AltrFeeManager contract.
	 */
	IFeeManager public feeManager;

	/**
	 * @dev The duration of the buyout open period in seconds
	 */
	uint256 public buyoutOpenTimePeriod;

	uint256 private constant _MIN_BUYOUT_OPEN_TIME_PERIOD = 86400; //ONE DAY

	uint256 private constant _MIN_FRACTIONS = 2000;
	uint256 private constant _MAX_FRACTIONS = 6000;
	uint256 private constant _DENOMINATOR = 10000;

	Counters.Counter private _buyoutsCounter;

	mapping(uint256 => Buyout) public buyouts;

	/**
	 * @dev Emitted when a buyout request is made
	 * @param saleId ID of the sale
	 * @param initiator Address of the buyout initiator
	 * @param buyoutId ID of the buyout
	 */
	event BuyoutRequested(uint256 indexed saleId, address indexed initiator, uint256 indexed buyoutId);
	/**
	 * @dev Emitted when the buyout parameters are set
	 * @param buyoutId ID of the buyout
	 * @param buyout Buyout struct containing the buyout parameters
	 */
	event BuyoutParamsSet(uint256 indexed buyoutId, Buyout buyout);
	/**
	 * @dev Emitted when a buyout is executed
	 * @param buyoutId ID of the buyout
	 * @param executor Address of the buyout executor
	 * @param boughtOutFractions Amount of fractions bought out
	 * @param buyoutAmount Amount paid for the buyout
	 */
	event BuyoutExecuted(
		uint256 indexed buyoutId,
		address indexed executor,
		uint256 boughtOutFractions,
		uint256 buyoutAmount,
		address Fractions,
		uint256 tokenId
	);
	/**
	 * @dev Emitted when the minimum fractions required for a buyout is set
	 * @param buyoutMinFractions The value of the minimum fractions required for a buyout
	 */
	event BuyoutMinFractionsSet(uint256 buyoutMinFractions);
	/**
	 * @dev Emitted when the time period for a buyout to be open is set
	 * @param buyoutOpenTimePeriod The time period for a buyout to be open
	 */
	event BuyoutOpenTimePeriodSet(uint256 buyoutOpenTimePeriod);
	/**
	 * @dev Emitted when the fee manager is set
	 * @param feeManager The new fee manager contract address
	 */
	event FeeManagerSet(address feeManager);

	/**
	 * @dev Rejects calls if the specified sale is not closed yet
	 * @param saleId The sale to check
	 */
	modifier onlyIfSaleClosed(uint256 saleId) {
		require(altrFractionsSale.isSaleClosed(saleId), "AltrFractionsBuyout: sale not finished yet");
		_;
	}
	/**
	 * @dev Rejects calls if the specified buyout has already started
	 * @param buyoutId The buyout to check
	 */
	modifier onlyBeforeBuyoutOpen(uint256 buyoutId) {
		require(isBeforeBuyoutOpen(buyoutId), "AltrFractionsBuyout: buyout already started");
		_;
	}
	/**
	 * @dev Rejects calls if the specified buyout is not open yet
	 * @param buyoutId The buyout to check
	 */
	modifier onlyWhileBuyoutOpen(uint256 buyoutId) {
		require(isBuyoutOpen(buyoutId), "AltrFractionsBuyout: buyout not open");
		_;
	}

	/**
	 * @dev Constructor function to initialize the AltrFractionsBuyout contract
	 * @param _altrFractions Address of the IFractions contract that holds the token fractions
	 * @param _altrFractionsSale Address of the IFractionsSale contract that holds the information of the fractions sale
	 * @param _feeManager Address of the feeManager contract that manages the buyout fee
	 * @param _buyoutMinFractions Minimum fractions required for a sale to be boughtOut
	 * @param _buyoutOpenTimePeriod Time duration for the buyout to be open
	 */
	constructor(IFractions _altrFractions, IFractionsSale _altrFractionsSale, address _feeManager, uint256 _buyoutMinFractions, uint256 _buyoutOpenTimePeriod) {
		require(address(_altrFractions) != address(0) && address(_altrFractionsSale) != address(0), "AltrFractionsBuyout: cannot be null address");

		altrFractions = _altrFractions;
		altrFractionsSale = _altrFractionsSale;
		_setBuyoutMinFractions(_buyoutMinFractions);
		_setBuyoutOpenTimePeriod(_buyoutOpenTimePeriod);
		_setFeeManager(_feeManager);

		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	/**
	 * @dev Initiates a buyout request for a sale
	 * @param saleId The sale to be boughtOut
	 */
	function requestBuyout(uint256 saleId) external nonReentrant onlyIfSaleClosed(saleId) {
		IFractionsSale.FractionsSale memory fractionsSale = altrFractionsSale.getFractionsSale(saleId);
		require(fractionsSale.fractionsSold >= fractionsSale.saleMinFractions, "AltrFractionsBuyout: sale unsuccessful");
		require(canDoBuyout(msg.sender, saleId), "AltrFractionsBuyout: not enough fractions");

		uint256 currentBuyoutId = _buyoutsCounter.current();
		_buyoutsCounter.increment();

		buyouts[currentBuyoutId] = Buyout({
			initiator: msg.sender,
			fractionSaleId: saleId,
			buyoutTokenManager: address(0),
			buyoutToken: fractionsSale.buyToken,
			buyoutPrice: 0,
			openingTime: 0,
			closingTime: 0,
			fractionsToBuyout: 0,
			isSuccessful: false
		});

		emit BuyoutRequested(saleId, msg.sender, currentBuyoutId);
	}

	/**
	 * @dev Sets the parameters for a buyout request
	 * @param buyoutId The buyout to set the parameters for
	 * @param buyoutPrice The price for buyout the tokens
	 */
	function setBuyoutParams(uint256 buyoutId, uint256 buyoutPrice) external onlyRole(DEFAULT_ADMIN_ROLE) onlyBeforeBuyoutOpen(buyoutId) {
		require(_buyoutsCounter.current() > buyoutId, "AltrFractionsBuyout: invalid buyout id");
		Buyout storage buyout = buyouts[buyoutId];
		buyout.openingTime = block.timestamp;
		buyout.closingTime = block.timestamp + buyoutOpenTimePeriod;
		buyout.buyoutPrice = buyoutPrice;

		emit BuyoutParamsSet(buyoutId, buyout);
	}

	/**
	 * @dev Executes a buyout request for 100% fractions holder
	 * @param saleId The ID of the sale to buyout
	 * @notice Only 100% fractions holder can execute this function
	 */
	function buyoutUnsupervised(uint256 saleId) external nonReentrant onlyIfSaleClosed(saleId) {
		IFractionsSale.FractionsSale memory fractionsSale = altrFractionsSale.getFractionsSale(saleId);
		uint256 fractionsBalance = altrFractions.balanceOf(msg.sender, saleId);
		require(fractionsBalance == fractionsSale.fractionsSold, "AltrFractionsBuyout: not enough fractions");
		require(fractionsSale.fractionsSold >= fractionsSale.saleMinFractions, "AltrFractionsBuyout: sale unsuccessful");

		uint256 currentBuyoutId = _buyoutsCounter.current();
		_buyoutsCounter.increment();

		buyouts[currentBuyoutId] = Buyout({
			initiator: msg.sender,
			fractionSaleId: saleId,
			buyoutTokenManager: address(0),
			buyoutToken: fractionsSale.buyToken,
			buyoutPrice: 0,
			openingTime: block.timestamp,
			closingTime: block.timestamp,
			fractionsToBuyout: 0,
			isSuccessful: true
		});

		altrFractions.burn(msg.sender, saleId, fractionsBalance);
		altrFractions.setBuyoutStatus(saleId);

		fractionsSale.nftCollection.approve(msg.sender, fractionsSale.nftId);

		uint256 firstSalePrice = fractionsSale.fractionPrice * fractionsSale.fractionsAmount;

		feeManager.setSaleInfo(address(fractionsSale.nftCollection), fractionsSale.nftId, address(fractionsSale.buyToken), firstSalePrice);

		emit BuyoutExecuted(currentBuyoutId, msg.sender, fractionsBalance, 0, address(altrFractions), saleId);
	}

	/**
	 * @dev Executes a buyout request
	 * @param buyoutId The buyout to be executed
	 * @notice This function can only be executed after a buyout has been requested and the buyout params have been set
	 */
	function executeBuyout(uint256 buyoutId) external onlyWhileBuyoutOpen(buyoutId) {
		Buyout storage buyout = buyouts[buyoutId];
		require(buyout.initiator == msg.sender, "AltrFractionsBuyout: must be buyout initiator");

		IFractionsSale.FractionsSale memory fractionsSale = altrFractionsSale.getFractionsSale(buyout.fractionSaleId);
		uint256 fractionsBalance = altrFractions.balanceOf(msg.sender, buyout.fractionSaleId);

		require(canDoBuyout(msg.sender, buyout.fractionSaleId), "AltrFractionsBuyout: not enough fractions");

		uint256 fractionsToBuyout = fractionsSale.fractionsSold - fractionsBalance;
		uint256 buyoutAmount = buyout.buyoutPrice * fractionsToBuyout;
		uint256 protocolFeeAmount = (buyoutAmount * feeManager.buyoutFee()) / _DENOMINATOR;

		buyout.fractionsToBuyout = fractionsToBuyout;
		buyout.isSuccessful = true;

		altrFractions.burn(msg.sender, buyout.fractionSaleId, fractionsBalance);
		altrFractions.setBuyoutStatus(buyout.fractionSaleId);

		address buyoutTokenManager = address(new TokenSplitter(buyout.buyoutToken, altrFractions, buyout.fractionSaleId, fractionsToBuyout));
		buyout.buyoutTokenManager = buyoutTokenManager;

		buyout.buyoutToken.safeTransferFrom(msg.sender, feeManager.governanceTreasury(), protocolFeeAmount);
		buyout.buyoutToken.safeTransferFrom(msg.sender, buyoutTokenManager, buyoutAmount);

		altrFractions.grantRole(BURN_MANAGER_ROLE, buyoutTokenManager);
		fractionsSale.nftCollection.approve(msg.sender, fractionsSale.nftId);

		uint256 firstSalePrice = fractionsSale.fractionPrice * fractionsSale.fractionsAmount;

		feeManager.setSaleInfo(address(fractionsSale.nftCollection), fractionsSale.nftId, address(fractionsSale.buyToken), firstSalePrice);

		emit BuyoutExecuted(buyoutId, msg.sender, fractionsBalance, buyoutAmount, address(altrFractions), buyout.fractionSaleId);
	}

	/**
	 * @dev Set the minimum number of fractions required to initiate a buyout
	 * @param _buyoutMinFractions The minimum number of fractions required for buyout
	 */
	function setBuyoutMinFractions(uint256 _buyoutMinFractions) external onlyRole(DEFAULT_ADMIN_ROLE) {
		_setBuyoutMinFractions(_buyoutMinFractions);

		emit BuyoutMinFractionsSet(_buyoutMinFractions);
	}

	/**
	 * @dev Sets the time period for buyout to be open
	 * @param _buyoutOpenTimePeriod The new time period for buyout to be open
	 */
	function setBuyoutOpenTimePeriod(uint256 _buyoutOpenTimePeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
		_setBuyoutOpenTimePeriod(_buyoutOpenTimePeriod);

		emit BuyoutOpenTimePeriodSet(_buyoutOpenTimePeriod);
	}

	/**
	 *  @dev Sets the address of the fee manager
	 * @param _feeManager The address of the fee manager
	 */
	function setFeeManager(address _feeManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
		_setFeeManager(_feeManager);

		emit FeeManagerSet(_feeManager);
	}

	/**
	 * @dev Returns true if the buyout has not yet started
	 * @param buyoutId The id of the buyout
	 * @return true if the buyout has not yet started, otherwise false
	 */
	function isBeforeBuyoutOpen(uint256 buyoutId) public view returns (bool) {
		return buyouts[buyoutId].openingTime == 0;
	}

	/**
	 * @dev Check if the buyout with the given id is still open
	 * @param buyoutId The id of the buyout to check
	 * @return true if the buyout is open, false otherwise
	 */
	function isBuyoutOpen(uint256 buyoutId) public view returns (bool) {
		Buyout memory buyout = buyouts[buyoutId];
		return block.timestamp >= buyout.openingTime && block.timestamp <= buyout.closingTime && !buyout.isSuccessful;
	}

	/**
	 * @dev Check whether the contract implements a specific interface
	 * @param interfaceId The interface identifier, as a 4-byte value
	 * @return true if the contract implements the interface, false otherwise
	 */
	function supportsInterface(bytes4 interfaceId) public view override(AccessControl) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	/**
	 * @dev Determine if the buyout initiator has enough fractions to perform a buyout
	 * @param buyoutInitiator the address of the buyout initiator
	 * @param saleId the ID of the sale
	 * @return boolean indicating if the buyout initiator can do a buyout
	 */
	function canDoBuyout(address buyoutInitiator, uint256 saleId) public view returns (bool) {
		uint256 fractionsSold = altrFractionsSale.getFractionsSale(saleId).fractionsSold;
		uint256 minFractionsAmount = fractionsSold - ((fractionsSold * buyoutMinFractions) / _DENOMINATOR);
		uint256 fractionsBalance = altrFractions.balanceOf(buyoutInitiator, saleId);
		return fractionsBalance > minFractionsAmount;
	}

	/**
	 * @dev returns the current number of buyouts
	 * @return uint256 current number of buyouts
	 */
	function buyoutsCounter() public view returns (uint256) {
		return _buyoutsCounter.current();
	}

	/**
	 * @dev sets the minimum number of fractions required for buyout
	 *@param _buyoutMinFractions The minimum number of fractions that can be bought out
	 */
	function _setBuyoutMinFractions(uint256 _buyoutMinFractions) internal {
		require(_buyoutMinFractions >= _MIN_FRACTIONS && _buyoutMinFractions <= _MAX_FRACTIONS, "AltrFractionsBuyout: buyout min fractions exceed boundaries");

		buyoutMinFractions = _buyoutMinFractions;
	}

	/**
	 * @dev sets the feeManager address. Only callable by contracts's admin role
	 * @param _feeManager The address of the fee manager contract
	 */
	function _setFeeManager(address _feeManager) internal {
		require(_feeManager != address(0), "AltrFractionsBuyout: cannot be null address");
		require(_feeManager.supportsInterface(type(IFeeManager).interfaceId), "AltrFractionsBuyout: does not support IFeeManager interface");

		feeManager = IFeeManager(_feeManager);
	}

	/**
	 * @dev sets the time period during which a buyout can be executed
	 * @param _buyoutOpenTimePeriod The time period during which a buyout can be executed
	 */
	function _setBuyoutOpenTimePeriod(uint256 _buyoutOpenTimePeriod) internal {
		require(_buyoutOpenTimePeriod > _MIN_BUYOUT_OPEN_TIME_PERIOD, "AltrFractionsBuyout: open time period cannot be less than minimum");

		buyoutOpenTimePeriod = _buyoutOpenTimePeriod;
	}
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2021 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity ^0.8.17;

interface IFeeManager {
	/**
	 * @dev A callback function invoked in the ERC721Feature for each ERC721
	 *      order fee that get paid. Integrators can make use of this callback
	 *      to implement arbitrary fee-handling logic, e.g. splitting the fee
	 *      between multiple parties.
	 * @param tokenAddress The address of the token in which the received fee is
	 *        denominated. `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` indicates
	 *        that the fee was paid in the native token (e.g. ETH).
	 * @param amount The amount of the given token received.
	 * @param feeData Arbitrary data encoded in the `Fee` used by this callback.
	 * @return success The selector of this function (0x0190805e),
	 *         indicating that the callback succeeded.
	 */
	function receiveZeroExFeeCallback(address tokenAddress, uint256 amount, bytes calldata feeData) external returns (bytes4 success);

	function isRedemptionFeePaid(address nftCollection, uint256 tokenId) external view returns (bool feePaid);

	function buyoutFee() external view returns (uint256 buyoutFee);

	function saleFee() external view returns (uint256 saleFee);

	function governanceTreasury() external view returns (address governanceTreasury);

	function setSaleInfo(address nftCollection, uint256 tokenId, address redemptionFeeTokenAddress, uint256 price) external;

	function salesInfo(
		address nftCollection,
		uint256 tokenId
	) external returns (bool isRedemptionFeePaid, uint256 firstSalePrice, address redemptionFeeTokenAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IFractions is IERC1155 {
	function mint(address to, uint256 tokenId, uint256 amount, bytes memory data) external;

	function burn(address account, uint256 id, uint256 amount) external;

	function operatorBurn(address account, uint256 id, uint256 amount) external;

	function setBuyoutStatus(uint256 tokenId) external;

	function setClosingTimeForTokenSale(uint256 tokenId, uint256 closingTime) external;

	function grantRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFractionsSale {
	struct FractionsSale {
		address initiator;
		address buyTokenManager;
		IERC721 nftCollection;
		uint256 nftId;
		IERC20 buyToken;
		uint256 openingTime;
		uint256 closingTime;
		uint256 fractionPrice;
		uint256 fractionsAmount;
		uint256 minFractionsKept;
		uint256 fractionsSold;
		uint256 saleMinFractions;
	}

	function isSaleClosed(uint256 saleId) external view returns (bool);

	function isSaleSuccessful(uint256 saleId) external view returns (bool);

	function getFractionsSale(uint256 saleId) external view returns (FractionsSale memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./TokenSplitter.sol";
import "./interfaces/IFractionsSale.sol";

/**
 * @title TimedTokenSplitter
 * @author Lucidao Developer
 * @dev Contract used to manage the tokens used to purchase Altr fractions.
 */
contract TimedTokenSplitter is TokenSplitter {
	using SafeERC20 for IERC20;

	uint256 private constant _DENOMINATOR = 10000;
	bool private releaseStarted = false;
	/**
	 * @dev A reference to the sale contract that is being used to manage the sale of the fractions
	 */
	IFractionsSale public immutable saleContract;
	/**
	 * @dev The ID of the sale that is being managed by this contract
	 */
	uint256 public immutable saleId;
	/**
	 * @dev The address of the governance treasury that will receive the protocol fee from the sale of the fractions
	 */
	address public immutable governanceTreasury;
	/**
	 * @dev The amount of the protocol fee that will be taken from the sale of the fractions
	 */
	uint256 public immutable protocolFee;
	/**
	 * @dev The address of the seller who is selling the fractions
	 */
	address public immutable seller;
	/**
	 * @dev Emits when tokens seller is released
	 * @param seller The address of the seller
	 * @param saleContract Address of the sale contract
	 * @param saleId Identifier of the sale
	 * @param sellerAmount The amount that was released to the seller
	 */
	event TokensSellerReleased(address seller, IFractionsSale saleContract, uint256 saleId, uint256 sellerAmount);

	/**
	 * @dev Modifier that checks if the sale of the contract has closed or not
	 * If the sale is not closed, the function calling this modifier will revert with the error message "TimedTokenSplitter: sale not finished yet"
	 */
	modifier onlyIfSaleClosed() {
		require(saleContract.isSaleClosed(saleId), "TimedTokenSplitter: sale not finished yet");
		_;
	}
	/**
	 * @dev Modifier that checks if the sale of the contract has failed or not
	 * If the sale is successful, the function calling this modifier will revert with the error message "TimedTokenSplitter: sale did not fail"
	 */
	modifier onlyFailedSale() {
		require(!saleContract.isSaleSuccessful(saleId), "TimedTokenSplitter: sale did not fail");
		_;
	}
	/**
	 * @dev Modifier that checks if the sale of the contract has been successful or not
	 * If the sale is unsuccessful, the function calling this modifier will revert with the error message "TimedTokenSplitter: sale unsuccessful"
	 */
	modifier onlySuccessfulSale() {
		require(saleContract.isSaleSuccessful(saleId), "TimedTokenSplitter: sale unsuccessful");
		_;
	}

	/**
	 * @dev TimedTokenSplitter contract constructor.
	 * Initializes the contract with the sale contract address, the sale id, the token to redeem, the token that represents the fractional ownership, the token price, the governance treasury address, the protocol fee, and the seller address
	 * @param saleContract_ address of the sale contract
	 * @param saleId_ the id of the sale
	 * @param redemptionToken_ the token to redeem
	 * @param token_ the token that represents the fractional ownership
	 * @param fractionsIssued the amount of fractions issued
	 * @param governanceTreasury_ the address of the governance treasury
	 * @param protocolFee_ the percentage of fee taken from the token amount
	 * @param seller_ the address of the seller
	 */

	constructor(
		address saleContract_,
		uint256 saleId_,
		IERC20 redemptionToken_,
		IFractions token_,
		uint256 fractionsIssued,
		address governanceTreasury_,
		uint256 protocolFee_,
		address seller_
	) TokenSplitter(redemptionToken_, token_, saleId_, fractionsIssued) {
		saleContract = IFractionsSale(saleContract_);
		saleId = saleId_;
		governanceTreasury = governanceTreasury_;
		protocolFee = protocolFee_;
		seller = seller_;
	}

	/**
	 * @dev Function to release the seller's token from the contract
	 * @notice This function can only be called after the sale is closed and was successful
	 * @notice this function will transfer protocolFee/10000 of the amount to the governanceTreasury and the rest to the seller
	 */
	function releaseSeller() public onlyIfSaleClosed onlySuccessfulSale {
		uint256 amount = redemptionToken.balanceOf(address(this));
		uint256 protocolFeeAmount = (amount * protocolFee) / _DENOMINATOR;
		uint256 sellerAmount = amount - protocolFeeAmount;

		redemptionToken.safeTransfer(governanceTreasury, protocolFeeAmount);
		redemptionToken.safeTransfer(seller, sellerAmount);

		emit TokensSellerReleased(seller, saleContract, saleId, sellerAmount);
	}

	/**
	 * @dev Function to release the user's token from the contract
	 * @param users address[] calldata of the users that we want to release the token
	 * @notice This function can only be called after the sale is closed and was unsuccessful
	 */
	function release(address[] calldata users) public override(TokenSplitter) onlyIfSaleClosed onlyFailedSale {
		if (!releaseStarted) {
			releaseStarted = true;
			fractionsToBuyout = saleContract.getFractionsSale(saleId).fractionsSold;
		}
		super.release(users);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IFractions.sol";

/**
 * @title TokenSplitter
 * @author Lucidao Developer
 * @dev Contract for managing tokens used to buyout Altr fractions.
 */
contract TokenSplitter is ReentrancyGuard {
	using SafeERC20 for IERC20;
	/**
	 * @dev The ERC-20 token that users need to provide to redeem the fractions
	 */
	IERC20 public immutable redemptionToken;
	/**
	 * @dev The fractional token that users will redeem
	 */
	IFractions public immutable token;
	/**
	 * @dev The amount of fractions issued from token contract
	 */
	uint256 public fractionsToBuyout;
	/**
	 * @dev The ID of the NFT that corresponds to this token redemption
	 */
	uint256 public immutable tokenId;

	/**
	 * @dev Event emitted when the tokens are released to the users
	 * @param users array of addresses of the users that receive the tokens
	 * @param redemptionToken The address of the token used for redemption
	 * @param token The address of the token contract that holds the fractions being redeemed
	 * @param tokenId The id of the token that represents the fractions being redeemed
	 * @param amounts The amounts of fractions being redeemed
	 * @param fractionsPrice The price of each fraction being redeemed
	 */
	event TokensReleased(address[] users, IERC20 indexed redemptionToken, IFractions indexed token, uint256 tokenId, uint256[] amounts, uint256 fractionsPrice);

	/**
	 * @dev Create the TokenSplitter instance and set the token instances
	 * @param redemptionToken_ The ERC20 token for redemption
	 * @param token_ The token to be split
	 * @param tokenId_ Token Id for the token to be split
	 * @param fractionsToBuyout_ the amount of fractions to buyout
	 */
	constructor(IERC20 redemptionToken_, IFractions token_, uint256 tokenId_, uint256 fractionsToBuyout_) {
		redemptionToken = redemptionToken_;
		token = token_;
		tokenId = tokenId_;
		fractionsToBuyout = fractionsToBuyout_;
	}

	/**
	 * @dev Release the tokens, by burning the token in token contract and transfer the redemption token to the user
	 * @param users The array of users' addresses to release the tokens to
	 */
	function release(address[] calldata users) public virtual nonReentrant {
		require(fractionsToBuyout > 0, "TokenSplitter: fractions amount cannot be 0");
		uint256[] memory amounts = new uint256[](users.length);
		uint256 fractionsPrice;
		uint256 boughtOutFractions;
		uint256 tokenBalance = redemptionToken.balanceOf(address(this));
		uint256 tokenPrice = tokenBalance / fractionsToBuyout;
		for (uint256 i; i < users.length; i++) {
			amounts[i] = token.balanceOf(users[i], tokenId);
			boughtOutFractions += amounts[i];
			fractionsPrice = (tokenBalance * amounts[i]) / fractionsToBuyout;

			token.operatorBurn(users[i], tokenId, amounts[i]);
			redemptionToken.safeTransfer(users[i], fractionsPrice);
		}
		fractionsToBuyout -= boughtOutFractions;
		emit TokensReleased(users, redemptionToken, token, tokenId, amounts, tokenPrice);
	}
}