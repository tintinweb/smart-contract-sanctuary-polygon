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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./EIP712.sol";
import "./Token.sol";
//import "./MerkleVerifier.sol";
import { InputBet, Input, SignatureVersion } from "./BetStructs.sol";
import "./BetDexEvent.sol";

contract BetDex is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable, EIP712, PausableUpgradeable, BetDexEvent {
    bool private initialized;
    bytes32 public constant ROLE_RANDOMIZER = keccak256("ROLE_RANDOMIZER");
    bytes32 public constant ROLE_MANAGER = keccak256("ROLE_MANAGER");
	bytes32 public constant ROLE_AUDITOR = keccak256("ROLE_AUDITOR");

    uint8 public constant ODDS_DECIMAL = 4;
	uint8 public constant SIGNATURE_TIMESTAMP_THRESHOLD = 90;
	uint16 public constant WITHDRAWAL_TIMEOUT = 60 * 24 * 2; // TODO:: will change?
	string public constant NAME = "BetDex";
	string public constant VERSION = "1.0";

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ECDSAUpgradeable for bytes32;
	using MathUpgradeable for uint256;

    address public signerAddress; // Signer role (1:1 mapping)
    mapping(bytes32 => mapping(address => uint256))
	public userBalances;
	mapping(bytes32 => mapping(uint256 => bytes32[]))
		private gameBetsArr;
	mapping(uint256 => bytes32[])
		private gameBetRoomsArr;
	mapping(uint256 => mapping(bytes32 => bool))
		private gameBetRoomsArrState;
    mapping(address => mapping(uint256 => bool)) public usedNonce;
    mapping(bytes32 => Room) public rooms;
	mapping(address => uint256) private minBetLimit;
	mapping(address => uint256) public withdrawalDailyLimit;
	mapping(uint256 => PendingWithdrawal) public pendingWithdrawals;
	mapping(address => mapping(address => mapping(uint256 => uint256))) public userWithdrawalCount; // userAddress, contractAddress, day, limit
	mapping(uint256 => uint256) gameBetRoomsArrProcessed;
	mapping(bytes32 => mapping(uint256 => uint256)) gameBetsArrProcessed;
	mapping(address => uint256) public gameBetFee;
	mapping(uint256 => bool) public matchResolved;
	uint256 public pendingWithdrawalId;
	uint256 public maxOdds;

	struct PendingWithdrawal {
		uint256 id;
		bytes32 roomId;
		address userAddress;
		uint256 amount;
		uint256 time;
		bool executed;
	}

    struct Room {
		address owner;
		address contractAddress;
		bytes32 id;
		uint256 reverse;
		uint256 lockedReverse;
		uint256 availableFee;
    }

    struct Bet {
		uint16 target;
		address bettor;
        uint256 potentialWinningAmount;
		uint256 amount;
    }

	mapping(uint16 => bool) private targets;
	mapping(bytes32 => Bet) public bets;
	mapping(uint16 => bool) private refundTargets;

    function initialize(address _address) public initializer {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        _setupRole(DEFAULT_ADMIN_ROLE, _address);
        _setupRole(ROLE_MANAGER, _address);
        signerAddress = _address;
		maxOdds = 10 * (10 ** ODDS_DECIMAL); // TODO::Define max odd
    }

	function _getDomainSeparator() internal view override(EIP712) returns (bytes32) {
		return _hashDomain(EIP712Domain({
			name              : NAME,
			version           : VERSION,
			chainId           : block.chainid,
			verifyingContract : address(this)
		}));
	}

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "PERMISSION_DENIED");
        _;
    }

    modifier onlyOwners(bytes32 roomId) {
        require(
			rooms[roomId].owner == msg.sender,
            "PERMISSION_DENIED"
        );
        _;
    }

    function createRoomWithToken(
        bytes32 roomId,
        address mainOwner,
        address contractAddress
    ) external whenNotPaused {
        Room storage room = rooms[roomId];
        require(room.id == 0, "ROOM_ALREADY_EXISTS");
        require(
            IERC20Upgradeable(contractAddress).totalSupply() > 0,
            "INVALID_TOKEN"
        );
        room.id = roomId;
		room.owner = mainOwner;
		room.contractAddress = contractAddress;
		emit RoomCreated(roomId, contractAddress, mainOwner);
    }

    /// @notice Deposit reserves into the room. Only available to room owners.
    /// @param _amount Amount to deposit into the room.
    /// @notice Must approve enough amount for ERC20 transfer before calling this function.
    function depositReserves(
        bytes32 roomId,
        uint256 _amount,
		uint256 _feeAmount
    ) external whenNotPaused nonReentrant onlyOwners(roomId) {
		Room storage room = rooms[roomId];
        Token.deposit(room.contractAddress, msg.sender, _amount + _feeAmount);
        room.reverse += _amount;
		room.availableFee += _feeAmount;
        emit ReservesDeposited(roomId, msg.sender, room.contractAddress, _amount);
		emit FeeDeposited(roomId, msg.sender, room.contractAddress, _feeAmount);
    }

    /// @notice Withdraw from the room. Only available to room owners.
    /// @param _recipient Address of the withdraw recipient.
    /// @param _amount Amount to withdraw.
    function withdrawReserves(
        bytes32 roomId,
        address _recipient,
        uint256 _amount
    ) external whenNotPaused nonReentrant onlyOwners(roomId) {
        require(rooms[roomId].lockedReverse == 0, "LOCKED");
        uint256 roomBalance = roomAvailableReserve(roomId);
        require(roomBalance >= _amount, "INSUFFICIENT_BALANCE");
        rooms[roomId].reverse -= _amount;
        Token.withdrawal(rooms[roomId].contractAddress, _recipient, _amount);
        emit ReservesWithdrawn(
            roomId,
			rooms[roomId].contractAddress,
            msg.sender,
            _recipient,
            _amount
        );
    }

	function adminWithdrawBetFee(
		address contractAddress,
		address _recipient,
		uint256 _amount
	) external whenNotPaused onlyAdmin nonReentrant {
		require(gameBetFee[contractAddress] >= _amount, "INSUFFICIENT_BALANCE");
		gameBetFee[contractAddress] -= _amount;
		Token.withdrawal(contractAddress, _recipient, _amount);
		emit AdminFeeWithdrawn(
			contractAddress,
			msg.sender,
			_recipient,
			_amount
		);
	}

    /// @notice User withdrawal
    /// @param roomId Room Id
    /// @param _amount Amount to withdraw.
    function userWithdrawal(
        bytes32 roomId,
        uint256 _amount
    ) external whenNotPaused nonReentrant {
		Room memory room = rooms[roomId];
        require(
            userBalances[roomId][msg.sender] >= _amount,
            "INSUFFICIENT_BALANCE"
        );
        userBalances[roomId][msg.sender] -= _amount;
		uint256 currentDay = block.timestamp - (block.timestamp % 1 days);
		userWithdrawalCount[msg.sender][room.contractAddress][currentDay] += _amount;
		if (withdrawalDailyLimit[room.contractAddress] > 0 && userWithdrawalCount[msg.sender][room.contractAddress][currentDay] >= withdrawalDailyLimit[room.contractAddress]) { // exceed daily limit
			uint256 currentPendingWithdrawalId = ++pendingWithdrawalId;
			PendingWithdrawal storage pendingWithdrawal = pendingWithdrawals[currentPendingWithdrawalId];
			pendingWithdrawal.id = currentPendingWithdrawalId;
			pendingWithdrawal.roomId = roomId;
			pendingWithdrawal.userAddress = msg.sender;
			pendingWithdrawal.amount = _amount;
			pendingWithdrawal.time = block.timestamp;
			emit PendingWithdrawalCreated(pendingWithdrawal.id, msg.sender, room.contractAddress, _amount);
		} else {
			Token.withdrawal(room.contractAddress, msg.sender, _amount);
		}
    }

	function approveWithdrawal(uint256 id, uint256 amount) external whenNotPaused onlyRole(ROLE_AUDITOR) nonReentrant {
		PendingWithdrawal storage pendingWithdrawal = pendingWithdrawals[id];
		require(pendingWithdrawal.id == id, "PENDING_WITHDRAWAL_NOT_EXISTS");
		require(pendingWithdrawal.executed == false, "WITHDRAWAL_PROCESSED");
		require(amount > 0 && amount <= pendingWithdrawal.amount, "INVALID_WITHDRAWAL_AMOUNT");
		pendingWithdrawal.executed = true;
		uint256 feeToUser = pendingWithdrawal.amount - amount;
		if (feeToUser > 0) {
			userBalances[pendingWithdrawal.roomId][pendingWithdrawal.userAddress] += feeToUser;
		}
		if (amount > 0) {
			Token.withdrawal(rooms[pendingWithdrawal.roomId].contractAddress, pendingWithdrawal.userAddress, amount);
		}
	}

	function batchApproveWithdrawal(uint256[] calldata ids) external whenNotPaused onlyRole(ROLE_AUDITOR) nonReentrant {
		uint idLength = ids.length;
    	address roomContractAddress;
    	address userAddress;
    	uint256 totalAmount;

		for (uint i; i < idLength; i = _uncheckedInc(i)) {
			PendingWithdrawal storage pendingWithdrawal = pendingWithdrawals[ids[i]];
			require(pendingWithdrawal.id == ids[i], "PENDING_WITHDRAWAL_NOT_EXISTS");
			require(!pendingWithdrawal.executed, "WITHDRAWAL_PROCESSED");
			if (i == 0) {
				roomContractAddress = rooms[pendingWithdrawal.roomId].contractAddress;
				userAddress = pendingWithdrawal.userAddress;
			} else {
				address tempRoomContractAddress = rooms[pendingWithdrawal.roomId].contractAddress;
				address tempUserAddress = pendingWithdrawal.userAddress;

				if (roomContractAddress != tempRoomContractAddress || userAddress != tempUserAddress) {
					Token.withdrawal(roomContractAddress, userAddress, totalAmount);
					roomContractAddress = tempRoomContractAddress;
					userAddress = tempUserAddress;
					totalAmount = 0;
				}
			}
			totalAmount += pendingWithdrawal.amount;
			pendingWithdrawal.executed = true;
		}

		if (totalAmount > 0) {
			Token.withdrawal(roomContractAddress, userAddress, totalAmount);
		}
	}

	function rejectWithdrawal(uint256 id, uint256 feeToRoom) external whenNotPaused onlyRole(ROLE_AUDITOR) {
		PendingWithdrawal storage pendingWithdrawal = pendingWithdrawals[id];
		require(pendingWithdrawal.id == id, "PENDING_WITHDRAWAL_NOT_EXISTS");
		require(pendingWithdrawal.executed == false, "WITHDRAWAL_PROCESSED");
		pendingWithdrawal.executed = true;
		rooms[pendingWithdrawal.roomId].reverse += feeToRoom;
		uint256 feeToUser = pendingWithdrawal.amount - feeToRoom;
		userBalances[pendingWithdrawal.roomId][pendingWithdrawal.userAddress] += feeToUser;
		emit RejectWithdrawal(id, pendingWithdrawal.roomId, rooms[pendingWithdrawal.roomId].contractAddress, msg.sender, pendingWithdrawal.userAddress, feeToUser, feeToRoom);
	}

	function userRequestWithdrawalTimeout(uint256 id) external whenNotPaused nonReentrant {
		PendingWithdrawal storage pendingWithdrawal = pendingWithdrawals[id];
		require(pendingWithdrawal.id == id, "PENDING_WITHDRAWAL_NOT_EXISTS");
		require(pendingWithdrawal.executed == false, "WITHDRAWAL_PROCESSED");
		require(pendingWithdrawal.userAddress == msg.sender, "NOT_REQUEST_BY_SENDER");
		require(block.timestamp - WITHDRAWAL_TIMEOUT >= pendingWithdrawal.time, "PENDING_ADMIN_APPROVAL");
		pendingWithdrawal.executed = true;
		Token.withdrawal(rooms[pendingWithdrawal.roomId].contractAddress, pendingWithdrawal.userAddress, pendingWithdrawal.amount);
	}

	function setMaxOdds(uint256 odds) external onlyAdmin {
		maxOdds = odds;
		emit MaxBetOddsLimit(odds);
	}

    /// @notice Get current amount of available reserves.
    function roomAvailableReserve(bytes32 roomId)
        public
        view
        returns (uint256)
    {
        return
            rooms[roomId].reverse -
            rooms[roomId].lockedReverse;
    }

    function getUserBalance(
        bytes32 roomId,
        address userAddress
    ) public view returns (uint256) {
        return userBalances[roomId][userAddress];
    }

	/**
     * @dev Verify ECDSA signature
     * @param signer Expected signer
     * @param digest Signature preimage
     * @param v v
     * @param r r
     * @param s s
     */
	function _verify(
		address signer,
		bytes32 digest,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal pure returns (bool) {
		require(v == 27 || v == 28, "Invalid v parameter");
		address recoveredSigner = ecrecover(digest, v, r, s);
		if (recoveredSigner == address(0)) {
			return false;
		} else {
			return signer == recoveredSigner;
		}
	}

	function _validateSignatures(Input calldata input, bytes32 hash)
		internal
		view
		returns (bool)
	{
		require((input.timestamp + SIGNATURE_TIMESTAMP_THRESHOLD) >= block.timestamp, "INVALID_SIGNATURE");
		return _validateAuthorization(keccak256(abi.encodePacked(hash, input.timestamp)), input.v, input.r, input.s);
	}

	function _validateAuthorization(
		bytes32 hash,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal view returns (bool) {
		bytes32 hashToSign;
		hashToSign = _hashToSign(hash);
		return _verify(signerAddress, hashToSign, v, r, s);
	}

	function batchSignedBet(Input calldata input) external whenNotPaused nonReentrant {
		require(usedNonce[input.bets[0].bettor][input.nonce] == false, "Nonce already used");
		usedNonce[input.bets[0].bettor][input.nonce] = true;
		bytes32[] memory betHashes = _hashBets(input.bets, input.nonce);
		bytes32 betSignHash = keccak256(abi.encodePacked(betHashes));
		require(_validateSignatures(input, betSignHash), "Invalid signature");
		(uint256 totalBetAmount, uint256 totalPotentialWinningAmount) = _preparePlaceBets(input, betHashes);
		_transferFees(input.roomId, input.bets[0].bettor, totalBetAmount);
		_transferRoomReverse(input.roomId, totalBetAmount, totalPotentialWinningAmount);
	}

	function setMatchResolved(uint256 matchId) external whenNotPaused nonReentrant onlyRole(ROLE_MANAGER) {
		matchResolved[matchId] = true;
	}

	function _preparePlaceBets(Input calldata input, bytes32[] memory betHashes) internal returns (uint256, uint256) {
		uint256 totalPotentialWinningAmount;
		uint256 totalBetAmount;
		address bettorAddress;
		uint betLength = input.bets.length;
		for (uint i = 0; i < betLength; i = _uncheckedInc(i)) {
			if (i == 0) {
				bettorAddress = input.bets[0].bettor;
			}
			require(input.bets[i].amount > minBetLimit[rooms[input.roomId].contractAddress], "Invalid amount");
			require(bettorAddress == input.bets[i].bettor, "Not allow multiple bettor");
			require(input.bets[i].odds <= maxOdds, "Exceed Max Odds");
			require(matchResolved[input.bets[i].matchId] == false, "Match resolved");
			uint256 potentialWinningAmount = (input.bets[i].amount * input.bets[i].odds) / (10**ODDS_DECIMAL);
			totalPotentialWinningAmount += potentialWinningAmount;
			totalBetAmount += input.bets[i].amount;
			// Start 44000 gas fee
			bytes32 betHash = betHashes[i];
			Bet storage myBet = bets[betHash];
			require(myBet.bettor == address(0), "BET_EXISTS");
			myBet.bettor = input.bets[i].bettor;
			myBet.target = input.bets[i].target;
			myBet.potentialWinningAmount = potentialWinningAmount;
			myBet.amount = input.bets[i].amount;
			// end 44000 gas fee
			// start 63000
			//			gameBets[roomId][signingBets[i].matchId][signingBets[i].gameType].add(betSlipId);
			//			gameBetRooms[signingBets[i].matchId][signingBets[i].gameType].add(roomId);
			// end 63000
			// start gas 55278
			gameBetsArr[input.roomId][input.bets[i].matchId].push(betHashes[i]);
			if (!gameBetRoomsArrState[input.bets[i].matchId][input.roomId]) {
				gameBetRoomsArrState[input.bets[i].matchId][input.roomId] = true;
				gameBetRoomsArr[input.bets[i].matchId].push(input.roomId);
			}
			// end gas

			emit BetPlaced(
				input.bets[i].matchId,
				myBet.bettor,
				betHashes[i],
				input.roomId
			);
		}
		return (totalBetAmount, totalPotentialWinningAmount);
	}

	function _transferFees(bytes32 roomId, address userAddress, uint256 amount) internal {
		address contractAddress = rooms[roomId].contractAddress;
		uint256 transferAmount;
		uint256 userBalance = userBalances[roomId][userAddress];
		if (userBalance == 0) {
			Token.deposit(contractAddress, userAddress, amount);
			emit TransferToRoom(
				roomId,
				contractAddress,
				userAddress,
				amount
			);
		} else if (userBalance < amount) {
			transferAmount = amount - userBalance;
			userBalances[roomId][userAddress] = 0;
			Token.deposit(contractAddress, userAddress, transferAmount);
			emit TransferToRoom(
				roomId,
				contractAddress,
				userAddress,
				transferAmount
			);
		} else {
			userBalances[roomId][userAddress] = userBalance - amount;
		}
	}

	function _transferRoomReverse(bytes32 roomId, uint256 betAmount, uint256 potentialWinningAmount) internal {
		rooms[roomId].reverse += betAmount;
		require(
			roomAvailableReserve(roomId) >=
			potentialWinningAmount,
			"FAILED_TO_BET"
		);
		rooms[roomId].lockedReverse += potentialWinningAmount;
	}

	function transferBetFee(bytes32 roomId, uint256 feeAmount) public whenNotPaused nonReentrant onlyRole(ROLE_AUDITOR) {
		require(rooms[roomId].availableFee >= feeAmount, "ROOM_OUT_OF_FEE");
		rooms[roomId].availableFee -= feeAmount;
		gameBetFee[rooms[roomId].contractAddress] += feeAmount;
	}

	function _uncheckedInc(uint i) pure internal returns (uint) {
		unchecked {
			return i + 1;
		}
	}

    function resolveBet(
        uint256 matchId,
        uint16[] calldata _targets,
		uint16[] calldata _refundTargets,
		uint256 maxBetLength
    ) external whenNotPaused onlyRole(ROLE_MANAGER) {
		uint256 processedRoomLength = gameBetRoomsArrProcessed[matchId];
		uint256 roomLength = gameBetRoomsArr[matchId].length - processedRoomLength;
		uint256 targetLength = _targets.length;
		uint256 refundTargetLength = _refundTargets.length;
		uint256 processedRoomCount = 0;
		uint256 totalProcessed = 0;
		require(roomLength > 0, "NO_BETS");
		matchResolved[matchId] = true;
        for (uint i = 0; i < targetLength; i = _uncheckedInc(i)) {
            targets[_targets[i]] = true;
        }
		for (uint i = 0; i < refundTargetLength; i = _uncheckedInc(i)) {
			refundTargets[_refundTargets[i]] = true;
		}
		for (uint i = processedRoomLength; i < (processedRoomLength + roomLength) && totalProcessed < maxBetLength; i = _uncheckedInc(i)) {
			bytes32 roomId = gameBetRoomsArr[matchId][i];
			uint256 processedGameLength = gameBetsArrProcessed[roomId][matchId];
			uint256 length = gameBetsArr[roomId][matchId].length - processedGameLength;
			uint256 processedGameCount = 0;
			for (uint j = processedGameLength; j < (processedGameLength + length) && totalProcessed < maxBetLength; j = _uncheckedInc(j)) {
				bytes32 betSlipId = gameBetsArr[roomId][matchId][j];
				Bet memory myBet = bets[betSlipId];
				uint256 potentialWinningAmount = myBet.potentialWinningAmount;
				bool result = targets[myBet.target];
				if (refundTargets[myBet.target]) {
					uint256 betAmount = myBet.amount;
					potentialWinningAmount = betAmount;
					userBalances[roomId][
						myBet.bettor
					] += betAmount;
					rooms[roomId].reverse -= betAmount;
					rooms[roomId].lockedReverse -= potentialWinningAmount;
				} else if (result) {
					userBalances[roomId][
						myBet.bettor
					] += potentialWinningAmount;
					rooms[roomId].reverse -= potentialWinningAmount;
					rooms[roomId].lockedReverse -= potentialWinningAmount;
				} else {
					rooms[roomId].lockedReverse -= potentialWinningAmount;
					potentialWinningAmount = 0;
				}

				emit BetResolved(
					roomId,
					myBet.bettor,
					betSlipId,
					myBet.target,
					result,
					potentialWinningAmount
				);
				delete gameBetsArr[roomId][matchId][j];
				processedGameCount++;
				totalProcessed++;
			}
			gameBetsArrProcessed[roomId][matchId] += processedGameCount;
			if (gameBetsArr[roomId][matchId].length == processedGameLength + processedGameCount) {
				delete gameBetRoomsArr[matchId][i];
				++processedRoomCount;
			}
		}
		gameBetRoomsArrProcessed[matchId] += processedRoomCount;
        for (uint i = 0; i < targetLength; i = _uncheckedInc(i)) {
			targets[_targets[i]] = false;
        }
		for (uint i = 0; i < refundTargetLength; i = _uncheckedInc(i)) {
			refundTargets[_refundTargets[i]] = false;
		}
    }

    function setSignerAddress(address _signerAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        signerAddress = _signerAddress;
    }

	function setMinBetLimit(address contractAddress, uint256 amount) public onlyAdmin {
		minBetLimit[contractAddress] = amount;
		emit MinBetLimit(contractAddress, amount);
	}

	function getMinBetLimit(address contractAddress) public view returns (uint256) {
		return minBetLimit[contractAddress];
	}

	function setWithdrawalDailyLimit(address contractAddress, uint256 amount) public onlyAdmin {
		withdrawalDailyLimit[contractAddress] = amount;
		emit WithdrawalDailyLimit(contractAddress, amount);
	}

	function getWithdrawalDailyLimit(address contractAddress) public view returns (uint256) {
		return withdrawalDailyLimit[contractAddress];
	}

	function pauseContract() public onlyAdmin {
		_pause();
	}

	function unpauseContract() public onlyAdmin {
		_unpause();
	}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;

contract BetDexEvent {
	/// @notice Emitted when reserves is deposited.
	event ReservesDeposited(
		bytes32 indexed roomId,
		address indexed contractAddress,
		address indexed sender,
		uint256 amount
	);

	event FeeDeposited(
		bytes32 indexed roomId,
		address indexed contractAddress,
		address indexed sender,
		uint256 amount
	);

	/// @notice Emitted when reserves is withdrawn.
	event ReservesWithdrawn(
		bytes32 indexed roomId,
		address indexed contractAddress,
		address sender,
		address indexed recipient,
		uint256 amount
	);

	event FeeWithdrawn(
		bytes32 indexed roomId,
		address indexed contractAddress,
		address sender,
		address indexed recipient,
		uint256 amount
	);

	event RejectWithdrawal(
		uint256 indexed id,
		bytes32 indexed roomId,
		address contractAddress,
		address approver,
		address indexed recipient,
		uint256 amountToUser,
		uint256 amountToRoom
	);

	event AdminFeeWithdrawn(
		address indexed contractAddress,
		address sender,
		address indexed recipient,
		uint256 amount
	);

	event RoomCreated(
		bytes32 indexed roomId,
		address indexed contractAddress,
		address sender
	);

	/// @notice Emitted when user transfer balance to room.
	event TransferToRoom(
		bytes32 indexed roomId,
		address indexed contractAddress,
		address sender,
		uint256 amount
	);

	event BetPlaced(
		uint256 indexed matchId,
		address indexed sender,
		bytes32 betSlipId,
		bytes32 roomId
	//        uint16 gameType,
	//        uint16 _target,
	//        address contractAddress,
	//        uint256 amount,
	//        uint32 odds
	);
	event BetResolved(
		bytes32 indexed roomId,
		address indexed sender,
		bytes32 indexed betSlipId,
		uint16 target,
		bool result,
	//        address contractAddress,
	//        uint256 amount,
		uint256 payout
	);
	event PendingWithdrawalCreated(
		uint256 indexed id,
		address indexed sender,
		address indexed contractAddress,
		uint256 amount
	);

	event WithdrawalDailyLimit(address indexed contractAddress, uint256 amount);
	event MinBetLimit(address indexed contractAddress, uint256 amount);
	event MaxBetOddsLimit(uint256 maxOdds);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum SignatureVersion { Single, Bulk }

struct InputBet {
	uint16 target;
	uint32 odds;
	uint256 amount;
	address bettor;
	uint256 matchId;
}

struct Input {
	InputBet[] bets;
	bytes32 roomId;
	uint8 v;
	bytes32 r;
	bytes32 s;
	bytes extraSignature;
	SignatureVersion signatureVersion;
	uint32 timestamp;
	uint256 nonce;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { InputBet } from "./BetStructs.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

/**
 * @title EIP712
 * @dev Contains all of the order hashing functions for EIP712 compliant signatures
 */
contract EIP712 {

	using ECDSAUpgradeable for bytes32;

	struct EIP712Domain {
		string  name;
		string  version;
		uint256 chainId;
		address verifyingContract;
	}

	/* Order typehash for EIP 712 compatibility. */
	bytes32 constant public BET_TYPEHASH = keccak256(
		"Bet(uint256 matchId,address bettor,uint16 target,uint32 odds,uint256 amount,uint256 nonce)"
	);
	bytes32 constant public ROOT_TYPEHASH = keccak256(
		"Root(bytes32 root)"
	);

	bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
		"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
	);

	function _getDomainSeparator() internal view virtual returns (bytes32) {
		return _hashDomain(EIP712Domain({
				name              : "EIP712Domain",
				version           : "1.0",
				chainId           : block.chainid,
				verifyingContract : address(this)
		}));
	}

	function _hashDomain(EIP712Domain memory eip712Domain)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				EIP712DOMAIN_TYPEHASH,
				keccak256(bytes(eip712Domain.name)),
				keccak256(bytes(eip712Domain.version)),
				eip712Domain.chainId,
				eip712Domain.verifyingContract
			)
		);
	}

	function _hashBets(InputBet[] calldata bets, uint256 nonce)
		internal
		pure
		returns (bytes32[] memory)
	{
		bytes32[] memory betHashes = new bytes32[](
			bets.length
		);
		for (uint256 i = 0; i < bets.length; i++) {
			betHashes[i] = _hashBet(bets[i], nonce);
		}
		return betHashes;
	}

	function _hashBet(InputBet calldata bet, uint256 nonce)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(
			abi.encode(
				BET_TYPEHASH,
				bet.matchId,
				bet.bettor,
				bet.target,
				bet.odds,
				bet.amount,
				nonce
			)
		);
	}

	function _hashToSign(bytes32 orderHash)
		internal
		view
		returns (bytes32 hash)
	{
		return keccak256(abi.encodePacked(
				"\x19\x01",
				_getDomainSeparator(),
				orderHash
			));
	}

	function _hashToSignRoot(bytes32 root)
		internal
		view
		returns (bytes32 hash)
	{
		return keccak256(abi.encodePacked(
				"\x19\x01",
				_getDomainSeparator(),
				keccak256(abi.encode(
					ROOT_TYPEHASH,
					root
				))
			));
	}

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library Token {
	using SafeERC20Upgradeable for IERC20Upgradeable;

	function deposit(
		address contractAddress,
		address from,
		uint256 _amount
	) internal {
		IERC20Upgradeable(contractAddress).safeTransferFrom(
			from,
			address(this),
			_amount
		);
	}

	function withdrawal(
		address contractAddress,
		address to,
		uint256 _amount
	) internal {
		IERC20Upgradeable(contractAddress).safeTransfer(to, _amount);
	}
}