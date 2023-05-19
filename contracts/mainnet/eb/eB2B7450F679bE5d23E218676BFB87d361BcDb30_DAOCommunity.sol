// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
pragma solidity 0.8.10;

import "./IDAOCommunity.sol";
import "./IDAO.sol";
import "./DAOStandart.sol";
import "../extension/ExtensionSelector.sol";

contract DAOCommunity is DAOStandart, ExtensionSelector, IDAO, IDAOCommunity {
    bytes32 public constant DAO_COMMUNITY_ROLE =
        keccak256("DAO_COMMUNITY_ROLE");
    bytes32 public constant DAO_ADMIN_ROLE = keccak256("DAO_ADMIN_ROLE");

    constructor(
        address voteToken,
        uint256 minimumQuorumPercent,
        uint256 debatingPeriodDuration,
        bytes4[] memory selectors,
        address DAOAdmin
    ) DAOStandart(voteToken, minimumQuorumPercent, debatingPeriodDuration) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DAO_ADMIN_ROLE, DAOAdmin);
        _setupRole(DAO_COMMUNITY_ROLE, address(this));

        uint256 len = selectors.length;
        for (uint256 i; i < len; i++) {
            _addSelector(selectors[i]);
        }
    }

    /**
     * @dev add a new selector.
     */
    function addSelector(bytes4 selector) external onlyRole(DAO_ADMIN_ROLE) {
        _addSelector(selector);
        emit Selector(selector, true);
    }

    /**
     * @dev remove a selector.
     */
    function removeSelector(bytes4 selector) external onlyRole(DAO_ADMIN_ROLE) {
        _removeSelector(selector);
        emit Selector(selector, false);
    }

    /**
     * @dev set the duration of the vote
     */
    function changePeriodDuration(uint256 debatingPeriodDuration)
        external
        onlyRole(DAO_COMMUNITY_ROLE)
    {
        require(
            debatingPeriodDuration <= 30 days &&
                debatingPeriodDuration >= 7 days,
            "Invalid debatingPeriodDuration"
        );
        _setPeriodDuration(debatingPeriodDuration);
    }

    /**
     * @dev set the minimum percentage of votes from the total number
     * of tokens to consider the vote successful
     */
    function changeMinimumQuorumPercent(uint256 minimumQuorum)
        external
        onlyRole(DAO_ADMIN_ROLE)
    {
        _setMinimumQuorumPercent(minimumQuorum);
    }

    /**
     * @dev replenishment of the user's balance
     */
    function deposit(uint256 amount) external {
        _deposit(amount);
    }

    /**
     * @dev withdrawal of the user's balance
     */
    function withdraw() external {
        _withdraw();
    }

    /**
     * @dev adding a new proposal
     * @param recipient the address of the contract on which the signature will be called
     * @param callData signature function
     * @param startTime voting start time
     */
    function addProposal(
        address recipient,
        bytes calldata callData,
        uint256 startTime
    ) external isValidSelector(bytes4(callData)) {
        _addProposal(recipient, callData, startTime);
    }

    /**
     * @dev voting for the proposal
     * @param proposalId id of voting
     * @param supportAgainst vote for (true) or against (false)
     */
    function vote(uint256 proposalId, bool supportAgainst) external {
        _vote(proposalId, supportAgainst);
    }

    /**
     * @dev end the vote
     * @param proposalId id of voting
     */
    function finishVote(uint256 proposalId) external {
        _finishVote(proposalId);
    }

    function isValidSignature(bytes4 selector) external view returns (bool) {
        return _isValidSelector(selector);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IDAOCommunity).interfaceId ||
            interfaceId == type(IDAO).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IDAOStandart.sol";

abstract contract DAOStandart is IDAOStandart, AccessControl {
    using SafeERC20 for IERC20;

    // required for working with percentages.
    uint256 constant PRECISION_E6 = 1e6;

    // number of votes must be more than minimum quorum
    uint256 private _minimumQuorumPercent;
    // debating period duration
    uint256 private _debatingPeriodDuration;
    // number of proposals
    uint256 private _nextProposalID;
    // voting token
    address private _voteToken;
    // stores the user's voting status (id => account => status)
    mapping(uint256 => mapping(address => bool)) internal _voteStatus;
    // stores voting data (id => Proposal)
    mapping(uint256 => Proposal) internal _proposals;
    // stores user data
    mapping(address => User) internal _users;

    constructor(
        address voteToken,
        uint256 minimumQuorumPercent,
        uint256 debatingPeriodDuration
    ) {
        _voteToken = voteToken;
        _minimumQuorumPercent = minimumQuorumPercent;
        _debatingPeriodDuration = debatingPeriodDuration;
    }

    /**
     * @dev returns the main parameters
     */
    function getDAOParam()
        external
        view
        returns (
            uint256 minimumQuorumPercent,
            uint256 debatingPeriodDuration,
            uint256 nextProposalID,
            address voteToken
        )
    {
        return (
            _minimumQuorumPercent,
            _debatingPeriodDuration,
            _nextProposalID,
            _voteToken
        );
    }

    /**
     * @dev returns the user's status in a specific voting ID
     * @return true - user has already voted
     *         false - user has not voted yet
     */
    function getVoteStatus(
        uint256 proposalId,
        address account
    ) external view returns (bool) {
        return _voteStatus[proposalId][account];
    }

    /**
     * @dev returns inforamation about the proposal by ID
     * @return struct Proposal
     */
    function getProposal(
        uint256 proposalId
    ) external view returns (Proposal memory) {
        return _proposals[proposalId];
    }

    /**
     * @dev returns the user's balance
     * @param account user address
     * @return balance
     */
    function getBalance(address account) external view returns (uint256) {
        return _users[account].balance;
    }

    /**
     * @dev returns the timestamp when the balance will be unlocked
     * @param account user address
     * @return unlock timeStamp
     */
    function getUnlockBalance(address account) external view returns (uint256) {
        return _users[account].unlockBalance;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IDAOStandart).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev replenishment of the user's balance
     */
    function _deposit(uint256 amount) internal virtual {
        if (amount <= 0) {
            revert DAOAmountZero();
        }

        // checking for commission inside the token
        uint256 balanceBefore = IERC20(_voteToken).balanceOf(address(this));
        IERC20(_voteToken).safeTransferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(_voteToken).balanceOf(address(this));
        uint256 newAmount = balanceAfter - balanceBefore;

        _users[msg.sender].balance += newAmount;

        emit Deposit(msg.sender, newAmount);
    }

    /**
     * @dev withdrawal of the user's balance
     */
    function _withdraw() internal virtual {
        User storage user = _users[msg.sender];

        if (user.unlockBalance > block.timestamp) {
            revert DAOFrozenBalance(user.unlockBalance);
        }
        uint256 amount = _users[msg.sender].balance;
        if (amount == 0) {
            revert ZeroAmount();
        }
        _users[msg.sender].balance = 0;
        IERC20(_voteToken).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev adding a new proposal
     * @param recipient the address of the contract on which the signature will be called
     * @param callData signature function
     * @param startTime voting start time
     */
    function _addProposal(
        address recipient,
        bytes calldata callData,
        uint256 startTime
    ) internal virtual {
        bytes4 selector = bytes4(callData);

        if (startTime < block.timestamp) {
            revert DAOInvalidStartTime();
        }
        Proposal storage proposal = _proposals[_nextProposalID];

        proposal.startTime = startTime;
        proposal.endTimeOfVoting = startTime + _debatingPeriodDuration;
        proposal.signature = callData;
        proposal.recipient = recipient;
        proposal.votingStatus = VotingStatus.CREATE;

        emit ProposalAdded(
            _nextProposalID,
            startTime,
            proposal.endTimeOfVoting,
            selector
        );

        _nextProposalID++;
    }

    /**
     * @dev adding a new poll
     * @param startTime voting start time
     */
    function _addPoll(uint256 startTime) internal virtual {
        if (startTime < block.timestamp) {
            revert DAOInvalidStartTime();
        }

        Proposal storage proposal = _proposals[_nextProposalID];
        proposal.startTime = startTime;
        proposal.endTimeOfVoting = startTime + _debatingPeriodDuration;
        proposal.votingStatus = VotingStatus.CREATE;

        emit AddPoll(_nextProposalID, startTime, proposal.endTimeOfVoting);

        _nextProposalID++;
    }

    /**
     * @dev voting for the proposal
     * @param proposalId id of voting
     * @param supportAgainst vote for (true) or against (false)
     */
    function _vote(uint256 proposalId, bool supportAgainst) internal virtual {
        require(
            _voteStatus[proposalId][msg.sender] != true,
            "DAO: you have already voted"
        );

        Proposal storage proposal = _proposals[proposalId];
        User storage user = _users[msg.sender];

        if (
            block.timestamp >= proposal.endTimeOfVoting ||
            block.timestamp < proposal.startTime ||
            proposal.votingStatus != VotingStatus.CREATE
        ) {
            revert DAOImpossibleVote();
        }

        uint256 powerOfVoting = user.balance;

        if (supportAgainst) {
            proposal.votedFor += powerOfVoting;
        } else {
            proposal.votedAgainst += powerOfVoting;
        }

        _voteStatus[proposalId][msg.sender] = true;

        if (user.unlockBalance < proposal.endTimeOfVoting) {
            user.unlockBalance = proposal.endTimeOfVoting;
        }

        emit Vote(msg.sender, proposalId, supportAgainst, powerOfVoting);
    }

    /**
     * @dev end the vote
     * @param proposalId id of voting
     */
    function _finishVote(uint256 proposalId) internal virtual {
        Proposal storage proposal = _proposals[proposalId];
        _finishValidation(proposal);
        require(
            proposal.signature.length != 0,
            "It is necessary to call the <finishPoll>"
        );

        if (
            proposal.votedFor + proposal.votedAgainst >=
            (_minimumQuorumPercent * IERC20(_voteToken).totalSupply()) /
                (100 * PRECISION_E6)
        ) {
            if (proposal.votedFor > proposal.votedAgainst) {
                (bool success, ) = proposal.recipient.call{value: 0}(
                    proposal.signature
                );
                proposal.votingStatus = !success
                    ? proposal.votingStatus = VotingStatus.MISTAKE
                    : VotingStatus.SUCCESSFULLY;
            } else {
                proposal.votingStatus = VotingStatus.FAILURE;
            }
        } else {
            proposal.votingStatus = VotingStatus.FAILURE;
        }
        emit Finish(proposalId, proposal.votingStatus);
    }

    /**
     * @dev end the vote
     * @param proposalId id of voting
     */
    function _finishPoll(uint256 proposalId) internal virtual {
        Proposal storage proposal = _proposals[proposalId];

        _finishValidation(proposal);
        require(
            proposal.signature.length == 0,
            "It is necessary to call the <finishVote>"
        );

        if (
            proposal.votedFor + proposal.votedAgainst >=
            (_minimumQuorumPercent * IERC20(_voteToken).totalSupply()) /
                (100 * PRECISION_E6)
        ) {
            if (proposal.votedFor > proposal.votedAgainst) {
                proposal.votingStatus = VotingStatus.SUCCESSFULLY;
            } else {
                proposal.votingStatus = VotingStatus.FAILURE;
            }
        } else {
            proposal.votingStatus = VotingStatus.FAILURE;
        }
        emit Finish(proposalId, proposal.votingStatus);
    }

    function _finishValidation(Proposal memory proposal) internal view {
        require(
            proposal.endTimeOfVoting <= block.timestamp,
            "DAO: It is impossible to complete now"
        );

        if (proposal.votingStatus != VotingStatus.CREATE) {
            revert DAOVotingEnded();
        }
    }

    /// @dev change the duration of new votes
    function _setPeriodDuration(uint256 debatingPeriodDuration) internal {
        _debatingPeriodDuration = debatingPeriodDuration;
        emit ChangePeriodDuration(debatingPeriodDuration);
    }

    /// @dev change the minimum allowable percentage
    /// @param minimumQuorum specify taking into account precision
    function _setMinimumQuorumPercent(uint256 minimumQuorum) internal {
        _minimumQuorumPercent = minimumQuorum;
        emit ChangeMinimumQuorumPercent(minimumQuorum);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IDAO {
    /**
     * @dev add a new selector.
     */
    function addSelector(bytes4 selector) external;

    /**
     * @dev remove a selector.
     */
    function removeSelector(bytes4 selector) external;

    /**
     * @dev replenishment of the user's balance
     */
    function deposit(uint256 amount) external;

    /**
     * @dev withdrawal of the user's balance
     */
    function withdraw() external;

    /**
     * @dev adding a new proposal
     * @param recipient the address of the contract on which the signature will be called
     * @param callData signature function
     * @param startTime voting start time
     */
    function addProposal(
        address recipient,
        bytes calldata callData,
        uint256 startTime
    ) external;

    /**
     * @dev voting for the proposal
     * @param proposalId id of voting
     * @param supportAgainst vote for (true) or against (false)
     */
    function vote(uint256 proposalId, bool supportAgainst) external;

    /**
     * @dev end the vote
     * @param proposalId id of voting
     */
    function finishVote(uint256 proposalId) external;

    function isValidSignature(bytes4 selector) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IDAOCommunity {
    /**
     * @dev set the duration of the vote
     */
    function changePeriodDuration(uint256 debatingPeriodDuration) external;

    /**
     * @dev set the minimum percentage of votes from the total number
     * of tokens to consider the vote successful
     */
    function changeMinimumQuorumPercent(uint256 minimumQuorum) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IDAOStandart {
    event ProposalAdded(
        uint256 proposalId,
        uint256 startTime,
        uint256 endTimeOfVoting,
        bytes4 selector
    );
    event Finish(uint256 proposalId, VotingStatus votingStatus);
    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);
    event Vote(
        address account,
        uint256 proposalId,
        bool supportAgainst,
        uint256 powerOfVoting
    );
    event AddPoll(
        uint256 proposalId,
        uint256 startTime,
        uint256 endTimeOfVoting
    );
    event ChangePeriodDuration(uint256 debatingPeriodDuration);
    event ChangeMinimumQuorumPercent(uint256 minimumQuorum);
    enum VotingStatus {
        NOT_CREATE,
        CREATE,
        SUCCESSFULLY,
        FAILURE,
        MISTAKE
    }

    struct Proposal {
        // proposal may execute only after voting ended
        uint256 endTimeOfVoting;
        // voting status
        VotingStatus votingStatus;
        // number of votes "For"
        uint256 votedFor;
        // number of votes "Against"
        uint256 votedAgainst;
        // a plain text description of the proposal
        bytes signature;
        // the address of the contract on which the byte code will be executed
        address recipient;
        // voting start time
        uint256 startTime;
    }

    struct User {
        // Deposit balance
        uint256 balance;
        //Time to unlock the balance
        uint256 unlockBalance;
    }

    error DAOAmountZero();
    error DAOInsufficientFunds(uint256 balance);
    error DAOFrozenBalance(uint256 unlockTime);
    error DAOVotingEnded();
    error DAOImpossibleVote();
    error DAOArrayLen();
    error DAOInvalidStartTime();
    error ZeroAmount();

    function getDAOParam()
        external
        view
        returns (
            uint256 minimumQuorumPercent,
            uint256 debatingPeriodDuration,
            uint256 nextProposalID,
            address voteToken
        );

    function getVoteStatus(uint256 proposalId, address account)
        external
        view
        returns (bool);

    function getProposal(uint256 proposalId)
        external
        view
        returns (Proposal memory);

    function getBalance(address account) external view returns (uint256);

    function getUnlockBalance(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

abstract contract ExtensionSelector {
    event Selector(bytes4 selector, bool status);
    error InvalidSelector(bytes4 selector);

    mapping(bytes4 => bool) private _selectors;

    modifier isValidSelector(bytes4 selector) {
        if (!_isValidSelector(selector)) {
            revert InvalidSelector(selector);
        }
        _;
    }

    function _addSelector(bytes4 selector) internal {
        _selectors[selector] = true;
    }

    function _removeSelector(bytes4 selector) internal {
        _selectors[selector] = false;
    }

    function _isValidSelector(bytes4 selector) internal view returns (bool) {
        return (_selectors[selector]);
    }
}