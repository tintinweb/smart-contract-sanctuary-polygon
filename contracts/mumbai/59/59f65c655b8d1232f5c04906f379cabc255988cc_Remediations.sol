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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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

    function safePermit(
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

/**
 * @dev ContractControl contract.
 * Contract intended to be used via inheritance in other contract to maintain the Admin address, but also
 * A list of addresses that are set by the Admin to execute authorized admin function that should be delegated.
 */
contract ContractControl is Initializable, AccessControlUpgradeable {
    /// @notice Address of Admin that controls this contract.
    address public currentAdmin;

    /// @dev Role for protocol assignees.
    bytes32 public constant PROTOCOL_ASSIGNEE_ROLE =
        keccak256("PROTOCOL_ASSIGNEE_ROLE");

    /// @dev Event thrown when a protocol assginee has been added.
    event ProtocolAssigneeAdded(address assignee);

    /// @dev Event thrown when a protocol assginee has been removed.
    event ProtocolAssigneeRemoved(address assignee);

    /// @dev Event thrown when Admin address has been switched.
    event AdminAddressSwitched(address newAdminAddress);

    /// @dev Modifier to restrict calls to the Admin.
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "ContractControl: Not Admin");
        _;
    }

    /// @dev Modifier to restrict calls to a protocol assignee.
    modifier onlyProtocolAssignee() {
        require(
            isProtocolAssignee(_msgSender()),
            "ContractControl: Not protocol assignee"
        );
        _;
    }

    /// @dev Modifier to restrict calls to a protocol assignee OR the admin.
    modifier onlyProtocolAssigneeOrAdmin() {
        require(
            isProtocolAssignee(_msgSender()) || isAdmin(_msgSender()),
            "ContractControl: Not protocol assignee or Admin"
        );
        _;
    }

    /**
     * @notice Initialize ContractControl contract.
     * @param _adminAddress The address of the admin.
     */
    function initializeContractControl(
        address _adminAddress
    ) external virtual initializer {
        __ContractControl_init(_adminAddress);
    }

    /**
     * @notice Switches the current admin address for another. Callable only by current admin.
     * @param _newAdminAddress The replacement address of the admin.
     */
    function switchAdminAddress(address _newAdminAddress) external onlyAdmin {
        _grantRole(DEFAULT_ADMIN_ROLE, _newAdminAddress);
        _revokeRole(DEFAULT_ADMIN_ROLE, currentAdmin);
        currentAdmin = _newAdminAddress;
        emit AdminAddressSwitched(_newAdminAddress);
    }

    /**
     * @notice Gives an address the role of protocol representative.
     * @param _newProtocolAssignee Address off protocol representative.
     */
    function addProtocolAssignee(
        address _newProtocolAssignee
    ) external onlyAdmin {
        grantRole(PROTOCOL_ASSIGNEE_ROLE, _newProtocolAssignee);
        emit ProtocolAssigneeAdded(_newProtocolAssignee);
    }

    /**
     * @notice Removes from an address the role of protocol representative.
     * @param _protocolAssigneeToRemove Address off protocol representative.
     */
    function removeProtocolAssignee(
        address _protocolAssigneeToRemove
    ) external onlyAdmin {
        revokeRole(PROTOCOL_ASSIGNEE_ROLE, _protocolAssigneeToRemove);
        emit ProtocolAssigneeRemoved(_protocolAssigneeToRemove);
    }

    /**
     * @notice Checks if an adddress is a protocol assignee.
     * @param toCheck Address to check.
     * @return boolean that represents if address is protocol representative or not.
     */
    function isProtocolAssignee(address toCheck) public view returns (bool) {
        return hasRole(PROTOCOL_ASSIGNEE_ROLE, toCheck);
    }

    /**
     * @notice Checks if an adddress is the current admin.
     * @param toCheck Address to check.
     * @return boolean that represents if address is current admin or not.
     */
    function isAdmin(address toCheck) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, toCheck) && currentAdmin == toCheck;
    }

    /**
     * @dev Initialize ContractControl contract via inheritance.
     * @param _adminAddress The address of the admin.
     */
    function __ContractControl_init(
        address _adminAddress
    ) internal onlyInitializing {
        __AccessControl_init();
        currentAdmin = _adminAddress;
        _grantRole(DEFAULT_ADMIN_ROLE, currentAdmin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAuditsClaims {
    function treasuryAddress() external returns (address);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IVotingEscrow {
    function slashPool(uint256 slashAmount, address destination) external;

    function slashGuardian(
        address guardian,
        uint256 requestedSlashAmount,
        address destination
    ) external;

    function token() external returns (IERC20Upgradeable);

    function totalLocked() external returns (uint256);

    function getLockSize(address user) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ContractControl.sol";
import "./interfaces/IVotingEscrow.sol";
import "./interfaces/IERC11554KController.sol";
import "./interfaces/IERC11554K.sol";
import "./interfaces/IAuditsClaims.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @dev Remediations contract where remediations are processed. There are two kinds of remediations:
 * fully automatic remediations that are triggered on the Ethereum AuditClaims contract,
 * and centralized remediations that are triggered by an offchain service.
 * This contract is intended to be deployed only on Ethereum.
 */
contract Remediations is Initializable, ContractControl {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev Possible status of a remediation.
    enum RemediationStatus {
        COMPLETED_ON_CHAIN,
        COMPLETED_CENTRALIZED,
        INSUFFICIENT_FUNDS
    }

    /// @dev Remediation Struct.
    struct Remediation {
        /// @dev The amount of token being remediated.
        uint256 remediationAmount;
        /// @dev The address of user being remediated.
        address remediationReceiver;
        /// @dev Timestamp of remediation.
        uint256 remediationTimestamp;
        /// @dev The id of the claim being processed.
        uint32 claimId;
        /// @dev The chain the asset and the claim exist on.
        uint16 chainId;
        /// @dev Current status of remediation.
        RemediationStatus status;
        /// @dev Number of items that are being remediated.
        uint88 numItems;
        /// @dev Reference to any offchain processes done before remediation.
        string offchainRemediationReference;
    }

    /// @dev Number used to calculate percentages in the calculation to get the guardian slash amount in a remediation.
    uint256 public constant PERCENTAGE_FACTOR = 10000;

    /// @dev Mapping of remediation ids to unique remediations.
    mapping(uint256 => Remediation) public remediations;

    /// @dev number of remediations in the system.
    uint256 public numRemediations;

    /// @dev Mapping of guardian addresses to their amount of debt to the pool.
    mapping(address => uint256) public poolSlashDebts;

    /// @dev The percentage of claims that come from the guardian's stake, as opposed to the larger staking pool.
    uint256 public coverageRatio;

    /// @dev The total amount of debt that the guardian can be in debt to the staking pool.
    /// When the value of the total debt of a guardian exceeds the risk cap for that guardian, remediation happens only from their self stake.
    uint256 public riskCap;

    /// @dev The voting power contract.
    IVotingEscrow public votingPowerContract;

    /// @dev The controler contract.
    IERC11554KController public controller;

    /// @dev The audits and claims contract on Ethereum.
    IAuditsClaims public auditsClaimsContract;

    /// @notice Version of the contract
    bytes32 public version;

    /// @dev Emitted when a remediation has failed because there are not enough funds.
    event InsufficientFunds(
        uint256 indexed claimId,
        uint256 indexed remediationId,
        string reason
    );

    /// @dev Emitted when a remediation has been completed.
    event Remediated(
        uint256 indexed claimId,
        uint256 indexed remediationId,
        Remediation remediation
    );

    /// @dev Emitted when a guardian has paid debt back.
    event DebtPayment(address payer, address receiver, uint256 amount);

    /// @dev Emitted when protocol punishes a guardian for a process fault.
    event ProcessFault(
        address caller,
        address guardian,
        uint256 amount,
        string reason
    );

    /// @dev Emitted when the coverage ratio is changed.
    event NewCoverageRatio(uint256 newCoverageRatio);

    /// @dev Emitted when the risk cap is changed.
    event NewRiskCap(uint256 newRiskCap);

    /// @dev Emitted when voting power contract is changed.
    event ChangedVotingPowerContract(IVotingEscrow newVotingPowerContract);

    /// @dev Emitted when controller contract is changed.
    event ChangedControllerContract(IERC11554KController newControllerContract);

    /// @dev Emitted when claims & audits contract is changed.
    event ChangedClaimsContract(IAuditsClaims newClaimsContract);

    /**
     * @notice Initialize Remediations contract.
     * @param _riskcap Initial risk cap.
     * @param _coverageRatio Initial coverage ratio.
     * @param _votingPower Voting powe contract.
     * @param _auditsClaimsContract Audits & Claims contract on Ethereum.
     * @param _controller Controller contract.
     * @param _version Version of contract
     */
    function initialize(
        uint256 _riskcap,
        uint256 _coverageRatio,
        IVotingEscrow _votingPower,
        IAuditsClaims _auditsClaimsContract,
        IERC11554KController _controller,
        bytes32 _version
    ) external virtual initializer {
        __ContractControl_init(_msgSender());
        require(
            _coverageRatio <= PERCENTAGE_FACTOR,
            "Remediations: invalid coverage ratio"
        );
        riskCap = _riskcap;
        coverageRatio = _coverageRatio;
        votingPowerContract = _votingPower;
        auditsClaimsContract = _auditsClaimsContract;
        controller = _controller;
        version = _version;
    }

    /**
     * @notice Sets the coverage ratio.
     *
     * Requirements:
     *
     * 1) Caller must be protocol admin for this contract.
     * 2) Coverage ratio must be smaller than PERCENTAGE_FACTOR.
     * @param _coverageRatio Coverage ratio.
     */
    function setCoverageRatio(uint256 _coverageRatio) external onlyAdmin {
        require(
            _coverageRatio <= PERCENTAGE_FACTOR,
            "Remediations: invalid coverage ratio"
        );
        coverageRatio = _coverageRatio;
        emit NewCoverageRatio(coverageRatio);
    }

    /**
     * @notice Sets the risk cap.
     *
     * Requirements:
     *
     * 1) Caller must be protocol admin for this contract.
     * @param _riskcap risk cap.
     */
    function setRiskCap(uint256 _riskcap) external onlyAdmin {
        riskCap = _riskcap;
        emit NewRiskCap(riskCap);
    }

    /**
     * @dev Sets the version of the contract.
     * @param version_ New version of contract.
     */
    function setVersion(
        bytes32 version_
    ) external virtual onlyProtocolAssignee {
        version = version_;
    }

    /**
     * @notice Sets the voting power contract.
     *
     * Requirements:
     *
     * 1) Caller must be protocol admin for this contract.
     * @param _newVotingPower voting power contract.
     */
    function changVotingPowerContract(
        IVotingEscrow _newVotingPower
    ) external onlyAdmin {
        votingPowerContract = _newVotingPower;
        emit ChangedVotingPowerContract(votingPowerContract);
    }

    /**
     * @notice Sets the controller contract.
     *
     * Requirements:
     *
     * 1) Caller must be protocol admin for this contract.
     * @param _newController controller contract.
     */
    function changeControllerContract(
        IERC11554KController _newController
    ) external onlyAdmin {
        controller = _newController;
        emit ChangedControllerContract(controller);
    }

    /**
     * @notice Sets the claims & audits contract.
     *
     * Requirements:
     *
     * 1) Caller must be protocol admin for this contract.
     * @param _newClaims claims and audits contract.
     */
    function changeClaimsContract(IAuditsClaims _newClaims) external onlyAdmin {
        auditsClaimsContract = _newClaims;
        emit ChangedClaimsContract(auditsClaimsContract);
    }

    /**
     * @notice Onchain remediation function called by the claims and audits contract upon a ruling.
     *
     * Requirements:
     *
     * 1) Caller must be the claims and audits contract.
     * 2) For a successful remediation, the voting power contract and the guardian must have enough tokens to cover the slashes.
     * @param claimId The associated claim that has been ruled on.
     * @param guardian Guardian that stores the items in the claim.
     * @param remediationAmount Amount of token that is being remediated.
     * @param remediationReceiver Address of user that will be remediated.
     * @param numItemsRemediated Number of items that are to be remediated.
     * @param collection Collection that is beinf remediated.
     * @param tokenId Item in collection that will be remediated.
     */
    function onchainRemediation(
        uint32 claimId,
        address guardian,
        uint256 remediationAmount,
        address remediationReceiver,
        uint88 numItemsRemediated,
        IERC11554K collection,
        uint256 tokenId
    ) external {
        require(
            _msgSender() == address(auditsClaimsContract),
            "Remediations: not audits contract"
        );
        _remediate(
            claimId,
            guardian,
            remediationAmount,
            remediationReceiver,
            numItemsRemediated,
            collection,
            tokenId,
            uint16(block.chainid),
            "",
            RemediationStatus.COMPLETED_ON_CHAIN
        );
    }

    /**
     * @notice Centralized remediation function called by a offchain service. Remediation receiver gets remediation on Ethereum.
     *
     * Requirements:
     *
     * 1) Caller must be a protocol assignee.
     * 2) For a successful remediation, the voting power contract and the guardian must have enough tokens to cover the slashes.
     * @param chainId The chain id where the assets being remediated lived.
     * @param claimId The associated claim that has been ruled on.
     * @param guardian Guardian that stores the items in the claim.
     * @param remediationAmount Amount of token that is being remediated.
     * @param remediationReceiver Address of user that will be remediated.
     * @param numItemsRemediated Number of items that are to be remediated.
     * @param offchainReference Reference to any processes that were done offchain, like token burning.
     */
    function centralizedRemediation(
        uint16 chainId,
        uint32 claimId,
        address guardian,
        uint256 remediationAmount,
        address remediationReceiver,
        uint88 numItemsRemediated,
        string calldata offchainReference
    ) external onlyProtocolAssignee {
        _remediate(
            claimId,
            guardian,
            remediationAmount,
            remediationReceiver,
            numItemsRemediated,
            IERC11554K(address(0)), //note: not used in centralized remediation. Burn has to happen before
            0,
            chainId,
            offchainReference,
            RemediationStatus.COMPLETED_CENTRALIZED
        );
    }

    /**
     * @notice User pays back debt that a guardian incurred during a remediation's pool slash.
     *
     * Requirements:
     *
     * 1) Guardian at hand must have non zero pool slash debt.
     * 2) Caller must have approved the transfer.
     * @param guardian guardian whose debt is being cleared.
     */
    function payBackDebt(address guardian) external {
        require(
            poolSlashDebts[guardian] > 0,
            "Remediations: guardian has 0 debt"
        );

        uint256 debt = poolSlashDebts[guardian];
        poolSlashDebts[guardian] = 0;

        votingPowerContract.token().safeTransferFrom(
            _msgSender(),
            auditsClaimsContract.treasuryAddress(),
            debt
        );
        emit DebtPayment(_msgSender(), guardian, debt);
    }

    /**
     * @notice Protocol punishes a guardian for a process fault, via a guardian slash. Funds go to Ethereum treasury address.
     *
     * Requirements:
     *
     * 1) Caller must be protocol admin or assignee.
     * 2) The pool and the guardian's lock must have enough tokens.
     * @param guardian guardian who is being punished.
     * @param amount Amount of token the guardian will be slashed for.
     * @param reason Reason for the punishment.
     */
    function processFaultPunishment(
        address guardian,
        uint256 amount,
        string calldata reason
    ) external onlyProtocolAssigneeOrAdmin {
        require(
            votingPowerContract.totalLocked() >= amount,
            "Remediations: Insufficient amount in pool"
        );
        require(
            votingPowerContract.getLockSize(guardian) >= amount,
            "Remediations: Insufficient amount in guardian lock"
        );

        votingPowerContract.slashGuardian(
            guardian,
            amount,
            auditsClaimsContract.treasuryAddress()
        );

        emit ProcessFault(_msgSender(), guardian, amount, reason);
    }

    /// @dev The chain id that remediations will be processed in, as this contract only lives in a single chain.
    function remediationChainId() public view returns (uint256) {
        return block.chainid;
    }

    function _remediate(
        uint32 claimId,
        address guardian,
        uint256 remediationAmount,
        address remediationReceiver,
        uint88 numItemsRemediated,
        IERC11554K collection,
        uint256 tokenId,
        uint16 chainId,
        string memory ref,
        RemediationStatus successState
    ) internal {
        Remediation memory newRemediation = Remediation(
            remediationAmount,
            remediationReceiver,
            block.timestamp,
            claimId,
            chainId,
            successState,
            numItemsRemediated,
            ref
        );
        if (votingPowerContract.totalLocked() < remediationAmount) {
            {
                newRemediation.status = RemediationStatus.INSUFFICIENT_FUNDS;
                uint256 remediationId = _writeRemediation(newRemediation);

                emit InsufficientFunds(
                    claimId,
                    remediationId,
                    "pool<remediationAmount"
                );
            }
        } else if (
            votingPowerContract.getLockSize(guardian) <
            _calculateGuardianSlashAmount(remediationAmount, guardian)
        ) {
            {
                newRemediation.status = RemediationStatus.INSUFFICIENT_FUNDS;
                uint256 remediationId = _writeRemediation(newRemediation);

                emit InsufficientFunds(
                    claimId,
                    remediationId,
                    "guardian lock<guardian slash"
                );
            }
        } else {
            {
                uint256 remediationId = _writeRemediation(newRemediation);
                _triggerSlashes(
                    remediationAmount,
                    _calculateGuardianSlashAmount(remediationAmount, guardian),
                    guardian,
                    remediationReceiver
                );

                if (chainId == remediationChainId()) {
                    controller.remediationBurn(
                        collection,
                        remediationReceiver,
                        tokenId,
                        numItemsRemediated
                    );
                }

                emit Remediated(claimId, remediationId, newRemediation);
            }
        }
    }

    function _writeRemediation(
        Remediation memory newRemediation
    ) internal returns (uint256) {
        uint256 remediationId = numRemediations;
        remediations[remediationId] = newRemediation;
        numRemediations++;
        return remediationId;
    }

    function _triggerSlashes(
        uint256 totalRemediationAmount,
        uint256 guardianSlashAmount,
        address guardian,
        address remediationReceiver
    ) internal returns (uint256) {
        uint256 poolSlashAmount = totalRemediationAmount - guardianSlashAmount;
        if (poolSlashAmount > 0) {
            poolSlashDebts[guardian] += poolSlashAmount;
            votingPowerContract.slashPool(poolSlashAmount, remediationReceiver);
        }
        votingPowerContract.slashGuardian(
            guardian,
            guardianSlashAmount,
            remediationReceiver
        );
        return poolSlashAmount;
    }

    function _calculateGuardianSlashAmount(
        uint256 remediationAmount,
        address guardian
    ) internal view returns (uint256) {
        uint256 guardianSlashAmount;
        if (poolSlashDebts[guardian] >= riskCap) {
            guardianSlashAmount = remediationAmount;
        } else {
            guardianSlashAmount =
                (coverageRatio * remediationAmount) /
                PERCENTAGE_FACTOR;
        }
        return guardianSlashAmount;
    }
}