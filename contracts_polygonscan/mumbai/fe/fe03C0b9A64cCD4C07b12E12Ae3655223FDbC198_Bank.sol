// SPDX-License-Identifier: MIT

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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Referral.sol";

// import "hardhat/console.sol";

/// @title BetSwirl's games bank
/// @author Romuald Hog
/// @dev Basis point are used for all rates
contract Bank is AccessControl, Referral {
    using SafeERC20 for IERC20;

    struct Token {
        bool allowed;
        uint256 minBetTxValue; // Minimum bet transaction value needed to cover the ChainLink's VRF cost
        HouseEdgeSplit houseEdgeSplit;
        uint256 balanceReference;
        BalanceOverflow balanceOverflow;
    }
    struct TokenMetadata {
        uint8 decimals;
        address tokenAddress;
        string name;
        string symbol;
        Token token;
    }
    struct HouseEdgeSplit {
        uint16 dividend;
        uint16 referral;
        uint16 treasury;
        uint16 team;
        uint256 dividendAmount;
        uint256 referralAmount;
        uint256 treasuryAmount;
        uint256 teamAmount;
    }
    struct BalanceOverflow {
        uint16 thresholdRate;
        uint16 toTreasury;
    }

    uint8 private constant _BALANCE_RISK_RATE = 200;
    uint16 private _tokensCount;
    address payable public immutable treasury; // multi-sig
    address payable public teamWallet; // payment splitter
    bytes32 public constant GAME_ROLE = keccak256("GAME_ROLE");
    mapping(address => Token) private _tokens;
    mapping(uint16 => address) private _tokensList;

    event SetTeamWallet(address teamWallet);
    event AddToken(address token);
    event SetAllowedToken(address indexed token, bool allowed);
    event SetTokenHouseEdgeSplit(
        address token,
        uint16 dividend,
        uint16 referral,
        uint16 treasury,
        uint16 team
    );
    event HouseEdgeDistribution(
        address token,
        uint256 treasuryAmount,
        uint256 teamAmount
    );
    event SetBalanceOverflow(
        address token,
        uint16 thresholdRate,
        uint16 toTreasury
    );
    event SetTokenMinBetTxValue(address indexed token, uint256 minBetTxValue);
    event BankOverflowTransfer(
        address indexed token,
        uint256 amountToTreasury,
        uint256 balanceReference
    );
    event SetBalanceReference(address token, uint256 balanceReference);
    event BetCollect(address indexed token, uint256 amount);
    event BetPayout(address indexed token, uint256 amount);
    event AllocateHouseEdgeAmount(
        address indexed token,
        uint256 dividend,
        uint256 referral,
        uint256 treasury,
        uint256 team
    );

    /// Token already added
    /// @param token is provided by caller.
    error TokenExists(address token);
    /// House edge shares sum should be 10000BP.
    /// @param splitSum is the sum of the shares.
    error WrongHouseEdgeSplit(uint16 splitSum);
    /// Balance Overflow threshold should be positive and toTreasory should be basis points.
    error WrongBalanceOverflow();
    /// Payout amount should be positive and fees should be less than amount.
    error WrongPayout();
    /// Token balance haven't reached the overflow
    /// @param token is provided by caller.
    error NoBalanceOverflow(address token);

    constructor(address payable _treasury, address payable _teamWallet) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // Should then transfered to the timelock
        treasury = _treasury;
        teamWallet = _teamWallet;
    }

    receive() external payable {}

    function _safeTransfer(
        address payable user,
        address token,
        uint256 amount
    ) private {
        if (_isNativeToken(token)) {
            user.transfer(amount);
        } else {
            IERC20(token).safeTransfer(user, amount);
        }
    }

    function _setBalanceReference(address token, uint256 newReference) private {
        _tokens[token].balanceReference = newReference;
        emit SetBalanceReference(token, newReference);
    }

    function _isNativeToken(address token) private pure returns (bool) {
        return token == address(0);
    }

    /// Funds the bank of token amount
    function deposit(address token, uint256 amount)
        external
        payable
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 balance = getBalance(token);
        if (_isNativeToken(token)) {
            _setBalanceReference(token, balance);
        } else {
            _setBalanceReference(token, balance + amount);
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    /// Get the funds out - only used for bank contract migration
    function withdraw(address token, uint80 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setBalanceReference(token, getBalance(token) - amount);
        _safeTransfer(payable(msg.sender), token, amount);
    }

    function setTeamWallet(address payable _teamWallet)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        teamWallet = _teamWallet;
        emit SetTeamWallet(teamWallet);
    }

    function addToken(address token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint16 tokensCount = _tokensCount;
        if (tokensCount > 0) {
            for (uint16 i; i < tokensCount; i++) {
                if (_tokensList[i] == token) {
                    revert TokenExists(token);
                }
            }
        }
        _tokensList[_tokensCount] = token;
        _tokensCount += 1;
        emit AddToken(token);
    }

    function setAllowedToken(address token, bool allowed)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _tokens[token].allowed = allowed;
        emit SetAllowedToken(token, allowed);
    }

    function setHouseEdgeSplit(
        address token,
        uint16 dividend,
        uint16 referral,
        uint16 _treasury,
        uint16 team
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint16 splitSum = dividend + team + _treasury + referral;
        if (splitSum != 10000) {
            revert WrongHouseEdgeSplit(splitSum);
        }

        HouseEdgeSplit storage tokenHouseEdge = _tokens[token].houseEdgeSplit;
        tokenHouseEdge.dividend = dividend;
        tokenHouseEdge.referral = referral;
        tokenHouseEdge.treasury = _treasury;
        tokenHouseEdge.team = team;

        emit SetTokenHouseEdgeSplit(token, dividend, referral, _treasury, team);
    }

    function setBalanceOverflow(
        address token,
        uint16 thresholdRate,
        uint16 toTreasury
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (thresholdRate > 10000 || toTreasury > 10000) {
            revert WrongBalanceOverflow();
        }

        _tokens[token].balanceOverflow = BalanceOverflow(
            thresholdRate,
            toTreasury
        );
        emit SetBalanceOverflow(token, thresholdRate, toTreasury);
    }

    function setTokenMinBetTxValue(address token, uint256 tokenMinBetTxValue)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _tokens[token].minBetTxValue = tokenMinBetTxValue;
        emit SetTokenMinBetTxValue(token, tokenMinBetTxValue);
    }

    function distributeTokenHouseEdgeSplit(address token)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        HouseEdgeSplit storage tokenHouseEdge = _tokens[token].houseEdgeSplit;
        uint256 treasuryAmount = tokenHouseEdge.treasuryAmount;
        uint256 teamAmount = tokenHouseEdge.teamAmount;
        tokenHouseEdge.treasuryAmount = 0;
        tokenHouseEdge.teamAmount = 0;
        _safeTransfer(treasury, token, treasuryAmount);
        _safeTransfer(teamWallet, token, teamAmount);
        emit HouseEdgeDistribution(token, treasuryAmount, teamAmount);
    }

    /// Transfer the bank overflow to treasury
    function bankOverflowTransfer(address _token)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 balance = getBalance(_token);
        Token storage token = _tokens[_token];
        BalanceOverflow memory balanceOverflow = token.balanceOverflow;
        uint256 balanceReference = token.balanceReference;
        uint256 overflow = (balanceReference +
            ((balance * balanceOverflow.thresholdRate) / 10000));
        if (balance < overflow) {
            revert NoBalanceOverflow(_token);
        }

        uint256 amountToTreasury = (((balance - balanceReference) *
            balanceOverflow.toTreasury) / 10000);
        token.balanceReference = balance - amountToTreasury;

        _safeTransfer(treasury, _token, amountToTreasury);
        emit BankOverflowTransfer(
            _token,
            amountToTreasury,
            token.balanceReference
        );
    }

    function setReferral(
        uint24 secondsUntilInactive,
        bool onlyRewardActiveReferrers,
        uint16[3] calldata levelRate,
        uint16[6] calldata refereeBonusRateMap
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setReferral(
            secondsUntilInactive,
            onlyRewardActiveReferrers,
            levelRate,
            refereeBonusRateMap
        );
    }

    function addReferrer(address user, address referrer)
        external
        onlyRole(GAME_ROLE)
    {
        _addReferrer(user, referrer);
    }

    function updateReferrerActivity(address user) external onlyRole(GAME_ROLE) {
        _updateReferrerActivity(user);
    }

    function payout(
        address payable user,
        address token,
        uint256 amount,
        uint256 fees
    ) external onlyRole(GAME_ROLE) {
        if (amount + fees > (getBalance(token) * _BALANCE_RISK_RATE) / 10000) {
            revert WrongPayout();
        }

        // Distribute the house edge
        HouseEdgeSplit storage tokenHouseEdge = _tokens[token].houseEdgeSplit;
        uint256 referralAllocation = (fees * tokenHouseEdge.referral) / 10000;
        uint256 referralAmount = _payReferral(user, token, referralAllocation);
        referralAllocation -= referralAmount;
        
        uint256 referralAllocationRestPerSplit = (referralAllocation -
            (referralAllocation % 3)) / 3;
        uint256 dividendAmount = ((fees * tokenHouseEdge.dividend) / 10000) +
            referralAllocationRestPerSplit;
        uint256 treasuryAmount = ((fees * tokenHouseEdge.treasury) / 10000) +
            referralAllocationRestPerSplit;
        uint256 teamAmount = ((fees * tokenHouseEdge.team) / 10000) +
            referralAllocationRestPerSplit;
        tokenHouseEdge.referralAmount += referralAmount;
        tokenHouseEdge.dividendAmount += dividendAmount;
        tokenHouseEdge.treasuryAmount += treasuryAmount;
        tokenHouseEdge.teamAmount += teamAmount;
        emit AllocateHouseEdgeAmount(
            token,
            dividendAmount,
            referralAmount,
            treasuryAmount,
            teamAmount
        );

        // Pay the user
        uint256 profit = amount - fees;
        _safeTransfer(user, token, profit);
        emit BetPayout(token, profit);
    }

    function cashIn(address token, uint256 amount)
        external
        payable
        onlyRole(GAME_ROLE)
    {
        if (_isNativeToken(token)) {
            amount = msg.value;
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }

        emit BetCollect(token, amount);
    }

    /// @dev For the front-end
    function getTokens() external view returns (TokenMetadata[] memory) {
        uint16 tokensCount = _tokensCount;
        TokenMetadata[] memory tokens = new TokenMetadata[](tokensCount);
        for (uint16 i; i < tokensCount; i++) {
            address tokenAddress = _tokensList[i];
            Token memory token = _tokens[tokenAddress];
            if (_isNativeToken(tokenAddress)) {
                tokens[i] = TokenMetadata({
                    decimals: 18,
                    tokenAddress: tokenAddress,
                    name: "ETH",
                    symbol: "ETH",
                    token: token
                });
            } else {
                IERC20Metadata erc20Metadata = IERC20Metadata(tokenAddress);
                tokens[i] = TokenMetadata({
                    decimals: erc20Metadata.decimals(),
                    tokenAddress: tokenAddress,
                    name: erc20Metadata.name(),
                    symbol: erc20Metadata.symbol(),
                    token: token
                });
            }
        }
        return tokens;
    }

    /// @dev multiplier should be at least 10000
    function getMaxBetAmount(address token, uint256 multiplier)
        external
        view
        returns (uint256)
    {
        return (getBalance(token) * _BALANCE_RISK_RATE) / multiplier;
    }

    function getTokenMinBetTxValue(address token)
        external
        view
        returns (uint256)
    {
        return _tokens[token].minBetTxValue;
    }

    function isAllowedToken(address token) external view returns (bool) {
        return _tokens[token].allowed;
    }

    function getBalance(address token) public view returns (uint256) {
        uint256 balance;
        if (_isNativeToken(token)) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
        HouseEdgeSplit memory tokenHouseEdgeSplit = _tokens[token]
            .houseEdgeSplit;
        return
            balance -
            tokenHouseEdgeSplit.dividendAmount -
            tokenHouseEdgeSplit.referralAmount -
            tokenHouseEdgeSplit.treasuryAmount -
            tokenHouseEdgeSplit.teamAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// import "hardhat/console.sol";

/// @title Multi-level referral
/// @author Thundercore, customized by Romuald Hog
/// @dev Basis point are used for all rates
abstract contract Referral {
    using SafeERC20 for IERC20;

    /**
     * @dev The struct of account information
     * @param referrer The referrer addresss
     * @param referredCount The total referral amount of an address
     * @param lastActiveTimestamp The last active timestamp of an address
     */
    struct Account {
        address referrer;
        uint24 referredCount;
        uint32 lastActiveTimestamp;
    }

    /**
     * @dev The struct of referee amount to bonus rate
     * @param lowerBound The minial referee amount
     * @param rate The bonus rate for each referee amount
     */
    struct RefereeBonusRate {
        uint16 lowerBound;
        uint16 rate;
    }

    uint16[3] public levelRate;
    uint24 public secondsUntilInactive;
    bool public onlyRewardActiveReferrers;
    RefereeBonusRate[3] public refereeBonusRateMap;
    mapping(address => mapping(address => uint256)) private _credits;
    mapping(address => Account) private _accounts;

    event SetReferral(
        uint24 secondsUntilInactive,
        bool onlyRewardActiveReferrers,
        uint16[3] levelRate
    );
    event SetReferreeBonusRate(uint16 lowerBound, uint16 rate);
    event RegisteredReferer(address indexed referee, address indexed referrer);
    event SetLastActiveTimestamp(address indexed referrer, uint32 lastActiveTimestamp);
    event AddReferralCredit(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint16 indexed level
    );
    event WithdrawnReferralCredit(address indexed payee, address indexed token, uint256 amount);

    /// Referral level should be at least one, length not exceed 3, and total not exceed 100%
    error WrongLevelRate();
    /// One of referee bonus rate exceeds 100%
    /// @param rate The referee bonus rate
    error WrongRefereeBonusRate(uint16 rate);

    /**
     * @dev Given a user referred count to calc in which rate period
     * @param referredCount The number of referrees
     */
    function _getRefereeBonusRate(uint24 referredCount) private view returns (uint16) {
        uint16 rate = refereeBonusRateMap[0].rate;
        uint256 refereeBonusRateMapLength = refereeBonusRateMap.length;
        for (uint8 i = 1; i < refereeBonusRateMapLength; i++) {
            RefereeBonusRate memory refereeBonusRate = refereeBonusRateMap[i];
            if (referredCount < refereeBonusRate.lowerBound) {
                break;
            }
            rate = refereeBonusRate.rate;
        }
        return rate;
    }

    function _isCircularReference(address referrer, address referee)
        private
        view
        returns (bool)
    {
        address parent = referrer;
        uint256 levelRateLength = levelRate.length;
        for (uint8 i; i < levelRateLength; i++) {
            if (parent == address(0)) {
                break;
            }

            if (parent == referee) {
                return true;
            }

            parent = _accounts[parent].referrer;
        }

        return false;
    }

    /**
     * @param _secondsUntilInactive The seconds that a user does not update will be seen as inactive.
     * @param _onlyRewardActiveReferrers The flag to enable not paying to inactive uplines.
     * @param _levelRate The bonus rate for each level. The max depth is 3.
     * @param _refereeBonusRateMap The bonus rate mapping to each referree amount. The max depth is 3.
     * The map should be pass as [<lower amount>, <rate>, ....]. For example, you should pass [1, 2500, 5, 5000, 10, 10000].
     *
     *  25%     50%     100%
     *   | ----- | ----- |----->
     *  1ppl    5ppl    10ppl
     *
     * @notice refereeBonusRateMap's lower amount should be ascending
     */
    function _setReferral(
        uint24 _secondsUntilInactive,
        bool _onlyRewardActiveReferrers,
        uint16[3] calldata _levelRate,
        uint16[6] calldata _refereeBonusRateMap
    ) internal {
        uint256 levelRateTotal;
        uint256 levelRateLength = _levelRate.length;
        for (uint8 i; i < levelRateLength; i++) {
            levelRateTotal += _levelRate[i];
        }
        if (
            levelRateTotal > 10000
        ) {
            revert WrongLevelRate();
        }

        secondsUntilInactive = _secondsUntilInactive;
        onlyRewardActiveReferrers = _onlyRewardActiveReferrers;
        levelRate = _levelRate;

        emit SetReferral(
            secondsUntilInactive,
            onlyRewardActiveReferrers,
            levelRate
        );

        uint8 j;
        uint256 refereeBonusRateMapLength = _refereeBonusRateMap.length;
        for (uint8 i; i < refereeBonusRateMapLength; i += 2) {
            uint16 refereeBonusLowerBound = _refereeBonusRateMap[i];
            uint16 refereeBonusRate = _refereeBonusRateMap[i + 1];
            if (refereeBonusRate > 10000) {
                revert WrongRefereeBonusRate(refereeBonusRate);
            }
            refereeBonusRateMap[j] = RefereeBonusRate(
                refereeBonusLowerBound,
                refereeBonusRate
            );
            emit SetReferreeBonusRate(refereeBonusLowerBound, refereeBonusRate);
            j++;
        }
    }

    /**
     * @dev Add an address as referrer
     * @param user The address of the user
     * @param referrer The address would set as referrer of user
     */
    function _addReferrer(address user, address referrer) internal {
        if (referrer == address(0)) {
            // Referrer cannot be 0x0 address
            return;
        } else if (_isCircularReference(referrer, user)) {
            // Referee cannot be one of referrer uplines
            return;
        } else if (_accounts[user].referrer != address(0)) {
            // Address have been registered upline
            return;
        }

        Account storage userAccount = _accounts[user];
        Account storage parentAccount = _accounts[referrer];

        userAccount.referrer = referrer;
        userAccount.lastActiveTimestamp = uint32(block.timestamp);
        parentAccount.referredCount += 1;

        emit RegisteredReferer(user, referrer);
    }

    /**
     * @dev This will calc and pay referral to uplines instantly
     * @param user The user to pay
     * @param token The token to pay
     * @param amount The number tokens will be calculated in referral process
     */
    function _payReferral(
        address user,
        address token,
        uint256 amount
    ) internal returns (uint256) {
        uint256 totalReferral;
        Account memory userAccount = _accounts[user];

        if (userAccount.referrer != address(0)) {
            uint256 levelRateLength = levelRate.length;
            for (uint8 i; i < levelRateLength; i++) {
                address parent = userAccount.referrer;
                Account memory parentAccount = _accounts[parent];

                if (parent == address(0)) {
                    break;
                }

                if (
                    !onlyRewardActiveReferrers ||
                    (parentAccount.lastActiveTimestamp + secondsUntilInactive >=
                        block.timestamp)
                ) {
                    uint256 credit = (((amount * levelRate[i]) / 10000) *
                        _getRefereeBonusRate(parentAccount.referredCount)) /
                        10000;
                    totalReferral += credit;

                    _credits[parent][token] += credit;

                    emit AddReferralCredit(parent, token, credit, i + 1);
                }

                userAccount = parentAccount;
            }
        }
        return totalReferral;
    }

    /**
     * @param user The address would like to update active time
     */
    function _updateReferrerActivity(address user) internal {
        Account storage userAccount = _accounts[user];
        if (userAccount.referredCount > 0) {
            uint32 lastActiveTimestamp = uint32(block.timestamp);
            userAccount.lastActiveTimestamp = lastActiveTimestamp;
            emit SetLastActiveTimestamp(user, lastActiveTimestamp);
        }
    }

    function withdrawReferralCredits(address token) external {
        address payable payee = payable(msg.sender);
        uint256 credit = _credits[payee][token];
        if (credit > 0) {
            _credits[payee][token] = 0;

            if (token == address(0)) {
                payee.transfer(credit);
            } else {
                IERC20(token).safeTransfer(payee, credit);
            }

            emit WithdrawnReferralCredit(payee, token, credit);
        }
    }

    /**
     * @dev Utils function for check whether an address has the referrer
     */
    function hasReferrer(address user) external view returns (bool) {
        return _accounts[user].referrer != address(0);
    }

    function referralCreditOf(address payee, address token)
        external
        view
        returns (uint256)
    {
        return _credits[payee][token];
    }

    function getReferralAccount(address user) external view returns (Account memory) {
        return _accounts[user];
    }
}

