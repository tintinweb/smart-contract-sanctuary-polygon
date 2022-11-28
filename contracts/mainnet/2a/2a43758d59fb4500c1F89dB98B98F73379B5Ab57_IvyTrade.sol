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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./structures/organization.sol";
import "./structures/tokenBalanceInfo.sol";
import "./structures/paymentInERC20.sol";

/***********************************************************************************************************************
 * IVY: Safe & Seamless Web3 Finance
 * https://ivy.trade
 **********************************************************************************************************************/
contract IvyTrade is AccessControl, ReentrancyGuard {

    using SafeERC20 for IERC20;

    /******************************************************************************************************************
    * Roles
    ******************************************************************************************************************/

    // this role does all admin level tasks - update supported tokens, withdraw funds
    bytes32 public constant PLATFORM_ADMIN = keccak256("PLATFORM_ADMIN");

    // this role is responsible for marking organization's as verified
    bytes32 public constant PLATFORM_VERIFICATION_MANAGER = keccak256("PLATFORM_VERIFICATION_MANAGER");

    // this role is responsible for giving credits to organizations
    bytes32 public constant PLATFORM_CREDIT_MANAGER = keccak256("PLATFORM_CREDIT_MANAGER");

    /******************************************************************************************************************
    * Platform Configs
    ******************************************************************************************************************/

    // native token
    address private constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // platform treasury wallet address
    address public treasury;

    // platform treasury wallet address
    address public crossChainTreasury;

    // this is the default platform fees percentage for new organizations
    // maps chain id to platform fees % on that chain.
    mapping(uint256 => uint256) defaultPlatformFees;

    // this is the amount of platform fees collective in native token
    uint256 public platformFeesCollected = 0;

    // this keeps track of platform fees collected in erc20 tokens
    mapping(address => uint256) platformFeesCollectedInTokens;

    // para-swap contract address
    address public paraSwap;

    // para-swap token transfer proxy address
    address public paraSwapTokenTransferProxy;

    // hyphen liquidity pool contract address
    address public hyphenLiquidityPool;

    // supported primary chains
    mapping(uint256 => bool) public supportedPrimaryChainIds;

    // supported secondary chains
    mapping(uint256 => bool) public supportedSecondaryChainIds;

    // supported erc20 tokens for payment
    mapping(address => bool) public supportedERC20Tokens;

    // this keeps track of registered organizations
    uint256 public organizationCounter = 0;

    // this maps organization id to organization details
    mapping(uint256 => Organization) private organizationsIdMap;

    // this will be default verification status for new organizations
    bool public defaultVerificationStatus = false;

    // this is the time after which new wallets get activated.
    uint32 public constant ACTIVATION_DELAY = 48 hours;

    /******************************************************************************************************************
    * Events
    ******************************************************************************************************************/

    // This event is emitted when a new organization is created.
    event NewOrganizationCreated(
        uint256 organization_id, // newly created organization id
        string indexed tag // backend's guid of organization document
    );

    // This event is emitted when a wallet is added/removed for an organization.
    event WalletsUpdated(
        uint256 indexed organization_id,
        address wallet,
        bool status
    );

    // This event is emitted when a funds are added to an organization.
    event FundsDeposited(
        uint256 indexed organization_id,
        uint256 amount,
        address tokenAddress
    );

    // This event is emitted when an organization requests withdrawal of deposited funds.
    event FundsWithdrawn(
        uint256 indexed organization_id,
        uint256 amount,
        address tokenAddress
    );

    // This event is emitted when an invoice is approved and will be processed on secondary chain.
    // Payment status will different as per network.
    event InvoiceApproved(
        uint256 indexed toOrganizationId,
        uint256 amount,
        string invoice_id,
        uint256 receiveFundsOnChainId,
        address tokenAddress
    );

    // This event is emitted when an invoice is paid.
    event InvoicePaid(
        uint256 indexed organization_id,
        uint256 amount,
        string invoice_id,
        uint256 receiveFundsOnChainId,
        address tokenAddress
    );

    // This event is emitted when an platform verification manager, verifies organizations.
    event OrganizationVerified(
        uint256[] indexed organizationIds,
        bool[] status
    );

    // This event is emitted when platform/cross-chain treasury wallet changes.
    event TreasuryUpdated(
        address indexed newAddress,
        bool crossChain
    );

    // This event is emitted when paraswap/hyphen contract addresses change.
    event OtherContractsUpdated(
        address indexed newAddress,
        uint8 target
    );

    // This event is emitted when an platform manager, withdraws fees collected to treasury wallet.
    event PlatformFeesWithdrawn(
        uint256 amount,
        address tokenAddress
    );

    constructor(
        address _treasury,
        address _crossChainTreasury,
        address[] memory _supportedERC20Tokens,
        uint256[] memory _supportedPrimaryChainIds,
        uint256[] memory _supportedSecondaryChainIds,
        address _paraSwapContract,
        address _paraSwapTokenTransferProxy,
        address _hyphenLiquidityPool
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PLATFORM_VERIFICATION_MANAGER, msg.sender);
        _grantRole(PLATFORM_CREDIT_MANAGER, msg.sender);
        _grantRole(PLATFORM_ADMIN, msg.sender);

        require(_treasury != address(0), "INVALID_TREASURY");
        require(_crossChainTreasury != address(0), "INVALID_CROSS_CHAIN_TREASURY");
        require(_paraSwapContract != address(0), "INVALID_PARASWAP_ADDRESS");
        require(_paraSwapTokenTransferProxy != address(0), "INVALID_PARASWAP_ADDRESS");
        require(_hyphenLiquidityPool != address(0), "INVALID_HYPHEN_ADDRESS");

        treasury = _treasury;
        crossChainTreasury = _crossChainTreasury;

        for (uint i = 0; i < _supportedERC20Tokens.length; i++) {
            supportedERC20Tokens[_supportedERC20Tokens[i]] = true;
        }

        for (uint i = 0; i < _supportedPrimaryChainIds.length; i++) {
            supportedPrimaryChainIds[_supportedPrimaryChainIds[i]] = true;
        }

        for (uint i = 0; i < _supportedSecondaryChainIds.length; i++) {
            supportedSecondaryChainIds[_supportedSecondaryChainIds[i]] = true;
        }

        paraSwap = _paraSwapContract;
        paraSwapTokenTransferProxy = _paraSwapTokenTransferProxy;
        hyphenLiquidityPool = _hyphenLiquidityPool;
    }

    // Permission check, only wallets listed in organization can proceed forward.
    modifier onlyOrganizationAdmins(
        uint256 organization_id
    ) {
        Organization storage organization = organizationsIdMap[organization_id];
        require(
            organization.addresses[msg.sender],
            "PERMISSION_DENIED"
        );
        require(
            organization.activateAfter[msg.sender] < block.timestamp,
            "WALLET_NOT_ACTIVATED"
        );
        _;
    }

    modifier onlySupportedTokens(
        address tokenAddress
    ) {
        require(supportedERC20Tokens[tokenAddress], "UNSUPPORTED_TOKEN");
        _;
    }

    modifier onlyValidOrganizations(
        uint256 organization_id
    ) {
        require(organization_id < organizationCounter, "INVALID_ORGANIZATION_ID");
        _;
    }

    /******************************************************************************************************************
    * -----------------------------------------------------------------------------------------------------------------
    * Platform Admin Actions
    * -----------------------------------------------------------------------------------------------------------------
    ******************************************************************************************************************/

    /**************************************************************************
    * Update platform treasury/cross-chain treasury wallet.
    ***************************************************************************/
    function updateTreasury(
        address newAddress,
        bool crossChain
    )
        external
        onlyRole(PLATFORM_ADMIN)
    {
        require(newAddress != address(0) , "ZERO_ADDRESS_NOT_ALLOWED");
        if (crossChain) {
            crossChainTreasury = newAddress;
        } else {
            treasury = newAddress;
        }
        emit TreasuryUpdated(newAddress, crossChain);
    }

    /**************************************************************************
    * Update third party contract addresses.
    * 0 => update paraswap
    * 1 => update paraswap token transfer proxy
    * 2 => update hyphen liquidity contract.
    ***************************************************************************/
    function updateOtherContract(
        address newAddress,
        uint8 target
    )
        external
        onlyRole(PLATFORM_ADMIN)
    {
        require(newAddress != address(0) , "ZERO_ADDRESS_NOT_ALLOWED");
        require(target >= 0 && target <= 2, "INVALID_TARGET");

        if (target == 0) {
            paraSwap = newAddress;
        } else if (target == 1) {
            paraSwapTokenTransferProxy = newAddress;
        } else if (target == 2) {
            hyphenLiquidityPool = newAddress;
        }
        emit OtherContractsUpdated(newAddress, target);
    }

    /**************************************************************************
    * Update default platform fees for new organizations.
    ***************************************************************************/
    function setDefaultPlatformFees(
        uint256 chainId,
        uint256 newDefaultPlatformFees
    )
        external
        onlyRole(PLATFORM_ADMIN)
    {
        require(newDefaultPlatformFees >= 0 && newDefaultPlatformFees <= 100, "INVALID_FEES");
        defaultPlatformFees[chainId] = newDefaultPlatformFees;
    }

     /**************************************************************************
    * Update default verification status for new organizations.
    ***************************************************************************/
    function setDefaultVerificationStatus(
        bool newStatus
    )
        external
        onlyRole(PLATFORM_VERIFICATION_MANAGER)
    {
        defaultVerificationStatus = newStatus;
    }

    /**************************************************************************
    * Mark Organization as verified.
    ***************************************************************************/
    function markVerified(
        uint256[] memory organizationIds,
        bool[] memory status
    )
        external
        onlyRole(PLATFORM_VERIFICATION_MANAGER)
    {
        require(organizationIds.length == status.length, "INVALID_PARAMETERS");
        for (uint i = 0; i < organizationIds.length; i++) {
            Organization storage organization = organizationsIdMap[organizationIds[i]];
            organization.isVerified = status[i];
        }
        emit OrganizationVerified(organizationIds, status);
    }

    /**************************************************************************
    * Set custom platform fees for organization.
    ***************************************************************************/
    function setCustomPlatformFees(
        uint256 organizationId,
        uint256[] memory chainIds,
        uint256[] memory platformFees,
        address[] memory tokenAddresses,
        uint256[] memory platformFeesCap
    )
        external
        onlyRole(PLATFORM_CREDIT_MANAGER)
    {
        require(chainIds.length == platformFees.length, "INVALID_FEES_DATA");
        require(tokenAddresses.length == platformFeesCap.length, "INVALID_TOKEN_DATA");
        Organization storage organization = organizationsIdMap[organizationId];

        for (uint i = 0; i < chainIds.length; i++) {
            require(platformFees[i] >= 0 && platformFees[i] <= 100, "INVALID_FEES");
            organization.platformFees[chainIds[i]] = platformFees[i];
        }
        for (uint i = 0; i < tokenAddresses.length; i++) {
            require(platformFeesCap[i] >= 0 , "INVALID_FEES");
            organization.platformFeesCap[tokenAddresses[i]] = platformFeesCap[i];
        }
    }

    /**************************************************************************
    * Update supported tokens. Payments can be done in these ERC20 tokens.
    ***************************************************************************/
    function updateSupportedTokens(
        address tokenAddress,
        bool status
    )
        external
        onlyRole(PLATFORM_ADMIN)
    {
        supportedERC20Tokens[tokenAddress] = status;
    }

    /**************************************************************************
    * Update supported chain ids.
    ***************************************************************************/
    function updateSupportedChainIds(
        uint256[] memory supportedChainIds,
        bool[] memory updatedStatus,
        bool primary
    )
        external
        onlyRole(PLATFORM_ADMIN)
    {
        require(supportedChainIds.length == updatedStatus.length, "INVALID_DATA");

        if (primary) {
            for (uint i = 0; i < supportedChainIds.length; i++) {
                supportedPrimaryChainIds[supportedChainIds[i]] = updatedStatus[i];
            }
            return;
        }

        for (uint i = 0; i < supportedChainIds.length; i++) {
            supportedSecondaryChainIds[supportedChainIds[i]] = updatedStatus[i];
        }
    }

    /**************************************************************************
    * Withdraw platform fees collected in the native token
    ***************************************************************************/
    function withdrawPlatformFeesCollected()
        external
        nonReentrant
        onlyRole(PLATFORM_ADMIN)
    {
        require(platformFeesCollected > 0, "PLATFORM_INSUFFICIENT_BALANCE");
        (bool sent, ) = payable(treasury).call{value: platformFeesCollected}("");
        require(sent, "FAILED_TO_SEND_AMOUNT");
        platformFeesCollected = 0;
        emit PlatformFeesWithdrawn(platformFeesCollected, NATIVE);
    }

    /**************************************************************************
    * Withdraw platform fees collected in specific ERC20 token.
    ***************************************************************************/
    function withdrawPlatformFeesCollectedInToken(
        address tokenAddress
    )
        external
        nonReentrant
        onlyRole(PLATFORM_ADMIN)
    {
        uint256 totalBalance = IERC20(tokenAddress).balanceOf(address(this));
        uint256 feesBalance = platformFeesCollectedInTokens[tokenAddress];

        require(feesBalance > 0, "ZERO_BALANCE");
        require(totalBalance >= feesBalance, "PLATFORM_INSUFFICIENT_BALANCE");

        // withdraw funds
        IERC20(tokenAddress).safeTransfer(treasury, feesBalance);
        platformFeesCollectedInTokens[tokenAddress] = 0;
        emit PlatformFeesWithdrawn(feesBalance, tokenAddress);
    }

    /******************************************************************************************************************
    * -----------------------------------------------------------------------------------------------------------------
    * Organization Actions
    * -----------------------------------------------------------------------------------------------------------------
    ******************************************************************************************************************/

    /******************************************************************************************************
    * Create New Organization.
    ******************************************************************************************************/
    function create(
        address _withdrawalAddress,
        address[] memory wallets,
        string memory tag,
        uint256[] memory chainIds
    )
        external
    {
        require(_withdrawalAddress != address(0), "WITHDRAWAL_ADDRESS_CAN_NOT_BE_ZERO");
        Organization storage newOrganization = organizationsIdMap[organizationCounter];
        newOrganization.withdrawalAddress = _withdrawalAddress;
        newOrganization.addresses[msg.sender] = true;
        newOrganization.isVerified = defaultVerificationStatus;

        for (uint i = 0; i < wallets.length; i = i+1) {
            newOrganization.addresses[wallets[i]] = true;
            newOrganization.activateAfter[wallets[i]] = block.timestamp + ACTIVATION_DELAY;
        }

        // activate msg.sender immediately.
        newOrganization.activateAfter[msg.sender] = block.timestamp;

        for (uint i = 0; i < chainIds.length; i = i+1) {
            newOrganization.platformFees[chainIds[i]] = defaultPlatformFees[chainIds[i]];
        }

        organizationCounter += 1;
        emit NewOrganizationCreated(organizationCounter - 1, tag);
    }


    /******************************************************************************************************
    * Manage wallets for an organization. Add/remove based on status flag.
    *******************************************************************************************************/
    function manageWallets(
        uint256 organization_id,
        address wallet,
        bool status
    )
        external
        onlyOrganizationAdmins(organization_id)
    {
        Organization storage organization = organizationsIdMap[organization_id];
        require(msg.sender != wallet, "INVALID_REQUEST");
        organization.addresses[wallet] = status;
        if (status) {
            // activate after x hours.
            organization.activateAfter[wallet] = block.timestamp + ACTIVATION_DELAY;
        }
        organization.isVerified = false; // reset organization verification status
        emit WalletsUpdated(organization_id, wallet, status);

        // organization verification status reset event
        bool[] memory status_list = new bool[](1);
        status_list[0] = false;
        uint256[] memory organization_ids = new uint256[](1);
        organization_ids[0] = organization_id;
        emit OrganizationVerified(organization_ids, status_list);
    }

    /******************************************************************************************************
    * Deposit native token to an organization balance.
    *******************************************************************************************************/
    function deposit(
        uint256 organization_id
    )
        external
        payable
        onlyValidOrganizations(organization_id)
        nonReentrant
    {
        require(msg.value > 0, "INVALID_DEPOSIT_AMOUNT");

        // update organization balance
        Organization storage organization = organizationsIdMap[organization_id];
        organization.balance += msg.value;
        emit FundsDeposited(organization_id, msg.value, NATIVE);
    }

    /******************************************************************************************************
    * Deposit supported ERC20 tokens to an organization balance.
    *******************************************************************************************************/
    function depositERC20(
        uint256 organization_id,
        address tokenAddress,
        uint256 amount
    )
        external
        nonReentrant
        onlyValidOrganizations(organization_id)
        onlySupportedTokens(tokenAddress)
    {
        require(amount > 0, "INVALID_DEPOSIT_AMOUNT");

        // deposit amount in contract
        IERC20 paymentToken = IERC20(tokenAddress);
        paymentToken.safeTransferFrom(msg.sender, address(this), amount);

        // update organization balance
        Organization storage organization = organizationsIdMap[organization_id];
        organization.tokenBalances[tokenAddress] += amount;
        emit FundsDeposited(organization_id, amount, tokenAddress);
    }

    /******************************************************************************************************
    * Withdraw native tokens from the organization balance.
    *******************************************************************************************************/
    function withdraw(
        uint256 organization_id,
        uint256 amount
    )
        external
        nonReentrant
        onlyOrganizationAdmins(organization_id)
    {
        Organization storage organization = organizationsIdMap[organization_id];
        require(amount > 0, "INVALID_WITHDRAWAL_AMOUNT");
        require(address(this).balance >= amount, "PLATFORM_INSUFFICIENT_BALANCE");
        require(organization.balance >= amount, "INSUFFICIENT_BALANCE");


        organization.balance -= amount;
        (bool sent, ) = organization.withdrawalAddress.call{value: amount}("");
        require(sent, "FAILED_TO_SEND_AMOUNT");

        emit FundsWithdrawn(organization_id, amount, NATIVE);
    }

    /******************************************************************************************************
    * Withdraw ERC20 tokens from the organization balance.
    *******************************************************************************************************/
    function withdrawERC20(
        uint256 organization_id,
        address tokenAddress,
        uint256 amount
    )
        external
        nonReentrant
        onlyOrganizationAdmins(organization_id)
    {
        require(supportedERC20Tokens[tokenAddress], "UNSUPPORTED_TOKEN");
        require(amount > 0, "INVALID_WITHDRAWAL_AMOUNT");

        Organization storage organization = organizationsIdMap[organization_id];
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));

        require(balance >= amount, "PLATFORM_INSUFFICIENT_BALANCE");
        require(organization.tokenBalances[tokenAddress] >= amount, "INSUFFICIENT_BALANCE");

        organization.tokenBalances[tokenAddress] -= amount;
        IERC20(tokenAddress).safeTransfer(organization.withdrawalAddress, amount);

        emit FundsWithdrawn(organization_id, amount, tokenAddress);
    }


    /******************************************************************************************************
    * Approve Invoice in native token.
    *******************************************************************************************************/
    function makePayment(
        uint256 organization_id,
        uint256 paymentToOrganizationId,
        uint256 amount,
        string memory invoice_id,
        uint receiveFundsOnChainId
    )
        public
        onlyValidOrganizations(paymentToOrganizationId)
        onlyOrganizationAdmins(organization_id)
        nonReentrant
    {

        require(receiveFundsOnChainId == block.chainid, "UN_SUPPORTED_CHAIN_ID");
        require(organization_id != paymentToOrganizationId, "ORGANIZATION_IDS_CAN_NOT_BE_SAME");

        Organization storage fromOrganization = organizationsIdMap[organization_id];
        Organization storage toOrganization = organizationsIdMap[paymentToOrganizationId];

        require(fromOrganization.isVerified, "YOUR_ORGANIZATION_IS_NOT_VERIFIED");
        require(toOrganization.isVerified, "YOUR_CONTACT_IS_NOT_VERIFIED");

        uint256 platformFees = (amount * fromOrganization.platformFees[block.chainid]) / 100;
        if ((fromOrganization.platformFeesCap[NATIVE] > 0) && (platformFees > fromOrganization.platformFeesCap[NATIVE])) {
            platformFees = fromOrganization.platformFeesCap[NATIVE];
        }

        uint256 totalAmount = amount + platformFees;

        require(totalAmount > 0, "INVALID_AMOUNT");
        require(address(this).balance >= totalAmount, "PLATFORM_INSUFFICIENT_BALANCE");
        require(fromOrganization.balance >= totalAmount, "INSUFFICIENT_BALANCE");

        // update balances
        fromOrganization.balance -= totalAmount;

        if (platformFees > 0) {
            platformFeesCollected += platformFees;
        }

        toOrganization.balance += amount;
        emit InvoicePaid(organization_id, amount, invoice_id, block.chainid, NATIVE);

    }

    /******************************************************************************************************
    * Approve Bulk Invoices in native token.
    *******************************************************************************************************/
    function makeBulkPayment(
        uint256 fromOrganizationId,
        uint256[] memory toOrganizationIds,
        uint256[] memory amounts,
        string[] memory invoice_ids,
        uint[] memory receiveFundsOnChainIds
    )
        external
    {

        for (uint256 i = 0; i < toOrganizationIds.length; i++) {
            makePayment(
                fromOrganizationId,
                toOrganizationIds[i],
                amounts[i],
                invoice_ids[i],
                receiveFundsOnChainIds[i]
            );
        }

    }

    /******************************************************************************************************
    * Approve Invoice in ERC20 tokens.
    *******************************************************************************************************/
    function makePaymentInERC20(
        uint256 fromOrganizationId,
        uint256 toOrganizationId,
        bytes memory paymentMethod,
        bytes memory paymentData
    )
        public
        onlyOrganizationAdmins(fromOrganizationId)
        onlyValidOrganizations(toOrganizationId)
        nonReentrant
    {

        Organization storage toOrganization = organizationsIdMap[toOrganizationId];
        PaymentInERC20 memory payment;

        {
            // scope to avoid stack too deep errors
            (
              uint256 receiveFundsOnChainId,
              address tokenAddress,
              address receiver,
              uint256 amount,
              string memory invoice_id
            ) = abi.decode(paymentData, (uint256,address,address,uint256,string));
            payment.receiveFundsOnChainId = receiveFundsOnChainId;
            payment.tokenAddress = tokenAddress;
            payment.receiver = receiver;
            payment.amount = amount;
            payment.invoice_id = invoice_id;
        }

        require(supportedERC20Tokens[payment.tokenAddress], "UNSUPPORTED_TOKEN");
        require(fromOrganizationId != toOrganizationId, "ORGANIZATION_IDS_CAN_NOT_BE_SAME");
        require(block.chainid == payment.receiveFundsOnChainId || supportedPrimaryChainIds[payment.receiveFundsOnChainId] || supportedSecondaryChainIds[payment.receiveFundsOnChainId], "UN_SUPPORTED_CHAIN_ID");
        require(toOrganization.isVerified, "YOUR_CONTACT_IS_NOT_VERIFIED");

        {
            // scope to avoid stack too deep errors
            Organization storage fromOrganization = organizationsIdMap[fromOrganizationId];
            require(fromOrganization.isVerified, "YOUR_ORGANIZATION_IS_NOT_VERIFIED");

            uint256 platformFees = (payment.amount * fromOrganization.platformFees[payment.receiveFundsOnChainId]) / 100;
            if ((fromOrganization.platformFeesCap[payment.tokenAddress] > 0) && (platformFees > fromOrganization.platformFeesCap[payment.tokenAddress])) {
                platformFees = fromOrganization.platformFeesCap[payment.tokenAddress];
            }

            uint256 totalAmount = payment.amount + platformFees;
            require(totalAmount > 0, "INVALID_AMOUNT");

            uint256 platformBalance = IERC20(payment.tokenAddress).balanceOf(address(this));
            require(platformBalance >= totalAmount, "PLATFORM_INSUFFICIENT_BALANCE");
            require(fromOrganization.tokenBalances[payment.tokenAddress] >= totalAmount, "INSUFFICIENT_BALANCE");

            // update balances
            fromOrganization.tokenBalances[payment.tokenAddress] -= totalAmount;

            if (platformFees > 0) {
                platformFeesCollectedInTokens[payment.tokenAddress] += platformFees;
            }
        }

        if (payment.receiveFundsOnChainId == block.chainid) {
            toOrganization.tokenBalances[payment.tokenAddress] += payment.amount;
            emit InvoicePaid(fromOrganizationId, payment.amount, payment.invoice_id, payment.receiveFundsOnChainId, payment.tokenAddress);
            return;
        }

        if (supportedPrimaryChainIds[payment.receiveFundsOnChainId]) {
            require(payment.receiver == toOrganization.withdrawalAddress, "INVALID_TO_ADDRESS");
            depositHyphen(
                payment.amount,
                payment.tokenAddress,
                paymentMethod,
                paymentData
            );
            emit InvoicePaid(fromOrganizationId, payment.amount, payment.invoice_id, payment.receiveFundsOnChainId, payment.tokenAddress);
            return;
        }

        // this would be processed by some hot wallet on other chain.
        IERC20(payment.tokenAddress).safeTransfer(crossChainTreasury, payment.amount);
        emit InvoiceApproved(toOrganizationId, payment.amount, payment.invoice_id, payment.receiveFundsOnChainId, payment.tokenAddress);

    }

    /******************************************************************************************************
    * Bulk Approve Invoice in ERC20 tokens.
    *******************************************************************************************************/
    function makeBulkPaymentInERC20(
        uint256 fromOrganizationId,
        uint256[] memory toOrganizationIds,
        bytes memory paymentMethod,
        bytes[] memory paymentData
    )
        external
    {

        for (uint256 i = 0; i < toOrganizationIds.length; i++) {
            makePaymentInERC20(
                fromOrganizationId,
                toOrganizationIds[i],
                paymentMethod,
                paymentData[i]
            );
        }

    }


    /******************************************************************************************************
    * Check if an organization is verified or not.
    *******************************************************************************************************/
    function isVerified(uint256 organization_id)
        view
        external
        returns(bool)
    {
        Organization storage organization = organizationsIdMap[organization_id];
        return organization.isVerified;
    }

    /******************************************************************************************************
    * Check if a wallet belongs to an organization.
    *******************************************************************************************************/
    function isOrganizationWallet(
        uint256 organization_id,
        address wallet
    )
        view
        external
        onlyOrganizationAdmins(organization_id)
        returns(bool)
    {
        Organization storage organization = organizationsIdMap[organization_id];
        return organization.addresses[wallet];
    }

    /******************************************************************************************************
    * Get organization's token or native balance.
    *******************************************************************************************************/
    function getBalance(uint256 organization_id, address tokenAddress)
        view
        external
        returns(uint256)
    {
        Organization storage organization = organizationsIdMap[organization_id];
        return tokenAddress == NATIVE
        ? organization.balance
        : organization.tokenBalances[tokenAddress];
    }

    /******************************************************************************************************
    * Get Platform's native or token balance.
    *******************************************************************************************************/
    function getPlatformBalance(address tokenAddress)
        view
        external
        returns(uint256)
    {
        return tokenAddress == NATIVE
        ? address(this).balance
        : IERC20(tokenAddress).balanceOf(address(this));
    }

    /******************************************************************************************************
    * Get organization details.
    *******************************************************************************************************/
    function getOrganizationFees(uint256 organization_id, uint256 chainId, address tokenAddress)
        view
        external
        returns(bool, uint256, uint256)
    {
        Organization storage organization = organizationsIdMap[organization_id];
        return (
            organization.isVerified,
            organization.platformFees[chainId],
            organization.platformFeesCap[tokenAddress]
        );
    }

    /******************************************************************************************************
    * Get organization withdrawal address.
    *******************************************************************************************************/

     function getWithdrawalAddress(uint256 organization_id)
        view
        external
        returns(address)
    {
        Organization storage organization = organizationsIdMap[organization_id];
        return (
            organization.withdrawalAddress
        );
    }

    /******************************************************************************************************
    * Para-swap: Swap and pay in a different token.
    *******************************************************************************************************/
    function swapAndPayInERC20(
        uint256 fromOrganizationId,
        uint256 toOrganizationId,
        address fromTokenAddress,
        address toTokenAddress,
        uint256 amount,
        bytes memory swapData,
        bytes memory paymentMethod,
        bytes memory paymentData
    )
        external
        onlyValidOrganizations(toOrganizationId)
        onlyOrganizationAdmins(fromOrganizationId)
    {
        require(fromOrganizationId != toOrganizationId, "ORGANIZATION_IDS_CAN_NOT_BE_SAME");
        require(supportedERC20Tokens[fromTokenAddress], "UNSUPPORTED_TOKEN");
        require(supportedERC20Tokens[toTokenAddress], "UNSUPPORTED_TOKEN");

        TempBalanceInfo memory balances;
        balances.initialFromToken = IERC20(fromTokenAddress).balanceOf(address(this));
        balances.initialToToken = IERC20(toTokenAddress).balanceOf(address(this));

        // approve and swap
        IERC20(fromTokenAddress).approve(address(paraSwapTokenTransferProxy), amount);
        (bool sent, ) = paraSwap.call(swapData);
        require(sent, "ERROR_SWAPPING");

        // get updated balances
        balances.updatedFromToken = IERC20(fromTokenAddress).balanceOf(address(this));
        balances.updatedToToken = IERC20(toTokenAddress).balanceOf(address(this));

        // get amount updated
        balances.transferredFromTokenAmount = balances.initialFromToken - balances.updatedFromToken;
        balances.transferredToTokenAmount = balances.updatedToToken - balances.initialToToken;
        require(balances.transferredToTokenAmount > 0, "INVALID_SWAP");

        // update organization balances
        Organization storage organization = organizationsIdMap[fromOrganizationId];
        organization.tokenBalances[fromTokenAddress] -= balances.transferredFromTokenAmount;
        organization.tokenBalances[toTokenAddress] += balances.transferredToTokenAmount;

        makePaymentInERC20(
            fromOrganizationId,
            toOrganizationId,
            paymentMethod,
            paymentData
        );
    }

    /******************************************************************************************************
    * Hyphen Deposit. This would trigger a cross-chain transaction.
    *******************************************************************************************************/
    function depositHyphen(
       uint256 amount,
       address tokenAddress,
       bytes memory paymentMethod,
       bytes memory paymentData
    )
        internal
    {
        IERC20(tokenAddress).approve(address(hyphenLiquidityPool), amount);
        bytes memory data = bytes.concat(paymentMethod, paymentData);
        (bool sent, ) = hyphenLiquidityPool.call(data);
        require(sent, "HYPHEN_DEPOSIT_FAILED");
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct Organization {
    string id;
    mapping(address => bool) addresses;
    mapping(address => uint256) tokenBalances;
    mapping(address => uint256) activateAfter;
    uint256 balance;
    mapping(uint256 => uint256) platformFees; // chain id to platform fees % on that chain.
    mapping(address => uint256) platformFeesCap; // token address to fees cap in token's quantity.
    address withdrawalAddress;
    bool isVerified;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct PaymentInERC20 {
    uint256 receiveFundsOnChainId;
    address tokenAddress;
    address receiver;
    uint256 amount;
    string invoice_id;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct TempBalanceInfo {
    uint256 initialFromToken;
    uint256 initialToToken;
    uint256 updatedFromToken;
    uint256 updatedToToken;
    uint256 transferredFromTokenAmount;
    uint256 transferredToTokenAmount;
}