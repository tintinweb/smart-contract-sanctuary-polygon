/**
 *Submitted for verification at polygonscan.com on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///////////////////////////////////////////////////////////////////////////
//     __/|      
//  __////  /|   This smart contract is part of Mover infrastructure
// |// //_///    https://viamover.com
//    |_/ //     [email protected]over.com
//       |/
///////////////////////////////////////////////////////////////////////////

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


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}


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
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
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
        _checkRole(role, _msgSender());
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
    uint256[49] private __gap;
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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


// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
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


// Interface to represent asset pool interactions
interface IAssetPoolV3 {
    function getBaseAsset() external view returns(address);

    // functions callable by HolyHand transfer proxy
    function depositOnBehalf(address beneficiary, uint256 amount) external;
    function depositOnBehalfDirect(address beneficiary, uint256 amount) external;
    function withdraw(address beneficiary, uint256 amount) external;

    // functions callable by HolyValor investment proxies
    // pool would transfer funds to HolyValor (returns actual amount, could be less than asked)
    function borrowToInvest(uint256 amount) external returns(uint256);
    // return invested body portion from HolyValor (pool will claim base assets from caller Valor)
    function returnInvested(uint256 amountCapitalBody) external;

    // functions callable by HolyRedeemer yield distributor
    function harvestYield(uint256 amount) external; // pool would transfer amount tokens from caller as it's profits
    // callable by strategies to keep track of conversion fees, etc.
    function realizeLoss(uint256 amount) external;
}


// Interface to represent middleware contract for swapping tokens
interface IExchangeProxy {
    // returns amount of 'destination token' that 'source token' was swapped to
    // NOTE: HolyWing grants allowance to arbitrary address (with call to contract that could be forged) and should not hold any funds
    function executeSwap(address tokenFrom, address tokenTo, uint256 amount, bytes calldata data) external returns(uint256);
}


// Interface to represent middleware contract for swapping tokens
interface IExchangeProxyV2 {
    // returns amount of 'destination token' that 'source token' was swapped to
    // NOTE: ExchangeProxy grants allowance to arbitrary address (with call to contract that could be forged) and should not hold any funds
    function executeSwap(address tokenFrom, address tokenTo, uint256 amount, bytes calldata data) payable external returns(uint256);

    function executeSwapDirect(address beneficiary, address tokenFrom, address tokenTo, uint256 amount, uint256 fee, bytes calldata data) payable external returns(uint256);
}


// Interface to represent Mover Transfer proxy
interface ITransferProxy {
}


// Interface to represent asset pool interactions
interface IStrategy {
    // safe amount of funds in base asset (USDC) that is possible to reclaim from this HolyValor without fee/penalty
    function safeReclaimAmount() external view returns(uint256);
    // total amount of funds in base asset (USDC) that is possible to reclaim from this HolyValor
    function totalReclaimAmount() external view returns(uint256);
    // callable only by a HolyPool, retrieve a portion of invested funds, return (just in case) amount transferred
    function reclaimFunds(uint256 amount, bool _safeExecution) external returns(uint256);
}


abstract contract SafeAllowanceResetUpgradeable {
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  // this function exists due to OpenZeppelin quirks in safe allowance-changing methods
  // we don't want to set allowance by small chunks as it would cost more gas for users
  // and we don't want to set it to zero and then back to value (this makes no sense security-wise in single tx)
  // from the other side, using it through safeIncreaseAllowance could revery due to SafeMath overflow
  // Therefore, we calculate what amount we can increase allowance on to refill it to max uint256 value
  function resetAllowanceIfNeeded(IERC20Upgradeable _token, address _spender, uint256 _amount) internal {
    uint256 allowance = _token.allowance(address(this), _spender);
    if (allowance < _amount) {
      uint256 newAllowance = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
      IERC20Upgradeable(_token).safeIncreaseAllowance(address(_spender), newAllowance.sub(allowance));
    }
  }
}

/*
   MoverAssetPoolPlus is a contract that holds user assets for investing
*/
contract MoverAssetPoolPlus is AccessControlUpgradeable, IAssetPoolV3 {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // role that grants most of financial operations for HolyPool
    bytes32 public constant FINMGMT_ROLE = keccak256("FINMGMT_ROLE");

    uint256 private constant lpPrecision = 1e3; // treshold to treat quantities (baseAsset, lpTokens) as equal (USDC has 6 decimals only)

    // emergency transfer (timelocked) variables and events
    event EmergencyTransferSet(
        address indexed token,
        address indexed destination,
        uint256 amount
    );
    event EmergencyTransferExecute(
        address indexed token,
        address indexed destination,
        uint256 amount
    );
    address private emergencyTransferToken;
    address private emergencyTransferDestination;
    uint256 private emergencyTransferTimestamp;
    uint256 private emergencyTransferAmount;

    // address of ERC20 base asset (expected to be stablecoin)
    address public baseAsset;

    ITransferProxy public transferProxy;

    // IStrategy invest proxies list and their statuses:
    // 0 -- invest proxy is blocked for all operations (equal to be deleted)
    // 1 -- invest proxy is active for all operations
    // 2 -- invest proxy can only place funds back and can not take funds from pool
    //   don't use enum for better upgradeability safety
    IStrategy[] public investProxies;
    mapping(address => uint256) public investProxiesStatuses;

    // total amount of assets in baseToken (baseToken balance of HolyPool + collateral valuation in baseToken)
    uint256 public totalAssetAmount;

    // total number of pool shares
    uint256 public totalShareAmount;
    // user balances (this is NOT USDC, but portion in shares)
    mapping(address => uint256) public shares;

    event Deposit(address indexed account, uint256 amount);
    event Withdraw(
        address indexed account,
        uint256 amountRequested,
        uint256 amountActual
    );

    event FundsInvested(address indexed investProxy, uint256 amount);
    event FundsDivested(address indexed investProxy, uint256 amount);
    event YieldRealized(uint256 amount);

    event ReclaimFunds(
        address indexed investProxy,
        uint256 amountRequested,
        uint256 amountReclaimed
    );

    bool depositsEnabled;

    uint256 public hotReserveTarget; // target amount of baseAsset tokens held in hot reserve (not invested)

    // for simple yield stats calculations
    uint256 public inceptionTimestamp; // inception timestamp

    function initialize(address _baseAsset) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FINMGMT_ROLE, _msgSender());

        baseAsset = _baseAsset;
        // pool has virtual 1 uint of base asset to avoid
        // division by zero and reasonable starting share value calculation
        // USDC has 6 decimal points, so USDC pool should have totalAssetAmount 1e6 as a starting point
        totalShareAmount = 1e6;
        totalAssetAmount = 1e6;
        depositsEnabled = true;
        hotReserveTarget = 0;

        inceptionTimestamp = block.timestamp;
    }

    function getBaseAsset() public view override returns (address) {
        return baseAsset;
    }

    function getDepositBalance(address _beneficiary)
        public
        view
        returns (uint256)
    {
        return shares[_beneficiary].mul(baseAssetPerShare()).div(1e18);
    }

    function baseAssetPerShare() public view returns (uint256) {
        return totalAssetAmount.mul(1e18).div(totalShareAmount);
    }

    function setTransferProxy(address _transferProxy) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        transferProxy = ITransferProxy(_transferProxy);
    }

    function setReserveTarget(uint256 _reserveTarget) public {
        require(hasRole(FINMGMT_ROLE, msg.sender), "finmgmt only");
        hotReserveTarget = _reserveTarget;
    }

    // Strategy management functions
    // add new strategy
    function addStrategy(address _address) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        investProxies.push(IStrategy(_address));
        investProxiesStatuses[_address] = 1;
    }

    // set status for strategy, can disable / restrict invest proxy methods
    function setStrategyStatus(address _address, uint256 _status) public {
        require(hasRole(FINMGMT_ROLE, msg.sender), "finmgmt only");
        investProxiesStatuses[_address] = _status;
    }

    function removeStrategy(uint256 index) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        //delete at index (order does not matter)
        investProxiesStatuses[address(investProxies[index])] = 0;
        investProxies[index] = investProxies[investProxies.length-1];
        investProxies.pop();
    }

    // Deposit/withdraw functions
    function setDepositsEnabled(bool _enabled) public {
        require(hasRole(FINMGMT_ROLE, msg.sender), "finmgmt only");
        depositsEnabled = _enabled;
    }

    function depositOnBehalf(address _beneficiary, uint256 _amount)
        public
        override
    {
        // transfer base asset tokens and calculate shares deposited
        IERC20Upgradeable(baseAsset).safeTransferFrom(msg.sender, address(this), _amount);

        depositOnBehalfDirect(_beneficiary, _amount);
    }

    // deposit process when funds have already been transferred (should be in the same transaction)
    function depositOnBehalfDirect(address _beneficiary, uint256 _amount)
        public
        override
    {
        require(msg.sender == address(transferProxy), "transfer proxy only");
        require(depositsEnabled, "deposits disabled");

        // compiler optimization should wrap these local vars automatically
        uint256 assetPerShare = baseAssetPerShare();
        uint256 sharesToDeposit = _amount.mul(1e18).div(assetPerShare);
        totalShareAmount = totalShareAmount.add(sharesToDeposit);
        totalAssetAmount = totalAssetAmount.add(_amount);
        shares[_beneficiary] = shares[_beneficiary].add(sharesToDeposit);

        emit Deposit(_beneficiary, _amount);
    }

    // withdraw funds from pool
    // amount is presented in base asset quantity
    // NOTE: this cannot transfer to arbitrary sender, or funds would be unsafe, only to transferProxy
    //
    // withdraw implementation considerations:
    // - the most important factor is: no external fee if possible;
    // - 2nd most important factor: lowest gas as possible
    //   (smallest strategy number used to reclaim funds, keep execution path short for simpler cases);
    // - if external withdraw fee is applied, no other users standings should be affected;
    // - if possible, reserve is restored on HolyPool up to hotReserveTarget
    function withdraw(address _beneficiary, uint256 _amount) public override {
        // TODO: perform funds reclamation if current amount of baseToken is insufficient
        require(msg.sender == address(transferProxy), "transfer proxy only");

        uint256 sharesAvailable = shares[_beneficiary];
        uint256 assetPerShare = baseAssetPerShare();
        uint256 assetsAvailable = sharesAvailable.mul(assetPerShare).div(1e18);
        require(_amount <= assetsAvailable, "requested amount exceeds balance");

        uint256 currentBalance = IERC20Upgradeable(baseAsset).balanceOf(address(this));

        if (currentBalance >= _amount) {
            // best case scenario, HolyPool has assets on reserve (current) balance
            performWithdraw(msg.sender, _beneficiary, _amount, _amount);
            return;
        }

        uint256 amountToReclaim = _amount.sub(currentBalance);
        uint256 reclaimedFunds = retrieveFunds(amountToReclaim);
        if (reclaimedFunds >= amountToReclaim) {
            // good scenario, funds were reclaimed (and probably some reserve amount was restored too)
            performWithdraw(msg.sender, _beneficiary, _amount, _amount);
        } else {
            // not very desireable scenario where funds were returned with fee
            performWithdraw(
                msg.sender,
                _beneficiary,
                _amount,
                currentBalance.add(reclaimedFunds)
            );
        }
    }

    function performWithdraw(
        address _addressProxy,
        address _beneficiary,
        uint256 _amountRequested,
        uint256 _amountActual
    ) internal {
        // amount of shares to withdraw to equal _amountActual of baseAsset requested
        uint256 sharesToWithdraw =
            _amountRequested.mul(1e18).div(baseAssetPerShare());

        // we checked this regarding base asset (USDC) amount, just in case check for share amount
        require(
            sharesToWithdraw <= shares[_beneficiary],
            "requested pool share exceeded"
        );

        // transfer tokens to transfer proxy
        IERC20Upgradeable(baseAsset).safeTransfer(_addressProxy, _amountActual);

        // only perform this after all other withdraw flow complete to recalculate HolyPool state\
        // even if external fees were applied, totalShareAmount/totalAssetAmount calculated
        // with requested withdrawal amount
        shares[_beneficiary] = shares[_beneficiary].sub(sharesToWithdraw);
        totalShareAmount = totalShareAmount.sub(sharesToWithdraw);
        totalAssetAmount = totalAssetAmount.sub(_amountRequested);

        emit Withdraw(_beneficiary, _amountRequested, _amountActual);
    }

    // used to get funds from invest proxy for withdrawal (if current amount to withdraw is insufficient)
    // tries to fulfill reserve
    // logic of funds retrieval:
    // 1. If _amount is larger than is safe to withdraw,
    //    withdraw only requested amount (calculate actully returned as fees may be implied)
    //    (don't imply fees on other users)
    // 2. Otherwise withdraw safe amount up to hotReserveTarget
    //    to keep next withdrawals cheaper
    // _amount parameter is the amount HolyPool shold have in addition to current balance for withdraw
    function retrieveFunds(uint256 _amount) internal returns (uint256) {
        uint256 safeAmountTotal = 0;

        // it is not possible to resize memory arrays, so declare sized one
        uint256 length = investProxies.length;
        uint256[] memory safeAmounts = new uint256[](length);
        uint256[] memory indexes = new uint256[](length);

        for (uint256 i; i < length; i++) {
            safeAmounts[i] = investProxies[i].safeReclaimAmount();
            if (
                safeAmounts[i] >= _amount &&
                investProxiesStatuses[address(investProxies[i])] > 0
            ) {
                // great, this strategy can provide funds without external fee
                // see if we can fulfill reserve safely
                // NOTE: _amount can be larger than hotReserveTarget
                uint256 amountToWithdraw = _amount.add(hotReserveTarget);
                if (amountToWithdraw > safeAmounts[i]) {
                    amountToWithdraw = safeAmounts[i]; // cap amountToWithdraw, don't reclaim more than safe amount
                }
                /*uint256 reclaimed =*/
                    investProxies[i].reclaimFunds(amountToWithdraw, true);
                // for savings plus this condition is relaxed, conversion fees are possible, etc.
                //require(reclaimed > amountToWithdraw.sub(lpPrecision), "reclaim amount mismatch");

                emit ReclaimFunds(address(investProxies[i]), _amount, amountToWithdraw);
                return amountToWithdraw;
            }
            indexes[i] = i;
            safeAmountTotal = safeAmountTotal.add(safeAmounts[i]);
        }

        // no single strategy has enough safe amount to get funds from, check if several have
        // https://medium.com/coinmonks/sorting-in-solidity-without-comparison-4eb47e04ff0d
        // as a reasonable empryric, number of active strategies would be less than 10, so use reverse insertion sort
        for (uint256 i = length - 1; i >= 0; i--) {
            uint256 picked = safeAmounts[i];
            uint256 pickedIndex = indexes[i];
            uint256 j = i + 1;
            while ((j < length) && (safeAmounts[j] > picked)) {
                safeAmounts[j - 1] = safeAmounts[j];
                indexes[j - 1] = indexes[j];
                j++;
            }
            safeAmounts[j - 1] = picked;
            indexes[j - 1] = pickedIndex;
            if (i == 0) {
                break; // uint256 won't be negative
            }
        }

        if (safeAmountTotal > _amount) {
            uint256 totalReclaimed = 0;
            // should be able to avoid external withdraw fee (even if use all strategies)
            // reclaim funds one by one (from sorted strategy list)
            for (uint256 i; i < length; i++) {
                uint256 amountToWithdraw = safeAmounts[i];
                if (amountToWithdraw > _amount.sub(totalReclaimed).add(hotReserveTarget)) {
                    amountToWithdraw = _amount.sub(totalReclaimed).add(hotReserveTarget);
                }
                /*uint256 reclaimed = */investProxies[indexes[i]].reclaimFunds(amountToWithdraw, true);
                
                // fees can occur, that would affect withdraw, this is allowed
                // require(reclaimed > amountToWithdraw.sub(lpPrecision), "insufficient amount reclaimed");
                
                totalReclaimed = totalReclaimed.add(amountToWithdraw);
                emit ReclaimFunds(
                    address(investProxies[indexes[i]]),
                    _amount,
                    amountToWithdraw
                );
                if (totalReclaimed >= _amount) {
                    break;
                }
            }
            return totalReclaimed;
        }

        // fee would occur, not enough safe amounts available
        uint256 totalReclaimedNoFees = 0; // we don't know what fees are for any investment allocation
        // so calculate theoretical quantity we expect without fees
        uint256 totalActualReclaimed = 0;
        // NOTE: we are not replenishing reserve balance when external fees apply
        // reclaim funds one by one (from sorted strategy list)
        // to use maximum safe amount and try to withdraw as much as is available in the particular allocation
        for (uint256 i; i < length; i++) {
            uint256 amountToWithdraw = _amount.sub(totalReclaimedNoFees);
            // cap amount if particular strategy does not have this amount of funds
            uint256 totalAvailableInStrategy =
                investProxies[indexes[i]].totalReclaimAmount();
            if (amountToWithdraw > totalAvailableInStrategy) {
                amountToWithdraw = totalAvailableInStrategy;
            }
            uint256 actualReclaimed =
                investProxies[indexes[i]].reclaimFunds(amountToWithdraw, false);
            totalReclaimedNoFees = totalReclaimedNoFees.add(amountToWithdraw);
            totalActualReclaimed = totalActualReclaimed.add(actualReclaimed);
            emit ReclaimFunds(
                address(investProxies[indexes[i]]),
                amountToWithdraw,
                actualReclaimed
            );
            if (totalReclaimedNoFees >= _amount) {
                break;
            }
        }
        return totalActualReclaimed;
    }

    // safe amount to withdraw
    // this function is for application to use to confirm withdrawal it exceeds safe amount.
    // takes into consideration this contract balance and invest proxies safe amounts
    // (meaning that no external fees/loss should be applied when withdrawing a certain amount,
    // to get cheapest (in terms of gas) withdraw amount, it's enough to query balanceOf this contract)
    function getSafeWithdrawAmount() public view returns (uint256) {
        uint256 safeAmount = IERC20Upgradeable(baseAsset).balanceOf(address(this));
        uint256 length = investProxies.length;

        for (uint256 i; i < length; i++) {
            if (investProxiesStatuses[address(investProxies[i])] > 0) {
                safeAmount = safeAmount.add(
                    investProxies[i].safeReclaimAmount()
                );
            }
        }
        return safeAmount;
    }

    // strategy invest/divest methods
    function borrowToInvest(uint256 _amount) public override returns (uint256) {
        require(
            investProxiesStatuses[msg.sender] == 1,
            "active invest proxy only"
        );

        uint256 borrowableAmount = IERC20Upgradeable(baseAsset).balanceOf(address(this));
        require(borrowableAmount > hotReserveTarget, "not enough funds");

        borrowableAmount = borrowableAmount.sub(hotReserveTarget);
        if (_amount > borrowableAmount) {
            _amount = borrowableAmount;
        }

        IERC20Upgradeable(baseAsset).safeTransfer(msg.sender, _amount);

        emit FundsInvested(msg.sender, _amount);

        return _amount;
    }

    // return funds body from strategy (divest), yield should go through yield distributor
    function returnInvested(uint256 _amountCapitalBody) public override {
        require(investProxiesStatuses[msg.sender] > 0, "invest proxy only"); // statuses 1 (active) or 2 (withdraw only) are ok

        IERC20Upgradeable(baseAsset).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amountCapitalBody
        );

        emit FundsDivested(msg.sender, _amountCapitalBody);
    }

    // Yield realization (intended to be called by HolyRedeemer)
    function harvestYield(uint256 _amountYield) public override {
        // check permissions
        // probably not required (anyone can put yield in pool if they want)

        // transfer _amountYield of baseAsset from caller
        IERC20Upgradeable(baseAsset).safeTransferFrom(
            msg.sender,
            address(this),
            _amountYield
        );

        // increase share price (indirectly, shares quantity remains same, but baseAsset quantity increases)
        totalAssetAmount = totalAssetAmount.add(_amountYield);

        // emit event
        emit YieldRealized(_amountYield);
    }

    // realize loss (intended to be called by strategy for small losses due to stablecoin conversion slippage, etc.)
    function realizeLoss(uint256 _amount) public override {
        // check permissions
        require(investProxiesStatuses[msg.sender] > 0, "invest proxy only"); // statuses 1 (active) or 2 (withdraw only) are ok

        // decrease share price (indirectly, shares quantity remains same, but baseAsset quantity increases)
        totalAssetAmount = totalAssetAmount.sub(_amount);
    }

    // This is oversimplified, no compounding and averaged across timespan from inception
    // TODO: daily, weekly, monthly, yearly APY
    // at inception pool share equals 1 (1e18) (specified in initializer)
    function getDailyAPY() public view returns (uint256) {
        uint256 secondsFromInception = block.timestamp.sub(inceptionTimestamp);

        return
            baseAssetPerShare()
                .sub(1e18)
                .mul(100) // substract starting share/baseAsset value 1.0 (1e18) and multiply by 100 to get percent value
                .mul(86400)
                .div(secondsFromInception); // fractional representation of how many days passed
    }

    // emergencyTransferTimelockSet is for safety (if some tokens got stuck)
    // in the future it could be removed, to restrict access to user funds
    // this is timelocked as contract can have user funds
    function emergencyTransferTimelockSet(
        address _token,
        address _destination,
        uint256 _amount
    ) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        emergencyTransferTimestamp = block.timestamp;
        emergencyTransferToken = _token;
        emergencyTransferDestination = _destination;
        emergencyTransferAmount = _amount;

        emit EmergencyTransferSet(_token, _destination, _amount);
    }

    function emergencyTransferExecute() public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "admin only");
        require(
            block.timestamp > emergencyTransferTimestamp + 24 * 3600,
            "timelock too early"
        );
        require(
            block.timestamp < emergencyTransferTimestamp + 72 * 3600,
            "timelock too late"
        );

        IERC20Upgradeable(emergencyTransferToken).safeTransfer(
            emergencyTransferDestination,
            emergencyTransferAmount
        );

        emit EmergencyTransferExecute(
            emergencyTransferToken,
            emergencyTransferDestination,
            emergencyTransferAmount
        );
        // clear emergency transfer timelock data
        emergencyTransferTimestamp = 0;
        emergencyTransferToken = address(0);
        emergencyTransferDestination = address(0);
        emergencyTransferAmount = 0;
    }
}