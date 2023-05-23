// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        StringsUpgradeable.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IERC11554KController.sol";
import "./interfaces/IGuardians.sol";
import "./interfaces/IFeesManager.sol";
import "./interfaces/IERC11554K.sol";
import "./interfaces/IERC11554KDrops.sol";

contract Administration is Initializable, AccessControlUpgradeable {
    enum ControlledContracts {
        CONTROLLER, //collections and drops are controller by controller
        GUARDIANS,
        FEES_MANAGER
    }

    /// @dev controller contract
    IERC11554KController public controller;
    /// @dev guardians contract
    IGuardians public guardians;
    /// @dev feesManager contract
    IFeesManager public feesManager;

    /// @dev address of controller admin.
    address public currentAdminController;
    /// @dev address of guardians admin.
    address public currentAdminGuardians;
    /// @dev address of fees manager admin.
    address public currentAdminFeesManager;

    /// @dev controller admin role.
    bytes32 public constant CONTROLLER_ADMIN_ROLE =
        keccak256("CONTROLLER_ADMIN_ROLE");
    /// @dev controller protocol assignee role.
    bytes32 public constant CONTROLLER_PROTOCOL_ASSIGNEE_ROLE =
        keccak256("CONTROLLER_PROTOCOL_ASSIGNEE_ROLE");

    /// @dev guardians admin role.
    bytes32 public constant GUARDIANS_ADMIN_ROLE =
        keccak256("GUARDIANS_ADMIN_ROLE");
    /// @dev guardians protocol assignee role.
    bytes32 public constant GUARDIANS_PROTOCOL_ASSIGNEE_ROLE =
        keccak256("GUARDIANS_PROTOCOL_ASSIGNEE_ROLE");

    /// @dev fees manager admin role.
    bytes32 public constant FEES_MANAGER_ADMIN_ROLE =
        keccak256("FEES_MANAGER_ADMIN_ROLE");
    /// @dev fees manager protocol assignee role.
    bytes32 public constant FEES_MANAGER_PROTOCOL_ASSIGNEE_ROLE =
        keccak256("FEES_MANAGER_PROTOCOL_ASSIGNEE_ROLE");

    /// @notice Version of the contract
    bytes32 public version;

    /// @dev A protocol assingee has been added for a particular controlled contract.
    event ProtocolAssigneeAdded(
        address assignee,
        ControlledContracts targetContract
    );
    /// @dev A protocol assingee has been removed for a particular controlled contract.
    event ProtocolAssigneeRemoved(
        address assignee,
        ControlledContracts targetContract
    );
    /// @dev The admin has been switched for a particular controlled contract.
    event AdminAddressSwitched(
        address newAdminAddress,
        ControlledContracts targetContract
    );

    /**
     * @dev Only the admin of a particular controller contract.
     */
    modifier onlyAdmin(ControlledContracts controlledContract) {
        require(
            isAdminOfContract(_msgSender(), controlledContract),
            "Administration: Not admin of contract"
        );
        _;
    }

    /**
     * @dev Only a protocol assignee of a particular controller contract.
     */
    modifier onlyProtocolAssignee(ControlledContracts controlledContract) {
        require(
            isProtocolAssigneeOfContract(_msgSender(), controlledContract),
            "Administration: Not protocol assignee of contract"
        );
        _;
    }

    /**
     * @dev Only a protocol assignee OR the admin of a particular controller contract.
     */
    modifier onlyControllerProtocolAssigneeOrAdmin(
        ControlledContracts controlledContract
    ) {
        require(
            isProtocolAssigneeOfContract(_msgSender(), controlledContract) ||
                isAdminOfContract(_msgSender(), controlledContract),
            "Administration: Not protocol assignee or admin of contract"
        );
        _;
    }

    /**
     * @notice Initialize Administration contract.
     * @param _controller ERC11554K controller contract address.
     * @param _guardians Guardians contract address.
     * @param _feesManager Fees manager contract address.
     * @param _controllerAdminAddress Admin of controller contract.
     * @param _guardiansAdminAddress Admin of guardians contract.
     * @param _feesManagerAdminAddress Admin of fees manager contract.
     * @param _version Version of contract
     */
    function initialize(
        IERC11554KController _controller,
        IGuardians _guardians,
        IFeesManager _feesManager,
        address _controllerAdminAddress,
        address _guardiansAdminAddress,
        address _feesManagerAdminAddress,
        bytes32 _version
    ) external virtual initializer {
        __Administration_init(
            _controller,
            _guardians,
            _feesManager,
            _controllerAdminAddress,
            _guardiansAdminAddress,
            _feesManagerAdminAddress,
            _version
        );
    }

    /**
     * @notice Switch the admin address of one of the controlled contracts.
     * Requirements:
     *
     * 1) Only callable by current admin of the contract being modifed.
     * @param _newAdminAddress Address of new contract.
     * @param controlledContract Which contract will be modified. See ControlledContracts enum.
     */
    function switchAdminAddress(
        address _newAdminAddress,
        ControlledContracts controlledContract
    ) external onlyAdmin(controlledContract) {
        _grantRole(DEFAULT_ADMIN_ROLE, _newAdminAddress);
        if (controlledContract == ControlledContracts.CONTROLLER) {
            _revokeRole(DEFAULT_ADMIN_ROLE, currentAdminController);
            _revokeRole(CONTROLLER_ADMIN_ROLE, currentAdminController);
            currentAdminController = _newAdminAddress;
            _grantRole(CONTROLLER_ADMIN_ROLE, _newAdminAddress);
        } else if (controlledContract == ControlledContracts.GUARDIANS) {
            _revokeRole(DEFAULT_ADMIN_ROLE, currentAdminGuardians);
            _revokeRole(GUARDIANS_ADMIN_ROLE, currentAdminGuardians);
            currentAdminGuardians = _newAdminAddress;
            _grantRole(GUARDIANS_ADMIN_ROLE, _newAdminAddress);
        } else if (controlledContract == ControlledContracts.FEES_MANAGER) {
            _revokeRole(DEFAULT_ADMIN_ROLE, currentAdminFeesManager);
            _revokeRole(FEES_MANAGER_ADMIN_ROLE, currentAdminFeesManager);
            currentAdminFeesManager = _newAdminAddress;
            _grantRole(FEES_MANAGER_ADMIN_ROLE, _newAdminAddress);
        }
        emit AdminAddressSwitched(_newAdminAddress, controlledContract);
    }

    /**
     * @dev Sets the version of the contract.
     * @param version_ New version of contract.
     */
    function setAdministrationVersion(
        bytes32 version_,
        ControlledContracts controlledContract
    ) external virtual onlyProtocolAssignee(controlledContract) {
        version = version_;
    }

    /**
     * @dev Sets the version of a controlled contract.
     * @param version_ New version of contract.
     */
    function setControlledContractVersion(
        bytes32 version_,
        ControlledContracts controlledContract
    ) external virtual onlyProtocolAssignee(controlledContract) {
        if (controlledContract == ControlledContracts.CONTROLLER) {
            controller.setVersion(version_);
        } else if (controlledContract == ControlledContracts.GUARDIANS) {
            guardians.setVersion(version_);
        } else if (controlledContract == ControlledContracts.FEES_MANAGER) {
            feesManager.setVersion(version_);
        }
    }

    /**
     * @notice Transfer the ownership of a controlled contract to a new address.
     * Requirements:
     *
     * 1) Only callable by current admin of the contract being modifed.
     * @param controlledContract Which contract will be modified. See ControlledContracts enum.
     * @param newOwner Address of new owner.
     */
    function transferOwnership(
        ControlledContracts controlledContract,
        address newOwner
    ) external onlyAdmin(controlledContract) {
        if (controlledContract == ControlledContracts.CONTROLLER) {
            controller.transferOwnership(newOwner);
        } else if (controlledContract == ControlledContracts.GUARDIANS) {
            guardians.transferOwnership(newOwner);
        } else if (controlledContract == ControlledContracts.FEES_MANAGER) {
            feesManager.transferOwnership(newOwner);
        }
    }

    /**
     * @notice Add a protocol assignee to one of the controlled contracts.
     * Requirements:
     *
     * 1) Only callable by current admin of the contract being modifed.
     * @param _newProtocolAssignee Address of assingnee.
     * @param controlledContract Which contract will be modified. See ControlledContracts enum.
     */
    function addProtocolAssignee(
        address _newProtocolAssignee,
        ControlledContracts controlledContract
    ) external onlyAdmin(controlledContract) {
        if (controlledContract == ControlledContracts.CONTROLLER) {
            grantRole(CONTROLLER_PROTOCOL_ASSIGNEE_ROLE, _newProtocolAssignee);
        } else if (controlledContract == ControlledContracts.GUARDIANS) {
            grantRole(GUARDIANS_PROTOCOL_ASSIGNEE_ROLE, _newProtocolAssignee);
        } else if (controlledContract == ControlledContracts.FEES_MANAGER) {
            grantRole(
                FEES_MANAGER_PROTOCOL_ASSIGNEE_ROLE,
                _newProtocolAssignee
            );
        }
        emit ProtocolAssigneeAdded(_newProtocolAssignee, controlledContract);
    }

    /**
     * @notice Remove a protocol assignee from one of the controlled contracts.
     * Requirements:
     *
     * 1) Only callable by current admin of the contract being modifed.
     * @param _protocolAssigneeToRemove Address of assingnee to remove.
     * @param controlledContract Which contract will be modified. See ControlledContracts enum.
     */
    function removeProtocolAssignee(
        address _protocolAssigneeToRemove,
        ControlledContracts controlledContract
    ) external onlyAdmin(controlledContract) {
        if (controlledContract == ControlledContracts.CONTROLLER) {
            revokeRole(
                CONTROLLER_PROTOCOL_ASSIGNEE_ROLE,
                _protocolAssigneeToRemove
            );
        } else if (controlledContract == ControlledContracts.GUARDIANS) {
            revokeRole(
                GUARDIANS_PROTOCOL_ASSIGNEE_ROLE,
                _protocolAssigneeToRemove
            );
        } else if (controlledContract == ControlledContracts.FEES_MANAGER) {
            revokeRole(
                FEES_MANAGER_PROTOCOL_ASSIGNEE_ROLE,
                _protocolAssigneeToRemove
            );
        }

        emit ProtocolAssigneeRemoved(
            _protocolAssigneeToRemove,
            controlledContract
        );
    }

    ///// CONTROLLER FUNCTIONS

    /**
     * @notice Sets maxMintPeriod to maxMintPeriod_.
     *
     * Requirements:
     *
     * 1) The caller must be admin of controller contract.
     * @param maxMintPeriod_ New max mint period.
     */
    function setControllerMaxMintPeriod(
        uint256 maxMintPeriod_
    ) external onlyAdmin(ControlledContracts.CONTROLLER) {
        controller.setMaxMintPeriod(maxMintPeriod_);
    }

    /**
     * @notice Sets remediator address
     *
     * Requirements:
     *
     * 1) The caller must be admin of controller contract.
     * @param _remediator New remediator
     */
    function setControllerRemediator(
        address _remediator
    ) external onlyAdmin(ControlledContracts.CONTROLLER) {
        controller.setRemediator(_remediator);
    }

    /**
     * @notice Sets collectionFee to collectionFee_.
     *
     * Requirements:
     *
     * 1) The caller must be admin of controller contract.
     * @param collectionFee_, New collection creation fee.
     */
    function setControllerCollectionFee(
        uint256 collectionFee_
    ) external onlyAdmin(ControlledContracts.CONTROLLER) {
        controller.setCollectionFee(collectionFee_);
    }

    /**
     * @notice Sets beneficiary to beneficiary_.
     *
     * Requirements:
     *
     * 1) The caller must be admin of controller contract.
     * @param beneficiary_ New fees beneficiary address.
     */
    function setControllerBeneficiary(
        address beneficiary_
    ) external onlyAdmin(ControlledContracts.CONTROLLER) {
        controller.setBeneficiary(beneficiary_);
    }

    /**
     * @notice Sets guardians contract to guardians_.
     *
     * Requirements:
     *
     * 1) The caller must be admin of controller contract.
     * @param guardians_, New Guardians contract address.
     */
    function setControllerGuardians(
        IGuardians guardians_
    ) external onlyAdmin(ControlledContracts.CONTROLLER) {
        controller.setGuardians(guardians_);
    }

    /**
     * @notice Sets paymentToken to paymentToken_.
     *
     * Requirements:
     *
     * 1) The caller must be admin of controller contract.
     * 2) Payment token must have 18 decimals or less.
     * @param paymentToken_ New payment token for fees.
     */
    function setControllerPaymentToken(
        IERC20Upgradeable paymentToken_
    ) external onlyAdmin(ControlledContracts.CONTROLLER) {
        controller.setPaymentToken(paymentToken_);
    }

    ///// 11554K COLLECTION FUNCTIONS

    /**
     * @notice Sets guardians contract for a collection.
     *
     * Requirements:
     *
     * 1) The caller must be admin of controller contract.
     * @param collection collection that is being operated on.
     * @param guardians_ New guardian contract address.
     **/
    function setCollectionsGuardians(
        IERC11554K collection,
        IGuardians guardians_
    ) external onlyAdmin(ControlledContracts.CONTROLLER) {
        collection.setGuardians(guardians_);
    }

    /**
     * @notice Sets token URI for a collection
     *
     * Requirements:
     *
     * 1) The caller must be admin or assignee of controller contract.
     * @param collection collection that is being operated on.
     * @param newuri New root uri for the tokens.
     **/
    function setCollectionsURI(
        IERC11554K collection,
        string calldata newuri
    )
        external
        onlyControllerProtocolAssigneeOrAdmin(ControlledContracts.CONTROLLER)
    {
        collection.setURI(newuri);
    }

    /**
     * @notice Sets contract-level collection URI for a collection.
     *
     * Requirements:
     *
     * 1) The caller must be admin or assignee of controller contract.
     * @param collection collection that is being operated on.
     * @param collectionURI_ New collection uri for the collection info.
     **/
    function setCollectionsCollectionURI(
        IERC11554K collection,
        string calldata collectionURI_
    )
        external
        onlyControllerProtocolAssigneeOrAdmin(ControlledContracts.CONTROLLER)
    {
        collection.setCollectionURI(collectionURI_);
    }

    /**
     * @notice Sets the verification status of a collection.
     *
     * Requirements:
     *
     * 1) The caller must be assignee of controller contract.
     * @param collection collection that is being operated on.
     * @param _isVerified Boolean that signifies if this is a verified collection or not.
     */
    function setCollectionsVerificationStatus(
        IERC11554K collection,
        bool _isVerified
    ) external onlyProtocolAssignee(ControlledContracts.CONTROLLER) {
        collection.setVerificationStatus(_isVerified);
    }

    /**
     * @notice Sets the royalty information that all ids in this collection will default to.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of controller contract.
     * 2) Receiver cannot be the zero address.
     * 3) feeNumerator cannot be greater than the fee denominator.
     * @param collection collection that is being operated on.
     * @param receiver the address of the entity that will be getting the default royalty.
     * @param feeNumerator the amount of royalty the receiver will receive. Numerator that generates percentage, over the _feeDenominator().
     */
    function setCollectionsGlobalRoyalty(
        IERC11554K collection,
        address receiver,
        uint96 feeNumerator
    ) external onlyProtocolAssignee(ControlledContracts.CONTROLLER) {
        collection.setGlobalRoyalty(receiver, feeNumerator);
    }

    ///// 11554KDROPS COLLECTION FUNCTIONS

    /**
     * @notice Sets a drop collection to revealed status.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of the controller.
     * @param drop Drop collection to operate on.
     * @param collectionURI_ Revealed collection URI.
     **/
    function setDropCollectionRevealed(
        IERC11554KDrops drop,
        string calldata collectionURI_
    ) external onlyProtocolAssignee(ControlledContracts.CONTROLLER) {
        drop.setRevealed(collectionURI_);
    }

    /**
     * @notice Sets Minting drops contract for a drop collection.
     *
     * Requirements:
     *
     * 1) The caller be the admin of the controller.
     * @param drop Drop collection to operate on.
     * @param mintingDrops_ Minting Drops contract
     **/
    function setDropCollectionMintingDrops(
        IERC11554KDrops drop,
        address mintingDrops_
    ) external onlyProtocolAssignee(ControlledContracts.CONTROLLER) {
        drop.setMintingDrops(mintingDrops_);
    }

    ///// FEES MANAGER FUNCTIONS

    /**
     * @notice Moves all guardian fees between guardians.
     *
     * Requirements:
     *
     * 1) The caller must be a protocol assginee of the fees manager.
     * @param guardianFrom Guardian address, from which fees are moved.
     * @param guardianTo Guardian address, to which fees are moved.
     */
    function moveFeesManagerFeesBetweenGuardians(
        address guardianFrom,
        address guardianTo,
        IERC20Upgradeable asset
    ) external onlyProtocolAssignee(ControlledContracts.FEES_MANAGER) {
        feesManager.moveFeesBetweenGuardians(guardianFrom, guardianTo, asset);
    }

    /**
     * @notice Sets guardians to guardians_ for the fees manager.
     *
     * Requirements:
     *
     * 1) The caller must be the admin of the fees manager contract.
     * @param guardians_ New Guardians contract address.
     */
    function setFeesManagerGuardians(
        IGuardians guardians_
    ) external onlyAdmin(ControlledContracts.FEES_MANAGER) {
        feesManager.setGuardians(guardians_);
    }

    /**
     * @notice Sets controller to controller_ for the fees manager.
     *
     * Requirements:
     *
     * 1) The caller must be the admin of the fees manager contract.
     * @param controller_ New Controller contract address.
     */
    function setFeesManagerController(
        IERC11554KController controller_
    ) external onlyAdmin(ControlledContracts.FEES_MANAGER) {
        feesManager.setController(controller_);
    }

    /**
     * @notice Sets globalTradingFee to globalTradingFee_  for the fees manager.
     *
     * Requirements:
     *
     * 1) The caller must be the admin of the fees manager contract.
     * @param globalTradingFee_ New global trading fee.
     */
    function setFeesManagerGlobalTradingFee(
        uint256 globalTradingFee_
    ) external onlyAdmin(ControlledContracts.FEES_MANAGER) {
        feesManager.setGlobalTradingFee(globalTradingFee_);
    }

    /**
     * @notice Sets tradingFeeSplit for the fees manager.
     *
     * Requirements:
     *
     * 1) The caller must be the admin of the fees manager contract.
     * @param protocolSplit New protocol fees share.
     * @param guardianSplit New guardians fees share.
     */
    function setFeesManagerTradingFeeSplit(
        uint256 protocolSplit,
        uint256 guardianSplit
    ) external onlyAdmin(ControlledContracts.FEES_MANAGER) {
        feesManager.setTradingFeeSplit(protocolSplit, guardianSplit);
    }

    /**
     * @notice Sets exchange to exchange_ for the fees manager.
     *
     * Requirements:
     *
     * 1) The caller must be the admin of the fees manager contract.
     * @param exchange_ New Exchange contract address.
     */
    function setFeesManagerExchange(
        address exchange_
    ) external onlyAdmin(ControlledContracts.FEES_MANAGER) {
        feesManager.setExchange(exchange_);
    }

    ///// GUARDIAN FUNCTIONS

    /**
     * @notice Set controller for guardian controller.
     *
     * Requirements:
     *
     * 1) The caller must be the admin of guardians controller.
     * @param controller_ New address of controller contract.
     */
    function setGuardiansController(
        IERC11554KController controller_
    ) external onlyAdmin(ControlledContracts.GUARDIANS) {
        guardians.setController(controller_);
    }

    /**
     * @notice Set fees manager for guardians contract
     *
     * Requirements:
     *
     * 1) The caller must be the admin of guardians controller.
     @param feesManager_ New address of fees manager contract.
     */
    function setGuardiansFeesManager(
        IFeesManager feesManager_
    ) external onlyAdmin(ControlledContracts.GUARDIANS) {
        guardians.setFeesManager(feesManager_);
    }

    /**
     * @notice Sets new min storage time.
     *
     * Requirements:
     *
     * 1) The caller must be the admin of guardians controller.
     * @param minStorageTime_ New minimum storage time that items require to have, in seconds.
     */
    function setGuardiansMinStorageTime(
        uint256 minStorageTime_
    ) external onlyAdmin(ControlledContracts.GUARDIANS) {
        guardians.setMinStorageTime(minStorageTime_);
    }

    /**
     * @notice Sets minimum mining fee.
     *
     * Requirements:
     *
     * 1) The caller must be the admin of guardians controller.
     * @param minimumRequestFee_ New minumum mint request fee.
     */
    function setGuardiansMinimumRequestFee(
        uint256 minimumRequestFee_
    ) external onlyAdmin(ControlledContracts.GUARDIANS) {
        guardians.setMinimumRequestFee(minimumRequestFee_);
    }

    /**
     * @notice Sets maximum Guardian fee rate set percentage.
     *
     * Requirements:
     *
     * 1) The caller must be the admin of guardians controller.
     * @param maximumGuardianFeeSet_ New max percentage increase that a guardian can increase a guardian fee rate by. Numerator that generates percentage, over the PERCENTAGE_FACTOR
     */
    function setGuardiansMaximumGuardianFeeSet(
        uint256 maximumGuardianFeeSet_
    ) external onlyAdmin(ControlledContracts.GUARDIANS) {
        guardians.setMaximumGuardianFeeSet(maximumGuardianFeeSet_);
    }

    /**
     * @notice Sets minimum Guardian fee.
     *
     * Requirements:
     *
     * 1) The caller must be the admin of guardians controller.
     * @param guardianFeeSetWindow_ New window of time in seconds within a guardian is allowed to increase a guardian fee rate
     */
    function setGuardianFeeSetWindow(
        uint256 guardianFeeSetWindow_
    ) external onlyAdmin(ControlledContracts.GUARDIANS) {
        guardians.setGuardianFeeSetWindow(guardianFeeSetWindow_);
    }

    /**
     * @notice Moves items from inactive guardian to active guardian. Move ALL items,
     * in the case of semi-fungibles. Must pass a guardian classe for each item for the new guardian.
     *
     * Requirements:
     *
     * 1) The caller must be the admin of guardians controller.
     * 2) Old guardian must be inactive.
     * 3) New guardian must be active.
     * 4) Each class passed for each item for the new guardian must be active.
     * 5) Must only be used to move ALL items and have movement of guardian fees after moving ALL items.
     * @param collection Address of the collection that includes the items being moved.
     * @param ids Array of item ids being moved.
     * @param oldGuardian Address of the guardian items are being moved from.
     * @param newGuardian Address of the guardian items are being moved to.
     * @param newGuardianClassIndeces Array of the newGuardian's guardian class indices the items will be moved to.
     */
    function moveGuardiansItems(
        IERC11554K collection,
        uint256[] calldata ids,
        address oldGuardian,
        address newGuardian,
        uint256[] calldata newGuardianClassIndeces
    ) external onlyAdmin(ControlledContracts.GUARDIANS) {
        guardians.moveItems(
            collection,
            ids,
            oldGuardian,
            newGuardian,
            newGuardianClassIndeces
        );
    }

    /**
     * @notice Copies all guardian classes from one guardian to another.
     * @dev If new guardian has no guardian classes before this, class indeces will be the same. If not, copies classes will have new indeces.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param oldGuardian Address of the guardian whose classes will be moved.
     * @param newGuardian Address of the guardian that will be receiving the classes.
     */
    function copyGuardianClasses(
        address oldGuardian,
        address newGuardian
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.copyGuardianClasses(oldGuardian, newGuardian);
    }

    /**
     * @notice Sets activity mode for the guardian. Either active or not.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of guardian whose activity mode will be set.
     * @param activity Boolean for guardian activity mode.
     */
    function setGuardiansActivity(
        address guardian,
        bool activity
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.setActivity(guardian, activity);
    }

    /**
     * @notice Sets privacy mode for the guardian. Either public false or private true.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of guardian whose privacy mode will be set.
     * @param privacy Boolean for guardian privacy mode.
     */
    function setGuardiansPrivacy(
        address guardian,
        bool privacy
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.setPrivacy(guardian, privacy);
    }

    /**
     * @notice Sets logo for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian address of guardian whose logo will be set.
     * @param logo URI of logo for guardian.
     */
    function setGuardiansLogo(
        address guardian,
        string calldata logo
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.setLogo(guardian, logo);
    }

    /**
     * @notice Sets name for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of guardian whose name will be set.
     * @param name Name of guardian.
     */
    function setGuardiansName(
        address guardian,
        string calldata name
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.setName(guardian, name);
    }

    /**
     * @notice Sets physical address hash for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of guardian whose physical address will be set.
     * @param physicalAddressHash Bytes hash of physical address of the guardian.
     */
    function setGuardiansPhysicalAddressHash(
        address guardian,
        bytes32 physicalAddressHash
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.setPhysicalAddressHash(guardian, physicalAddressHash);
    }

    /**
     * @notice Sets policy for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of guardian whose policy will be set.
     * @param policy Guardian policy.
     */
    function setGuardiansPolicy(
        address guardian,
        string calldata policy
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.setPolicy(guardian, policy);
    }

    /**
     * @notice Sets redirects for the guardian.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of guardian whose redirect URI will be set.
     * @param redirect Redirect URI for guardian.
     */
    function setGuardiansRedirect(
        address guardian,
        string calldata redirect
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.setRedirect(guardian, redirect);
    }

    /**
     * @notice Adds or removes users addresses to guardian whitelist.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of guardian whose users whitelist status will be modified.
     * @param users Array of user addresses whose whitelist status will be modified.
     * @param whitelistStatus Boolean for the whitelisted status of the users.
     */
    function changeGuardiansWhitelistUsersStatus(
        address guardian,
        address[] calldata users,
        bool whitelistStatus
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.changeWhitelistUsersStatus(guardian, users, whitelistStatus);
    }

    /**
     * @notice Removes guardian from the whitelist.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian address of guardian who will be removed.
     */
    function removeGuardian(
        address guardian
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.removeGuardian(guardian);
    }

    /**
     * @notice Sets minting fee for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of the guardian whose guardian class minting fee will be modified.
     * @param classID Guardian's guardian class index whose minting fee will be modified.
     * @param mintingFee New minting fee. Minting fee must be passed as already scaled by 10^18 from real life value.
     */
    function setGuardianClassMintingFee(
        address guardian,
        uint256 classID,
        uint256 mintingFee
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.setGuardianClassMintingFee(guardian, classID, mintingFee);
    }

    /**
     * @notice Sets redemption fee for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of the guardian whose guardian class redemption fee will be modified.
     * @param classID Guardian's guardian class index whose redemption fee will be modified.
     * @param redemptionFee New redemption fee. Redemption fee must be passed as already scaled by 10^18 from real life value.
     */
    function setGuardianClassRedemptionFee(
        address guardian,
        uint256 classID,
        uint256 redemptionFee
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.setGuardianClassRedemptionFee(
            guardian,
            classID,
            redemptionFee
        );
    }

    /**
     * @notice Sets Guardian fee rate for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of the guardian whose guardian class guardian fee rate will be modified.
     * @param classID Guardian's guardian class index whose guardian fee rate  will be modified.
     * @param guardianFeeRate New guardian fee rate. Guardain fee rate must be passed as already scaled by 10^18 from real life value.
     */
    function setGuardianClassGuardianFeeRate(
        address guardian,
        uint256 classID,
        uint256 guardianFeeRate
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.setGuardianClassGuardianFeeRate(
            guardian,
            classID,
            guardianFeeRate
        );
    }

    /**
     * @notice Sets Guardian fee rate and guardian fee rate period for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of the guardian whose guardian class guardian fee rate will be modified.
     * @param classID Guardian's guardian class index whose guardian fee rate  will be modified.
     * @param guardianFeeRatePeriod New guardian fee rate period.
     * @param guardianFeeRate New guardian fee rate. Guardain fee rate must be passed as already scaled by 10^18 from real life value.
     */
    function setGuardianClassGuardianFeePeriodAndRate(
        address guardian,
        uint256 classID,
        IGuardians.GuardianFeeRatePeriods guardianFeeRatePeriod,
        uint256 guardianFeeRate
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.setGuardianClassGuardianFeePeriodAndRate(
            guardian,
            classID,
            guardianFeeRatePeriod,
            guardianFeeRate
        );
    }

    /**
     * @notice Sets URI for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of the guardian whose guardian class URI will be modified.
     * @param classID Guardian's guardian class index whose class URI will be modified.
     * @param uri New URI.
     */
    function setGuardianClassURI(
        address guardian,
        uint256 classID,
        string calldata uri
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.setGuardianClassURI(guardian, classID, uri);
    }

    /**
     * @notice Sets guardian class as active or not active by guardian or owner
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of the guardian whose guardian class active status will be modified.
     * @param classID Guardian's guardian class index whose guardian class active status will be modified.
     * @param activeStatus New guardian class active status.
     */
    function setGuardianClassActiveStatus(
        address guardian,
        uint256 classID,
        bool activeStatus
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.setGuardianClassActiveStatus(guardian, classID, activeStatus);
    }

    /**
     * @notice Sets maximum insurance coverage for guardian class by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of the guardian whose guardian class maximum coverage will be modified.
     * @param classID Guardian's guardian class index whose guardian class maximum coverage will be modified.
     * @param maximumCoverage New guardian class maximum coverage.
     */
    function setGuardianClassMaximumCoverage(
        address guardian,
        uint256 classID,
        uint256 maximumCoverage
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.setGuardianClassMaximumCoverage(
            guardian,
            classID,
            maximumCoverage
        );
    }

    /**
     * @notice Adds guardian class to guardian by guardian.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of guardian who is adding a new class.
     * @param maximumCoverage Max coverage of new guardian class.
     * @param mintingFee Minting fee of new guardian class. Minting fee must be passed as already scaled by 10^18 from real life value.
     * @param redemptionFee Redemption fee of new guardian class. Redemption fee must be passed as already scaled by 10^18 from real life value.
     * @param guardianFeeRate Guardian fee rate of new guardian class. Guardian fee rate must be passed as already scaled by 10^18 from real life value.
     * @param guardianFeeRatePeriod The size of the period unit for the guardian fee rate: per second, minute, hour, or day.
     */
    function addGuardianClass(
        address guardian,
        uint256 maximumCoverage,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 guardianFeeRate,
        IGuardians.GuardianFeeRatePeriods guardianFeeRatePeriod,
        string calldata uri
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.addGuardianClass(
            guardian,
            maximumCoverage,
            mintingFee,
            redemptionFee,
            guardianFeeRate,
            guardianFeeRatePeriod,
            uri
        );
    }

    /**
     * @notice Registers guardian.
     *
     * Requirements:
     *
     * 1) The caller must be an assignee of guardians controller.
     * @param guardian Address of the new guardian.
     * @param name Name of new guardian.
     * @param logo URI of new guardian logo.
     * @param policy Policy of new guardian.
     * @param redirect Redirect URI of new guardian.
     * @param physicalAddressHash physical address hash of new guardian.
     * @param privacy Boolean - is the new guardian private or not.
     */
    function registerGuardian(
        address guardian,
        string calldata name,
        string calldata logo,
        string calldata policy,
        string calldata redirect,
        bytes32 physicalAddressHash,
        bool privacy
    ) external onlyProtocolAssignee(ControlledContracts.GUARDIANS) {
        guardians.registerGuardian(
            guardian,
            name,
            logo,
            policy,
            redirect,
            physicalAddressHash,
            privacy
        );
    }

    function isProtocolAssigneeOfContract(
        address toCheck,
        ControlledContracts controlledContract
    ) public view returns (bool) {
        if (controlledContract == ControlledContracts.CONTROLLER) {
            return hasRole(CONTROLLER_PROTOCOL_ASSIGNEE_ROLE, toCheck);
        } else if (controlledContract == ControlledContracts.GUARDIANS) {
            return hasRole(GUARDIANS_PROTOCOL_ASSIGNEE_ROLE, toCheck);
        } else if (controlledContract == ControlledContracts.FEES_MANAGER) {
            return hasRole(FEES_MANAGER_PROTOCOL_ASSIGNEE_ROLE, toCheck);
        } else {
            return false;
        }
    }

    function isAdminOfContract(
        address toCheck,
        ControlledContracts controlledContract
    ) public view returns (bool) {
        if (controlledContract == ControlledContracts.CONTROLLER) {
            return
                hasRole(CONTROLLER_ADMIN_ROLE, toCheck) &&
                hasRole(DEFAULT_ADMIN_ROLE, toCheck) &&
                currentAdminController == toCheck;
        } else if (controlledContract == ControlledContracts.GUARDIANS) {
            return
                hasRole(GUARDIANS_ADMIN_ROLE, toCheck) &&
                hasRole(DEFAULT_ADMIN_ROLE, toCheck) &&
                currentAdminGuardians == toCheck;
        } else if (controlledContract == ControlledContracts.FEES_MANAGER) {
            return
                hasRole(FEES_MANAGER_ADMIN_ROLE, toCheck) &&
                hasRole(DEFAULT_ADMIN_ROLE, toCheck) &&
                currentAdminFeesManager == toCheck;
        } else {
            return false;
        }
    }

    function __Administration_init(
        IERC11554KController _controller,
        IGuardians _guardians,
        IFeesManager _feesManager,
        address _controllerAdminAddress,
        address _guardiansAdminAddress,
        address _feesManagerAddress,
        bytes32 _version
    ) internal onlyInitializing {
        __AccessControl_init();

        controller = _controller;
        guardians = _guardians;
        feesManager = _feesManager;
        version = _version;

        currentAdminController = _controllerAdminAddress;
        _grantRole(DEFAULT_ADMIN_ROLE, currentAdminController);
        _grantRole(CONTROLLER_ADMIN_ROLE, currentAdminController);

        currentAdminGuardians = _guardiansAdminAddress;
        _grantRole(DEFAULT_ADMIN_ROLE, currentAdminGuardians);
        _grantRole(GUARDIANS_ADMIN_ROLE, currentAdminGuardians);

        currentAdminFeesManager = _feesManagerAddress;
        _grantRole(DEFAULT_ADMIN_ROLE, currentAdminFeesManager);
        _grantRole(FEES_MANAGER_ADMIN_ROLE, currentAdminFeesManager);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IGuardians.sol";

/**
 * @dev {IERC11554K} interface:
 */
interface IERC11554K {
    function controllerMint(
        address mintAddress,
        uint256 tokenId,
        uint256 amount
    ) external;

    function controllerBurn(
        address burnAddress,
        uint256 tokenId,
        uint256 amount
    ) external;

    function setGuardians(IGuardians guardians_) external;

    function setURI(string calldata newuri) external;

    function setCollectionURI(string calldata collectionURI_) external;

    function setVerificationStatus(bool _isVerified) external;

    function setGlobalRoyalty(address receiver, uint96 feeNumerator) external;

    function owner() external view returns (address);

    function balanceOf(
        address user,
        uint256 item
    ) external view returns (uint256);

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256);

    function totalSupply(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IERC11554K.sol";
import "./IGuardians.sol";

/**
 * @dev {IERC11554KController} interface:
 */
interface IERC11554KController {
    /// @dev Batch minting request data structure.
    struct BatchRequestMintData {
        /// @dev Collection address.
        IERC11554K collection;
        /// @dev Item id.
        uint256 id;
        /// @dev Guardian address.
        address guardianAddress;
        /// @dev Amount to mint.
        uint256 amount;
        /// @dev Service fee to guardian.
        uint256 serviceFee;
        /// @dev Is item supply expandable.
        bool isExpandable;
        /// @dev Recipient address.
        address mintAddress;
        /// @dev Guardian class index.
        uint256 guardianClassIndex;
        /// @dev Guardian fee amount to pay.
        uint256 guardianFeeAmount;
    }

    function requestMint(
        IERC11554K collection,
        uint256 id,
        address guardian,
        uint256 amount,
        uint256 serviceFee,
        bool expandable,
        address mintAddress,
        uint256 guardianClassIndex,
        uint256 guardianFeeAmount
    ) external returns (uint256);

    function mint(IERC11554K collection, uint256 id) external;

    function owner() external returns (address);

    function originators(
        address collection,
        uint256 tokenId
    ) external returns (address);

    function isActiveCollection(address collection) external returns (bool);

    function isLinkedCollection(address collection) external returns (bool);

    function paymentToken() external returns (IERC20Upgradeable);

    function maxMintPeriod() external returns (uint256);

    function remediationBurn(
        IERC11554K collection,
        address owner,
        uint256 id,
        uint256 amount
    ) external;

    function setMaxMintPeriod(uint256 maxMintPeriod_) external;

    function setRemediator(address _remediator) external;

    function setCollectionFee(uint256 collectionFee_) external;

    function setBeneficiary(address beneficiary_) external;

    function setGuardians(IGuardians guardians_) external;

    function setPaymentToken(IERC20Upgradeable paymentToken_) external;

    function transferOwnership(address newOwner) external;

    function setVersion(bytes32 version_) external;

    function guardians() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IERC11554K.sol";

/**
 * @dev {IERC11554KDrops} interface:
 */
interface IERC11554KDrops is IERC11554K {
    function setItemUriID(uint256 id, uint256 uriID) external;

    function setVaulted() external;

    function setRevealed(string calldata collectionURI_) external;

    function setMintingDrops(address mintingDrops_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IERC11554K.sol";
import "./IGuardians.sol";
import "./IERC11554KController.sol";

/**
 * @dev {IFeesManager} interface:
 */
interface IFeesManager {
    function receiveFees(
        IERC11554K erc11554k,
        uint256 id,
        IERC20Upgradeable asset,
        uint256 _salePrice
    ) external;

    function calculateTotalFee(
        IERC11554K erc11554k,
        uint256 id,
        uint256 _salePrice
    ) external returns (uint256);

    function payGuardianFee(
        uint256 guardianFeeAmount,
        uint256 guardianClassFeeRateMultiplied,
        address guardian,
        uint256 storagePaidUntil,
        address payer,
        IERC20Upgradeable paymentAsset
    ) external;

    function refundGuardianFee(
        uint256 guardianFeeAmount,
        uint256 guardianClassFeeRateMultiplied,
        address guardian,
        uint256 storagePaidUntil,
        address recipient,
        IERC20Upgradeable paymentAsset
    ) external;

    function moveFeesBetweenGuardians(
        address guardianFrom,
        address guardianTo,
        IERC20Upgradeable asset
    ) external;

    function setGuardians(IGuardians guardians_) external;

    function setController(IERC11554KController controller_) external;

    function setGlobalTradingFee(uint256 globalTradingFee_) external;

    function setTradingFeeSplit(
        uint256 protocolSplit,
        uint256 guardianSplit
    ) external;

    function setExchange(address exchange_) external;

    function setVersion(bytes32 version_) external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IERC11554K.sol";
import "./IERC11554KController.sol";
import "./IFeesManager.sol";

/**
 * @dev {IGuardians} interface:
 */
interface IGuardians {
    enum GuardianFeeRatePeriods {
        SECONDS,
        MINUTES,
        HOURS,
        DAYS
    }

    function controllerStoreItem(
        IERC11554K collection,
        address mintAddress,
        uint256 id,
        address guardian,
        uint256 guardianClassIndex,
        uint256 guardianFeeAmount,
        uint256 numItems,
        address feePayer,
        IERC20Upgradeable paymentAsset
    ) external;

    function controllerTakeItemOut(
        address guardian,
        IERC11554K collection,
        uint256 id,
        uint256 numItems,
        address from
    ) external;

    function shiftGuardianFeesOnTokenMove(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function setController(IERC11554KController controller_) external;

    function setFeesManager(IFeesManager feesManager_) external;

    function setMinStorageTime(uint256 minStorageTime_) external;

    function setMinimumRequestFee(uint256 minimumRequestFee_) external;

    function setMaximumGuardianFeeSet(uint256 maximumGuardianFeeSet_) external;

    function setGuardianFeeSetWindow(uint256 guardianFeeSetWindow_) external;

    function moveItems(
        IERC11554K collection,
        uint256[] calldata ids,
        address oldGuardian,
        address newGuardian,
        uint256[] calldata newGuardianClassIndeces
    ) external;

    function copyGuardianClasses(
        address oldGuardian,
        address newGuardian
    ) external;

    function setActivity(address guardian, bool activity) external;

    function setPrivacy(address guardian, bool privacy) external;

    function setLogo(address guardian, string calldata logo) external;

    function setName(address guardian, string calldata name) external;

    function setPhysicalAddressHash(
        address guardian,
        bytes32 physicalAddressHash
    ) external;

    function setPolicy(address guardian, string calldata policy) external;

    function setRedirect(address guardian, string calldata redirect) external;

    function changeWhitelistUsersStatus(
        address guardian,
        address[] calldata users,
        bool whitelistStatus
    ) external;

    function removeGuardian(address guardian) external;

    function setGuardianClassMintingFee(
        address guardian,
        uint256 classID,
        uint256 mintingFee
    ) external;

    function setGuardianClassRedemptionFee(
        address guardian,
        uint256 classID,
        uint256 redemptionFee
    ) external;

    function setGuardianClassGuardianFeeRate(
        address guardian,
        uint256 classID,
        uint256 guardianFeeRate
    ) external;

    function setGuardianClassGuardianFeePeriodAndRate(
        address guardian,
        uint256 classID,
        GuardianFeeRatePeriods guardianFeeRatePeriod,
        uint256 guardianFeeRate
    ) external;

    function setGuardianClassURI(
        address guardian,
        uint256 classID,
        string calldata uri
    ) external;

    function setGuardianClassActiveStatus(
        address guardian,
        uint256 classID,
        bool activeStatus
    ) external;

    function setGuardianClassMaximumCoverage(
        address guardian,
        uint256 classID,
        uint256 maximumCoverage
    ) external;

    function addGuardianClass(
        address guardian,
        uint256 maximumCoverage,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 guardianFeeRate,
        GuardianFeeRatePeriods guardianFeeRatePeriod,
        string calldata uri
    ) external;

    function registerGuardian(
        address guardian,
        string calldata name,
        string calldata logo,
        string calldata policy,
        string calldata redirect,
        bytes32 physicalAddressHash,
        bool privacy
    ) external;

    function transferOwnership(address newOwner) external;

    function setVersion(bytes32 version_) external;

    function isAvailable(address guardian) external view returns (bool);

    function guardianInfo(
        address guardian
    )
        external
        view
        returns (
            bytes32,
            string memory,
            string memory,
            string memory,
            string memory,
            bool,
            bool
        );

    function guardianWhitelist(
        address guardian,
        address user
    ) external view returns (bool);

    function delegated(address guardian) external view returns (address);

    function getRedemptionFee(
        address guardian,
        uint256 classID
    ) external view returns (uint256);

    function getMintingFee(
        address guardian,
        uint256 classID
    ) external view returns (uint256);

    function isClassActive(
        address guardian,
        uint256 classID
    ) external view returns (bool);

    function minStorageTime() external view returns (uint256);

    function feesManager() external view returns (address);

    function stored(
        address guardian,
        IERC11554K collection,
        uint256 id
    ) external view returns (uint256);

    function whereItemStored(
        IERC11554K collection,
        uint256 id
    ) external view returns (address);

    function itemGuardianClass(
        IERC11554K collection,
        uint256 id
    ) external view returns (uint256);

    function guardianFeePaidUntil(
        address user,
        address collection,
        uint256 id
    ) external view returns (uint256);

    function isFeeAboveMinimum(
        uint256 guardianFeeAmount,
        uint256 numItems,
        address guardian,
        uint256 guardianClassIndex
    ) external view returns (bool);

    function getGuardianFeeRateByCollectionItem(
        IERC11554K collection,
        uint256 itemId
    ) external view returns (uint256);

    function getGuardianFeeRate(
        address guardian,
        uint256 guardianClassIndex
    ) external view returns (uint256);

    function isWhitelisted(address guardian) external view returns (bool);

    function inRepossession(
        address user,
        IERC11554K collection,
        uint256 id
    ) external view returns (uint256);

    function isDelegated(
        address guardian,
        address delegatee,
        IERC11554K collection
    ) external view returns (bool);
}