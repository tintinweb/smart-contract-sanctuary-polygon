// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import './ICRD.sol';
import './utils/Access.sol';
import './utils/Div.sol';
import './utils/ISecurityERC721.sol';
import './utils/Royalty.sol';
import './utils/Tier.sol';
import './utils/Token.sol';

error SelfTransfer(address from, address to);
error TokenHoldPeriod(uint256 holdPeriodEnd);
error UnauthorizedTrade(address caller);
error BadURI();

/**
@title A Channel Revenue Distribution Contract (CRDC) to help securitize revenue payments from a media platform where
    each investor holds a Channel Revenue Token (CRT) which provides the features described below.
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@dev Comments are avoided in preference of writing code that is concise, clear, and simple. However, before we get to
    that part, here is an overview of things for context when reviewing the code.
@notice This solidity contract code is meant to facilitate a purchase agreement between an issuer and investors.
    To assist in understanding the code, terms and descriptions are used; in the event of a conflict or absence of
    information, then the purchase agreement should be considered as the source of truth and supercede any conflicts
    with this code. Please review the purchase agreement and consult an attorney if needed to fully understand things.
@notice Terms: When an investor purchases a CRT they become the owner of that token; however, owning the token does not
    entitle them to any ownership in the underlying channel. The owner of a CRT is entitled to channel revenue paid by
    the media platform. The details of ownership and revenue distribution are given in the terms of the investment.
@notice Terms: To distinguish between 1) channel revenue paid by a media platform and 2) CRT royalties paid per trade,
    (1) may be referred to as 'revenue share' or 'divs' and (2) may be referred to as 'trade royalties'.
@notice Terms: The term 'div' is an abbreviation of 'a division of shared revenue'. This term is meant to be short and
    differentiated from many loaded or generic terms (e.g. revenue, dividend, distribution) that confer or imply ownership in an underlying asset which a 'div' does not. However, a div is similar to a dividend in that it is revenue distributed with a predictable frequency to a group of investors.
@dev Features provided by this contract:
* Security Token: Token owners are entitled to a % of revenue share paid in recurring distributions.
* Token reassignment: A financial authority requires the ability to reassign a token for an investor with a
    bad wallet (e.g. lost, stolen, inaccessible)
* Max Issued %: A fixed value to ensure investors know the maximum % of revenue share that can be issued.
* NFTs: Every token uses ERC721 which provides a unique tokenId
* Tiers: Each tier has attributes shared by each token in the tier (e.g. perks and revenue share % per token)
* Metadata URI: Can be specified at the tier or token level
* Divs: Paid by the paying agent in phases: add to holding account, request allocation, allocate divs, push divs
* Trade Royalties: Provide trade royalty info addresses and amounts for use in a secondary market
* KYC: Transfers are restricted to registered addresses and facilitate trade royalties
* Hold Periods: Tokens may not trade during a hold period (e.g. 1 year after issuance in the primary market)
* Buy-backs: An issuer may buy tokens from investors and then destroy them thus reducing the issued %
* Unclaimed Divs and CRT Custody: Divs and tokens remain in the holding account until claimed/pushed to token owners
* Access Control: State modifying functions require a caller to have the proper access control role
* Security and Upgradeabilty: Via OpenZeppelin contracts, design patterns, and best practices
@dev Conventions: Underscore prefixes are used for both 'private' and 'internal' members. In some cases 'internal'
    facilitate tests accessing state that would otherwise be private. 'get' and 'set' prefix are often used to avoid
    naming conflicts with related variables.
*/
contract CRD is
    ICRD,
    ERC721Upgradeable,
    ISecurityERC721,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    Access,
    Royalty,
    Tier,
    Token,
    Div
{
    // UPGRADABILITY: https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts
    uint256 private _securityId; // See {CRD-__CRD_init}
    address private _holding; // See {CRD-__CRD_init}
    string internal _uriBase; // See {CRD-__CRD_init}
    uint256 internal _issuedPercent; // % issued to investors = _issuedPercent / DISPLAY_DIVISOR
    uint256 private _issuedPercentMax; // % that can be issued to investors = _issuedPercentMax / DISPLAY_DIVISOR
    uint256 internal _brokenTokenId; // Allows an administrative ownership fix
    EnumerableSetUpgradeable.UintSet internal _buyBacks; // key: tokenId, value: 1 if issuer did a token buy-back
    IKYC private _kyc; // See {CRD-__CRD_init}
    // UPGRADABILITY: All new variables should be immediately above this line and decrement the gap array

    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[42] private __gap; // Array size + the sum of all storage slots used (except this member) should be 50

    /**
    @dev Upgradeable contracts have a 2 part initialization: constructor(empty) + init(args), for more info see:
        https://docs.openzeppelin.com/contracts/4.x/upgradeable#usage
    @dev CALLER_UNIQUE: Label indicating the caller should enforce uniqueness on the field, not enforced by contract
    @param name_ CALLER_UNIQUE, Token name, see {ERC721Upgradeable-name}
    @param symbol_ CALLER_UNIQUE, Token symbol, see {ERC721Upgradeable-symbol}
    @param securityId CALLER_UNIQUE, Security identifier for numeric indexing
    @param uriBase Set if doing metadata at the token level, to be appended with a tokenId as `${uriBase}${tokenId}`,
        else if doing metadata at the tier level leave this blank and use setURISegment
    @param royaltyReceivers Accounts to receive trade royalties, see {Royalty-getRoyaltyFees}
    @param royaltyAmounts Trade royalty percent per receiver, see {Royalty-getRoyaltyFees}
    @param kyc Contract assists with identifying token owners for trade royalties, see {KYC}
    @param div Contract controls the currency for revenue distributions, see {Div}
    @param holding Account used as a holding area for 2 purposes: A) Revenue allocated before pushing to CRT owners,
        B) CRT owners with no personal wallet. The ownership mapping is stored off-chain for these unclaimed tokens
    @param manager Account to be granted permissions for running state changing functions (some restricted to owner)
    @param issuedPercentMax The maximum percent of revenue share that can be offered to investors
    */
    // slither-disable-next-line external-function
    function __CRD_init(
        string memory name_,
        string memory symbol_,
        uint256 securityId,
        string memory uriBase,
        address[] memory royaltyReceivers,
        uint256[] memory royaltyAmounts,
        IKYC kyc,
        IERC20Upgradeable div,
        address holding,
        address manager,
        uint256 issuedPercentMax
    ) public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
        __AccessControlEnumerable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __Access_init(manager);
        __Royalty_init(royaltyReceivers, royaltyAmounts);
        __Tier_init();
        __Token_init();
        __Div_init(div);
        setHolding(holding);
        setKyc(kyc);
        setUriBase(uriBase);
         // slither-disable-next-line events-maths
        _securityId = securityId;
        _checkString(Tag.name, name_);
        _checkString(Tag.symbol, symbol_);
         // slither-disable-next-line events-maths
        _issuedPercentMax = issuedPercentMax;
    }

    // Implement IERC165Upgradeable (Standard Interface Detection)
    function supportsInterface(bytes4 interfaceId)
        public view override(ERC721Upgradeable, IERC165Upgradeable, AccessControlEnumerableUpgradeable) returns(bool)
    {
        return interfaceId == type(ICRD).interfaceId
            || interfaceId == type(ISecurityERC721).interfaceId
            || super.supportsInterface(interfaceId);
    }

    // Implement ERC721Upgradeable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        _requireNotPaused();
        if(from == to) revert SelfTransfer(from, to);
        _checkExpectValue(Tag.batchSize, batchSize, 1);
        bool isMint = from == address(0);
        bool isBurn = to == address(0);
        bool isClaim = from == _holding && !EnumerableSetUpgradeable.contains(_buyBacks, tokenId);
        bool isSameUser = _kyc.areSameUser(from, to); // a friendly contract controlled by the same organization
        bool isTokenFix = _brokenTokenId != 0;
        bool isTrade = !(isMint || isBurn || isClaim || isSameUser || isTokenFix);
        bool isBuyBack = to == _holding && !(isMint || isTokenFix);
        // slither-disable-next-line unused-return
        _kyc.balanceOf(to); // reverts for an unknown account
        if(!isMint) {
            // slither-disable-next-line unused-return
            _kyc.balanceOf(from); // reverts for an unknown account
            if(isTokenFix) {
                _checkExpectValue(Tag.brokenTokenId, tokenId, _brokenTokenId);
                _brokenTokenId = 0;
                if(to != _holding) // Not an unclaim
                    _pushDiv(tokenId, to); // isBurn would fail to transfer
            } else if(!isSameUser) {
                if(isClaim) {
                    _pushDiv(tokenId, to);
                } else {
                    if(isTrade) {
                        _checkTransferAuthorized();
                        _checkHoldPeriod(tokenId);
                        if(from == _holding)
                            // slither-disable-next-line unused-return
                            EnumerableSetUpgradeable.remove(_buyBacks, tokenId);
                    }
                    if(isBuyBack)
                        // slither-disable-next-line unused-return
                        EnumerableSetUpgradeable.add(_buyBacks, tokenId);
                    _pushDiv(tokenId, from); // Claim divs before ownership change
                }
            }
            if(!isBurn)
                _getToken(tokenId).owner = to;
        }
        uint256 flags = _setTransferTypeFlags(isMint, isBurn, isClaim, isTrade, isBuyBack, isSameUser, isTokenFix);
        emit CRTTransfer(from, to, tokenId, flags, _msgSender());
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _checkTransferAuthorized() private view {
        if(!_isTransferAuthorized()) revert UnauthorizedTrade(_msgSender());
    }

    function _checkHoldPeriod(uint256 tokenId) private view {
        // slither-disable-next-line timestamp // low accuracy is fine as hold period is ~1 year
        if(block.timestamp <= _getToken(tokenId).holdPeriodEnd) // solhint-disable-line not-rely-on-time
            revert TokenHoldPeriod(_getToken(tokenId).holdPeriodEnd);
    }

    function isApprovedForAll(address tokenOwner, address operator)
        public view override(ERC721Upgradeable, IERC721Upgradeable) returns(bool)
    {
        return _isTransferAuthorized() || super.isApprovedForAll(tokenOwner, operator);
    }

    function tokenURI(uint256 tokenId) public override view returns(string memory) {
        _requireMinted(tokenId);
        if(bytes(_uriBase).length > 0)
            return string.concat(_uriBase, StringsUpgradeable.toString(tokenId)); // token URI
        TierInfo storage tier = _getTier(_getToken(tokenId).tierId);
        return string.concat(tier.uriA, tier.uriB, tier.uriC, tier.uriD); // tier URI
    }

    function setUriBase(string memory newUriBase) public override onlyManager {
        if(bytes(newUriBase).length > 0)
            _checkUriBase(newUriBase);
        else if(bytes(_uriBase).length == 0)
            return;
        string memory from = _uriBase;
        _uriBase = newUriBase;
        emit BaseURIUpdate(from, newUriBase, msg.sender);
    }

    // Implement ISecurityERC721
    function getSecurityId() external view override returns(uint256) { return _securityId; }

    function getName() external view override returns(string memory) { return name(); }

    function getSymbol() external view override returns(string memory) { return symbol(); }

    function getKyc() external view override returns(IKYC) { return _kyc; }

    function getDivToken() external view override returns(IERC20Upgradeable) { return _div; }

    function getHoldPeriod(uint256 tokenId) external view override returns(uint256) {
        return _getToken(tokenId).holdPeriodEnd;
    }

    // Implement IRoyalty
    function setRoyaltyPayees(address[] memory receivers, uint256[] memory amounts) external override onlyOwner {
        _setRoyaltyPayees(receivers, amounts);
    }

    // Implement IDiv
    function _getHolding() internal view override returns(address) { return _holding; }

    function _getIssuedPercent() internal view override returns(uint256) { return _issuedPercent; }

    function _getTierCount() internal view override returns(uint256) {
        return EnumerableSetUpgradeable.length(_tierIds);
    }

    function _getTierByIndex(uint256 index) internal view override returns(TierInfo storage) {
        return _getTier(EnumerableSetUpgradeable.at(_tierIds, index));
    }

    function _getTokenIds(uint256 tierId) internal view override returns(EnumerableSetUpgradeable.UintSet storage) {
        return _getTier(tierId).tokenIds;
    }

    function _isTransferAuthorized() internal view override returns(bool) {
        return hasRole(ROLE_MANAGER, _msgSender()) || hasRole(ROLE_MARKET, _msgSender());
    }

    function _ownerOf2(uint256 tokenId) internal view override returns(address) { return ownerOf(tokenId); }

    function _getChannelId() internal view override returns(uint256) { return _securityId; }

    // Divs step 1: Enqueue a request to allocate divs. The request allows paging vs doing it directly.
    function requestDivAlloc(uint256 divAmountIn, uint256 pageSize)
        external override onlyManager nonReentrant returns(bool)
    {
        _requestDivAlloc(divAmountIn);
        return pageSize == 0 ? true : _processAllocRequest(pageSize);
    }

    // Divs step 2: Process queued requests to allocate divs. Caller should page requests while returns true
    function processAllocRequest(uint256 pageSize) external onlyManager returns(bool) {
        return _processAllocRequest(pageSize);
    }

    // Divs step 3: Push allocated divs to each token owner (if claimed)
    function pushDivs(uint256 tierId, uint256 tokenIndexBegin, uint256 tokenIndexEnd)
        external override onlyManager nonReentrant returns(uint256)
    {
        return _pushDivs(tierId, tokenIndexBegin, tokenIndexEnd);
    }

    // Implement ICRD
    function pause() external override onlyManager {
        _pause(); // emits Paused
    }

    function unpause() external override onlyManager {
        _unpause(); // emits Unpaused
    }

    function isPaused() external view override returns(bool) { return paused(); }

    function getIssuedPercent() external view override returns(uint256) { return _issuedPercent; }

    function getIssuedPercentMax() external view override returns(uint256) { return _issuedPercentMax; }

    function getHolding() external view override returns(address) { return _holding; }

    function setHolding(address account) public override onlyOwner {
        emit AddressUpdate(_holding, account, 'holding', msg.sender);
        // slither-disable-next-line missing-zero-check
        _holding = _checkAddress(Tag.holding, account);
    }

    function setKyc(IKYC kyc) public override onlyOwner {
        address to = address(kyc);
        _checkAddress(Tag.kyc, to);
        emit AddressUpdate(address(_kyc), to, 'kyc', msg.sender);
        _kyc = kyc;
    }

    function createTiers(string[] memory names, uint256[] memory tokenRevPercents)
        external override onlyManager returns(uint256)
    {
        return _createTiers(names, tokenRevPercents);
    }

    // facilitates testing
    function _createTiers(string[] memory names, uint256[] memory tokenRevPercents) internal returns(uint256) {
        _checkNonZero(Tag.namesLength, names.length);
        _checkArrayLength(Tag.namesLength, names.length, tokenRevPercents.length);
        uint256 tierId = _tierIdSeed;
        uint256 issuedPercentMax = _issuedPercentMax;
        unchecked {
            // slither-disable-next-line uninitialized-local // value zero init is default behavior
            for(uint256 i; i < names.length; ++i) { // TIER_COUNT: Likely ~3, caller must page
                _checkRange(Tag.revenuePercent, 1, issuedPercentMax, tokenRevPercents[i]);
                _createTier(++tierId, names[i], tokenRevPercents[i]);
            }
            _tierIdSeed = tierId;
            uint256 tierIdBegin = tierId - names.length + 1;
            emit TiersCreated(names, tokenRevPercents, tierIdBegin, _msgSender());
            return tierIdBegin; // return first id of range created: [tokenIdBegin, tokenIdBegin + names.length)
        }
    }

    function destroyTiers(uint256[] memory tierIds) external override onlyManager {
        unchecked {
            for(uint256 i = 0; i < tierIds.length; ++i) // See TIER_COUNT
                _destroyTier(tierIds[i]);
        }
        emit TiersDestroyed(tierIds, _msgSender());
    }

    function createTokens(address[] memory owners, uint256 tierId, uint256 holdPeriodEnd)
        external override onlyManager returns(uint256)
    {
        return _createTokens(owners, tierId, holdPeriodEnd);
    }

    // facilitates testing
    function _createTokens(address[] memory owners, uint256 tierId, uint256 holdPeriodEnd) internal returns(uint256) {
        _checkDate(Tag.holdPeriodEnd, holdPeriodEnd);
        TierInfo storage tier = _getTier(tierId);
        _issuedPercent += tier.tokenRevPercent * owners.length; // 'checked' for unlikely overflow
        unchecked {
            _checkRange(Tag.sharesIssued, 1, _issuedPercentMax, _issuedPercent);
            // slither-disable-next-line uninitialized-local // value zero init is default behavior
            for(uint256 i; i < owners.length; ++i) { // TOKEN_COUNT: Maybe many, caller must page
                address owner = owners[i] == address(0) ? _holding : owners[i];
                _createToken(owner, tierId, holdPeriodEnd);
                // slither-disable-next-line unused-return
                EnumerableSetUpgradeable.add(tier.tokenIds, _tokenIdSeed);
                _safeMint(owner, _tokenIdSeed); // emit Transfer
            }
            uint256 tokenIdBegin = _tokenIdSeed - owners.length + 1;
            emit TokensCreated(owners, tierId, holdPeriodEnd, tokenIdBegin, _msgSender());
            return tokenIdBegin; // return first id of range created: [tokenIdBegin, tokenIdBegin + to.length)
        }
    }

    function destroyBuyBacks(uint256 pageSize) external override onlyManager returns(uint256[] memory) {
        // EnumerableSetUpgradeable.values() is unbounded so we initialize and iteratively set each item
        uint256 tokenCount = EnumerableSetUpgradeable.length(_buyBacks);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        if(tokenCount == 0)
            return tokenIds;
        _checkNonZero(Tag.pageSize, pageSize);
        unchecked {
            uint256 end = pageSize >= tokenCount ? 0 : tokenCount - pageSize;
            for(uint256 i = tokenCount - 1; i >= end; --i) { // REPURCHASE_COUNT: Maybe many, caller must page
                _destroyToken(tokenIds[i] = EnumerableSetUpgradeable.at(_buyBacks, i));
                if(i == 0) break;
            }
        }
        emit TokensDestroyed(tokenIds, _msgSender());
        return tokenIds;
    }

    function _destroyToken(uint256 tokenId) internal {
        TokenInfo storage token = _getToken(tokenId);
        uint256 div = _divs[tokenId];
        if(div != 0)
            emit DivForfeited(tokenId, token.owner, div, _msgSender());
        delete _divs[tokenId];
        // slither-disable-next-line unused-return
        EnumerableSetUpgradeable.remove(_buyBacks, tokenId);
        uint256 tierId = token.tierId;

        TierInfo storage tier = _getTier(tierId);
        // slither-disable-next-line unused-return
        EnumerableSetUpgradeable.remove(tier.tokenIds, tokenId);
        unchecked { _issuedPercent -= tier.tokenRevPercent; }

        _deleteToken(tokenId);
        _burn(tokenId); // emit Transfer
    }

    function allocateURIPage(uint256 tierId, uint256 pageId, uint256 length) external override onlyManager {
        _allocateURIPage(tierId, pageId, length);
    }

    /// @dev Allow a URI to be built across multiple calls where the URI is passed in segments incrementally
    /// @param tierId Tier ID for this URI
    /// @param offset This segment's character offset from the beginning of the URI
    /// @param uriLength Length of the final URI
    /// @param segment 1 of N segments that when assembled, in the order passed, recreate the original URI
    function setURISegment(uint256 tierId, uint256 offset, uint256 uriLength, string calldata segment)
        external override onlyManager
    {
        _setURISegment(tierId, offset, uriLength, segment);
    }

    // A financial authority requires an ability to reassign a token for an investor with a bad wallet
    // (e.g. lost, stolen, inaccessible)
    function fixTokenOwnership(address newOwner, uint256 tokenId) external override onlyManager nonReentrant {
        TokenInfo storage token = _getToken(tokenId);
        if(newOwner == token.owner) return;
        address prevOwner = token.owner;
        token.owner = newOwner;
        _brokenTokenId = tokenId; // used during transfer
        emit CRTOwnerFix(prevOwner, newOwner, tokenId, _msgSender());
        // slither-disable-next-line unused-return
        EnumerableSetUpgradeable.remove(_buyBacks, tokenId);
        safeTransferFrom(prevOwner, newOwner, tokenId); // emit Transfer
    }

    function pushUnclaimedTokens(address[] memory newOwners, uint256[] memory tokenIds)
        external override onlyManager nonReentrant
    {
        _checkArrayLength(Tag.tokenCount, newOwners.length, tokenIds.length);
        unchecked {
            // slither-disable-next-line uninitialized-local // value zero init is default behavior
            for(uint256 i; i < newOwners.length; ++i) { // See TOKEN_COUNT. Maybe many, caller must page
                _getToken(tokenIds[i]).owner = newOwners[i];
                safeTransferFrom(_holding, newOwners[i], tokenIds[i]); // emit Transfer
            }
        }
        emit TokensPushed(tokenIds, _msgSender());
    }

    // Constants become literals during compile
    // Transfer Type bitmask flags: isFlagSet(uint256 value, uint256 flag) return value & flag != 0;
    uint256 public constant TX_FLAG_MINT = 1;
    uint256 public constant TX_FLAG_BURN = 2;
    uint256 public constant TX_FLAG_CLAIM = 4;
    uint256 public constant TX_FLAG_TRADE = 8;
    uint256 public constant TX_FLAG_BUY_BACK = 16;
    uint256 public constant TX_FLAG_SAME_USER = 32;
    uint256 public constant TX_FLAG_TOKEN_OWNER_FIX = 64;

    // This function is modular/clear but costs extra to execute vs integrating into the calller
    function _setTransferTypeFlags(bool mint, bool burn, bool claim, bool trade, bool buyBack, bool sameUser, bool fix)
        internal pure returns(uint256)
    {
        uint256 value = 0;
        if(mint) value |= TX_FLAG_MINT;
        if(burn) value |= TX_FLAG_BURN;
        if(claim) value |= TX_FLAG_CLAIM;
        if(trade) value |= TX_FLAG_TRADE;
        if(buyBack) value |= TX_FLAG_BUY_BACK;
        if(sameUser) value |= TX_FLAG_SAME_USER;
        if(fix) value |= TX_FLAG_TOKEN_OWNER_FIX;
        return value;
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

import './IKYC.sol';
import './utils/IAccess.sol';
import './utils/ITier.sol';
import './utils/IToken.sol';
import './utils/IDiv.sol';
import './utils/IRoyalty.sol';

/**
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@notice See terms in {CRD} contract comments.
@dev This interface allows usage of the CRD contract to be decoupled from the implementation.
*/
interface ICRD is IAccess, ITier, IToken, IRoyalty, IDiv {
    event CRTTransfer(address from, address to, uint256 indexed tokenId, uint256 flags, address indexed caller);
    event CRTOwnerFix(address from, address to, uint256 indexed tokenId, address indexed caller);
    event AddressUpdate(address from, address to, string indexed label, address indexed caller);
    event BaseURIUpdate(string from, string to, address indexed caller);
    event TiersCreated(string[] names, uint256[] tokenRevPercents, uint256 tierIdBegin, address indexed caller);
    event TiersDestroyed(uint256[] tierIds, address caller);
    event TokensCreated(
        address[] owners, uint256 indexed tierId, uint256 holdPeriodEnd, uint256 tokenIdBegin, address indexed caller);
    event TokensDestroyed(uint256[] tokenIds, address indexed caller);
    event TokensPushed(uint256[] tokenIds, address indexed caller);

    // Pausable
    function pause() external;
    function unpause() external;
    function isPaused() external view returns(bool);

    // Misc
    function getIssuedPercent() external view returns(uint256);
    function getIssuedPercentMax() external view returns(uint256);
    function getHolding() external view returns(address);
    function setHolding(address account) external;
    function setKyc(IKYC kyc) external;
    function setUriBase(string memory uriBase) external;
    function allocateURIPage(uint256 tierId, uint256 pageId, uint256 length) external;
    function setURISegment(uint256 tierId, uint256 offset, uint256 uriLength, string calldata segment) external;

    // Tier (and see ITier)
    function createTiers(string[] memory names, uint256[] memory tokenRevPercents) external returns(uint256);
    function destroyTiers(uint256[] memory tierIds) external;

    // Token (and see IToken)
    function createTokens(address[] memory owners, uint256 tierId, uint256 holdPeriodEnd) external returns(uint256);
    function destroyBuyBacks(uint256 pageSize) external returns(uint256[] memory);
    function fixTokenOwnership(address newOwner, uint256 tokenId) external;
    function pushUnclaimedTokens(address[] memory newOwners, uint256[] memory tokenIds) external;
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

/**
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@notice See terms in {CRD} contract comments.
@dev This interface allows usage of the KYC contract to be decoupled from the implementation.
*/
interface IKYC is IERC721Upgradeable {
    event KYCOwnership(address indexed prevOwner, address indexed newOwner);

    struct Token {
        uint256 userId;
        address owner;
        uint256 issuedDate; // When token was issued, stored as seconds since unix epoch
        uint256 level; // Level of checks passed

        // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
        uint256[11] __gap; // Array size + the sum of all storage slots used (except this member) should be 15
    }    
    
    // Utility (supplements IERC721Upgradeable)
    function areSameUser(address owner1, address owner2) external view returns(bool);
    function getCheckLevelByTokenId(uint256 tokenId) external view returns(uint256);
    function getCheckLevelByOwner(address owner_) external view returns(uint256);

    // Admin
    function pause() external;
    function unpause() external;
    function isPaused() external view returns(bool);
    function createToken(address to, uint256 tokenId, uint256 issuedDate, uint256 level_) external returns(uint256);
    function createTokenBatch(address[] calldata owners, uint256[] calldata tokenIds, uint256[] calldata issuedDates, 
        uint256[] calldata levels) external returns(uint256);
    function getToken(uint256 tokenId) external view returns(uint256, address, uint256, uint256);
    function destroyToken(uint256 tokenId) external;
    function destroyTokens(uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';
import './IAccess.sol';
import './Checks.sol';

/**
@title A CRD utility for access control features
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@notice See terms in {CRD} contract comments.
@notice Terms: The term 'owner' is not meant to imply any ownership in the media channel that generates revenue.
@dev This contract modularizes features in the {CRD} contract such as having role based access
*/
contract Access is IAccess, AccessControlEnumerableUpgradeable {
    // UPGRADABILITY: https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts
    address private _owner; // Owner and creator of this contract
    // UPGRADABILITY: All new variables should be immediately above this line
    
    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[14] private __gap; // Array size + the sum of all storage slots used (except this member) should be 15

    // Constants become literals during compile with no impact on the data layout
    bytes32 public constant ROLE_MANAGER = keccak256('MANAGER');
    bytes32 public constant ROLE_MARKET = keccak256('MARKET');

    /// @dev Internal version of {Access-__Access_init} to facilitate testing
    /// @dev Upgradeable contracts have a 2 part initialization: constructor(empty) + init(args), for more info see:
    ///  https://docs.openzeppelin.com/contracts/4.x/upgradeable#usage
    function __Access_init(address manager) internal onlyInitializing {
        address owner = msg.sender;
        _owner = owner; // owner is admin of all roles
        _grantRole(DEFAULT_ADMIN_ROLE, owner); // emits RoleAdminChanged
        _grantRole(ROLE_MANAGER, owner); // emits RoleGranted
        if(manager != address(0) && manager != owner) _grantRole(ROLE_MANAGER, manager); // emits RoleGranted
    }
   
    function getOwner() external view override returns(address) { return _owner; }

    function setOwner(address account) external override onlyOwner {
        address from = _owner;
        if(account == from) return;
        _checkAddress(Tag.account, account);
        _owner = account;
        grantRole(ROLE_MANAGER, account); // emits RoleGranted
        revokeRole(ROLE_MANAGER, from);
    }

    // slither-disable-next-line incorrect-modifier
    modifier onlyOwner() { if(hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) _; else revert OwnerRoleRequired(msg.sender); }

    // slither-disable-next-line incorrect-modifier
    modifier onlyManager() { if(hasRole(ROLE_MANAGER, msg.sender)) _; else revert ManagerRoleRequired(msg.sender); }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

/// @dev Tag provides context in a more compact way than using strings
enum Tag {
    account,
    amountsSum,
    batchSize,
    brokenTokenId,
    divAmountIn,
    existingOwner,
    holding,
    holdPeriodEnd,
    insufficientAllowance,
    insufficientBalance,
    issuedDate,
    issuedPercent,
    kyc,
    manager,
    market,
    name,
    namesLength,
    ownerOf,
    owners,
    ownersLength,
    pageSize,
    receiver,
    receiversLength,
    renounceOwnership,
    revenuePercent,
    royaltyAmount,
    security,
    sharesIssued,
    symbol,
    tierName,
    tierTokenIds,
    tokenCount,
    tokenIndexes,
    unknownOwner,
    uriBase,
    uriBaseLength,
    userIdReserved
}

error ArrayLengthMismatch(Tag tag, uint256 len1, uint256 len2);
error BadValue(Tag tag, uint256 actual, uint256 expect);
error DateRange(Tag tag, uint256 lower, uint256 upper, uint256 actual);
error DisabledFeature(Tag tag);
error EmptyString(Tag tag);
error ExpectZero(Tag tag, uint256 value);
error ExpectNonZero(Tag tag);
error LessEqual(Tag tag, uint256 left, uint256 right);
error Range(Tag tag, uint256 lower, uint256 upper, uint256 actual);
error UriBase(string value);
error ZeroAddress(Tag tag);

// solhint-disable-next-line func-visibility
function _checkAddress(Tag tag, address account) pure returns(address) {
    if(account == address(0)) revert ZeroAddress(tag);
    return account;
}

function _checkArrayLength(Tag tag, uint256 len1, uint256 len2) pure { // solhint-disable-line func-visibility
    if(len1 != len2) revert ArrayLengthMismatch(tag, len1, len2);
}

function _checkZero(Tag tag, uint256 value) pure { // solhint-disable-line func-visibility
    if(value != 0) revert ExpectZero(tag, value);
}

function _checkString(Tag tag, string memory value) pure { // solhint-disable-line func-visibility
    if(bytes(value).length == 0) revert EmptyString(tag);
}

function _checkNonZero(Tag tag, uint256 value) pure { // solhint-disable-line func-visibility
    if(value == 0) revert ExpectNonZero(tag);
}

// solhint-disable-next-line func-visibility
function _checkExpectValue(Tag tag, uint256 actual, uint256 expect) pure {
    if(actual != expect) revert BadValue(tag, actual, expect);
}

// solhint-disable-next-line func-visibility
function _checkRange(Tag tag, uint256 lower, uint256 upper, uint256 actual) pure {
    if(actual < lower || upper < actual) revert Range(tag, lower, upper, actual);
}

// solhint-disable-next-line func-visibility
function _checkLessEqual(Tag tag, uint256 left, uint256 right) pure {
    if(left > right) revert LessEqual(tag, left, right);
}

function _checkUriBase(string memory value) pure { // solhint-disable-line func-visibility
    bytes memory uri = bytes(value);
    if(bytes(value).length == 0) revert EmptyString(Tag.uriBaseLength);
    if(uri[uri.length - 1] != '/') revert UriBase(value);
}

// Constants become literals during compile
uint256 constant UNIX_TIME_2000_01_01 = 946684800;
uint256 constant UNIX_TIME_2100_01_01 = 4102444800;

function _checkDate(Tag tag, uint256 date) pure { // solhint-disable-line func-visibility
    if(date < UNIX_TIME_2000_01_01 || UNIX_TIME_2100_01_01 < date)
        revert DateRange(tag, UNIX_TIME_2000_01_01, UNIX_TIME_2100_01_01, date);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import './IDiv.sol';
import './Checks.sol';

error UnauthorizedDivPush(address caller);

/**
@title A CRD utility for div (revenue share) features
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@notice See terms in {CRD} contract comments such as an explanation of the term 'div'.
@dev This contract modularizes features in the {CRD} contract. Decoupling adds code bloat but the separation of
    concerns should make the code easier to maintain.
*/
abstract contract Div is IDiv, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // UPGRADABILITY: https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts
    IERC20Upgradeable internal _div; // payment currency/token for divs
    mapping(uint256 => uint256) internal _divs; // key: tokenId, value: balance allocated for transfer
    uint256 internal _divTotalAllocated; // sum of all divs allocated to tokens
    uint256 internal _divTotalTransferred; // sum of all divs transferred to token owner wallets
    uint256 internal _divSlip; // slippage: sum of all divs allocation remainders
    DivAllocRequest internal _divAllocReq;
    // UPGRADABILITY: All new variables should be immediately above this line and decrement the gap array

    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[24] private __gap; // Array size + the sum of all storage slots used (except this member) should be 30

    // Constants become literals during compile
    uint256 constant private MAX_DIV_AMOUNTS = 2;

    /// @dev Upgradeable contracts have a 2 part initialization: constructor(empty) + init(args), for more info see:
    ///  https://docs.openzeppelin.com/contracts/4.x/upgradeable#usage
    function __Div_init(IERC20Upgradeable div) internal onlyInitializing {
        _div = div;
    }

    // Functions to decouple this contract from CRD
    function _getHolding() internal view virtual returns(address);
    function _getIssuedPercent() internal view virtual returns(uint256);
    function _getTierCount() internal view virtual returns(uint256);
    function _getTierByIndex(uint256 index) internal view virtual returns(TierInfo storage);
    function _getTokenIds(uint256 tierId) internal view virtual returns(EnumerableSetUpgradeable.UintSet storage);
    function _isTransferAuthorized() internal view virtual returns(bool);
    function _ownerOf2(uint256 tokenId) internal view virtual returns(address);
    function _getChannelId() internal view virtual returns(uint256);

    function _divUnclaimed() internal view returns(uint256) {
        return _divTotalAllocated - _divTotalTransferred; // Unclaimed divs pending transfer
    }

    function getDivSlippage() external view override returns(uint256) { return _divSlip; }

    // Divs step 1: Enqueue a request to allocate divs. The request allows paging vs doing it directly.
    function _requestDivAlloc(uint256 divAmountIn) internal {
        _checkNonZero(Tag.issuedPercent, _getIssuedPercent());
        _checkNonZero(Tag.divAmountIn, divAmountIn);
        if(_divAllocReq.nextTierIndex == 0 && _divAllocReq.nextTokenIndex == 0) // No request in progress
            _divAllocReq.divAmountIn += divAmountIn; // Merge with current request
        else
            _divAllocReq.nextDivAmount += divAmountIn; // Merge with next request
        emit DivAllocRequested(divAmountIn, msg.sender);

        // Ensure holding account has a balance to pay current obligations and this new div (funds received)
        uint256 pendingUnclaimed = _divUnclaimed() + _divAllocReq.divAmountIn + _divAllocReq.nextDivAmount;
        address holding = _getHolding();
        _checkLessEqual(Tag.insufficientBalance, pendingUnclaimed, _div.balanceOf(holding));

        // Ensure the holding account approved sufficient allowance to this contract to transfer the div
        _checkLessEqual(Tag.insufficientAllowance, pendingUnclaimed, _div.allowance(holding, address(this)));
    }

    // Divs step 2: Process requests to allocate divs. Caller should page requests while returns true
    function _processAllocRequest(uint256 pageSize) internal returns(bool) {
        _checkNonZero(Tag.pageSize, pageSize);
        // Many variables are used to cache storage vars into memory for less gas, especially in loops; however,
        // the stack depth limit is reached so not everything can be cached as highlighted by 'STACK'.
        uint256 pageRemaining = pageSize;
        uint256 divAmount = _divAllocReq.divAmountIn + _divSlip; // Includes any previously unallocated remainder
        uint256 sumAllocated = _divAllocReq.sumAllocated;
        uint256 tierCount = _getTierCount();
        // uint256 issuedPercent = _getIssuedPercent(); // STACK: Too deep so removed
        uint256 nextTierIndex = _divAllocReq.nextTierIndex;
        uint256 channelId = _getChannelId();
        for(uint256 i = 0; i < tierCount * MAX_DIV_AMOUNTS; ++i) {
            TierInfo storage tier = _getTierByIndex(nextTierIndex);
            uint256 tokenCount = EnumerableSetUpgradeable.length(tier.tokenIds);
            uint256 divPerToken = (divAmount * tier.tokenRevPercent) / _getIssuedPercent();
            uint256 nextTokenIndex = _divAllocReq.nextTokenIndex;
            // uint256 tokensRemainInTier = tokenCount - nextTokenIndex; // STACK: Too deep so removed
            uint256 batchSize = pageRemaining <= tokenCount - nextTokenIndex
                ? pageRemaining : tokenCount - nextTokenIndex;
            uint256 end = nextTokenIndex + batchSize;
            uint256 tierId = tier.tierId;
            unchecked {
                while(nextTokenIndex < end) { // See TOKEN_COUNT, caller must page
                    uint256 tokenId = EnumerableSetUpgradeable.at(tier.tokenIds, nextTokenIndex);
                    _divs[tokenId] += divPerToken;
                    emit DivAllocToken(channelId, tierId, tokenId, divPerToken, msg.sender);
                    ++nextTokenIndex;
                }
            }
            pageRemaining -= batchSize;
            // slither-disable-next-line divide-before-multiply (this sequence is necessary in this context)
            sumAllocated += batchSize * divPerToken;
            if(nextTokenIndex >= tokenCount) { // Finished tier
                // slither-disable-next-line divide-before-multiply (this sequence is necessary in this context)
                emit DivAllocTier(channelId, tier.tierId, tokenCount * divPerToken, msg.sender);
                nextTokenIndex = 0;
                if(++nextTierIndex >= tierCount) { // Finished all tiers
                    uint256 newSlip = divAmount - sumAllocated; // Unallocated remainder
                    emit DivAllocChannel(channelId, _divAllocReq.divAmountIn, _divSlip, newSlip, msg.sender);
                    _divTotalAllocated += sumAllocated;
                    _divSlip = newSlip;
                    _divAllocReq.divAmountIn = divAmount = _divAllocReq.nextDivAmount;
                    _divAllocReq.nextTierIndex = nextTierIndex = 0;
                    _divAllocReq.nextTokenIndex = 0;
                    _divAllocReq.sumAllocated = sumAllocated = 0;
                    _divAllocReq.nextDivAmount = 0;
                    if(divAmount == 0 || pageRemaining == 0)
                        break;
                    divAmount += newSlip;
                    continue;
                }
            }
            if(pageRemaining == 0) { // Storage writes to resume processing later
                _divAllocReq.nextTierIndex = nextTierIndex;
                _divAllocReq.nextTokenIndex = nextTokenIndex;
                _divAllocReq.sumAllocated = sumAllocated;
                break;
            }
        }
        return _divAllocReq.divAmountIn > 0; // true: More processing required
    }

    // Divs step 3: Push allocated divs to each token owner (if claimed)
    function _pushDivs(uint256 tierId, uint256 tokenIndexBegin, uint256 tokenIndexEnd) internal returns(uint256) {
        if(_divUnclaimed() == 0) return 0;
        EnumerableSetUpgradeable.UintSet storage tokenIds = _getTokenIds(tierId);
        uint256 tokenCount = EnumerableSetUpgradeable.length(tokenIds);
        _checkNonZero(Tag.tokenCount, tokenCount);
        uint256 end = tokenIndexEnd < tokenCount ? tokenIndexEnd : tokenCount - 1;
        _checkLessEqual(Tag.tokenIndexes, tokenIndexBegin, end);
        uint256 divTotalTransferredOld = _divTotalTransferred;
        unchecked {
            for(uint256 i = tokenIndexBegin; i <= end; ++i) { // See TOKEN_COUNT. Maybe many, caller must page
                uint256 tokenId = EnumerableSetUpgradeable.at(tokenIds, i);
                _pushDiv(tokenId, _ownerOf2(tokenId));
            }
        }

        return _divTotalTransferred - divTotalTransferredOld;
    }

    function _pushDiv(uint256 tokenId, address tokenOwner) internal virtual returns(uint256) {
        _pushDivSub(tokenId, tokenOwner);
        return 0; // facilitates testing, could be removed
    }

    function _pushDivSub(uint256 tokenId, address tokenOwner) private {
        address holding = _getHolding();
        if(holding == tokenOwner) { // Token is unclaimed or a buy-back:
            // unclaimed: div pushed after token claim
            // buy-back: issuer destroys token before paying div
            return;
        }
        uint256 balance = _divs[tokenId];
        if(balance == 0) return; // no balance or unknown tokenId
        if(!_isTransferAuthorized()) revert UnauthorizedDivPush(msg.sender);
        _divs[tokenId] = 0;
        unchecked {
            _divTotalTransferred += balance;
        }
        emit DivPushed(holding, tokenOwner, tokenId, balance, msg.sender);
        _div.safeTransferFrom(holding, tokenOwner, balance); // emits Transfer and decreases allowance
    }

    function getUnclaimedDiv(uint256 tokenId) external view override returns(uint256) {
        return _divs[tokenId];
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol';

/**
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@notice See terms in {CRD} contract comments.
@notice Terms: The term 'owner' is not meant to imply any ownership in the media channel that generates revenue.
@dev This interface allows usage of the Access contract to be decoupled from the implementation.
*/
interface IAccess {
    error OwnerRoleRequired(address caller);
    error ManagerRoleRequired(address caller);

    function getOwner() external view returns(address);
    function setOwner(address account) external;
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

import './ITier.sol';

/**
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@notice See terms in {CRD} contract comments.
@dev This interface allows usage of the Div contract to be decoupled from the implementation.
*/
interface IDiv is ITier {
    event DivAllocRequested(uint256 amount, address caller);
    event DivAllocToken(
        uint256 indexed channelId,
        uint256 indexed tierId,
        uint256 indexed tokenId,
        uint256 amount,
        address caller
    );
    event DivAllocTier(uint256 indexed channelId, uint256 indexed tierId, uint256 amount, address caller);
    event DivAllocChannel(
        uint256 indexed channelId, uint256 amount, uint256 prevSlippage, uint256 newSlippage, address indexed caller);
    event DivForfeited(uint256 indexed tokenId, address indexed owner, uint256 amount, address caller);
    event DivPushed(address indexed from, address indexed to, uint256 indexed tokenId, uint256 amount, address caller);

    /// @dev Allow 1 or more div (revenue share) allocation requests to be conceptually queued such that a caller
    /// can service these requests with repeated calls (paging) until complete
    struct DivAllocRequest {
        uint256 divAmountIn; // Div to be allocated across tokens
        uint256 nextTierIndex; // Cursor to iterate tiers and persist across paged calls
        uint256 nextTokenIndex; // Cursor to iterate tokens and persist across paged calls
        uint256 sumAllocated; // Actual amount allocated: input - slippage (eg 10/3 -> 3.33... x 3 + 0.0...1 slip)
        uint256 nextDivAmount; // To be processed after current request, acts as a queue for 1 or more later requests

        // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
        uint256[10] __gap; // Array size + the sum of all storage slots used (except this member) should be 15
    }

    function getDivSlippage() external view returns(uint256);
    function requestDivAlloc(uint256 divAmountIn, uint256 pageSize) external returns(bool);
    function processAllocRequest(uint256 pageSize) external returns(bool);
    function pushDivs(uint256 tierId, uint256 tokenIndexBegin, uint256 tokenIndexEnd) external returns(uint256);
    function getUnclaimedDiv(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

/**
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@notice See terms in {CRD} contract comments.
@dev This interface allows usage of the Royalty contract to be decoupled from the implementation.
*/
interface IRoyalty {
    event RoyaltyPayeesUpdate(address[] receivers, uint256[] amounts, address indexed caller);

    function getRoyaltyFees(uint256 salePrice) external view returns(address[] memory, uint256[] memory, uint256);
    function getRoyaltyPayees() external view returns(address[] memory, uint256[] memory);
    function setRoyaltyPayees(address[] memory receivers, uint256[] memory amounts) external;
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '../IKYC.sol';
import './IRoyalty.sol';

/**
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@notice See terms in {CRD} contract comments.
@dev This interface allows usage of the Security contract to be decoupled from the implementation.
*/
interface ISecurity is IRoyalty {
    function getSecurityId() external view returns(uint256);
    function getName() external view returns(string memory);
    function getSymbol() external view returns(string memory);
    function getKyc() external view returns(IKYC);
    function getDivToken() external view returns(IERC20Upgradeable);
    function getHoldPeriod(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import './ISecurity.sol';

/**
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@notice See terms in {CRD} contract comments.
*/
// solhint-disable-next-line no-empty-blocks
interface ISecurityERC721 is ISecurity, IERC721Upgradeable {}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';

/**
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@notice See terms in {CRD} contract comments.
@dev This interface allows usage of the Tier contract to be decoupled from the implementation.
*/
interface ITier {
    event URIUpdated(uint256 indexed tierId, address caller);

    struct TierInfo {
        uint256 tierId;
        string name;
        uint256 tokenRevPercent; // % revenue per token (e.g. numerator / DISPLAY_DIVISOR
        string uriA; // The URI is split across multiple segments to page the (de)allocations
        string uriB;
        string uriC;
        string uriD;
        EnumerableSetUpgradeable.UintSet tokenIds; // to enumerate tokens in a tier during div allocation

        // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
        uint256[12] __gap; // Array size + the sum of all storage slots used (except this member) should be 20
    }

    function getTierCount() external view returns(uint256);
    function getTier(uint256 tierId) external view returns(string memory, uint256, uint256);
    function getTiers(uint256 indexBegin, uint256 indexEnd) external view
        returns(uint256[] memory, string[] memory, uint256[] memory, uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

/**
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@notice See terms in {CRD} contract comments.
@dev This interface allows usage of the Token contract to be decoupled from the implementation.
*/
interface IToken {
    struct TokenInfo {
        address owner; // This saves an additional lookup via ERC721.ownerOf(tokenId)
        uint256 tierId;
        uint256 holdPeriodEnd; // When token can be traded, stored as seconds since unix epoch

        // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
        uint256[7] __gap; // Array size + the sum of all storage slots used (except this member) should be 10
    }
    function getToken(uint256 tokenId) external view returns(address, uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import './IRoyalty.sol';
import './Checks.sol';

/**
@title A CRD utility for royalty features supporting multiple payees and independent of a specific currency
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@notice See terms in {CRD} contract comments.
@dev This contract modularizes features in the {CRD} contract
@dev ERC2981 was considered but it requires a proxy to split an amount among payees, this does not
*/
abstract contract Royalty is IRoyalty, Initializable {
    // UPGRADABILITY: See https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts
    address[] internal _royaltyReceivers;
    uint256[] internal _royaltyAmounts; // % royalty = amount / DISPLAY_DIVISOR
    // UPGRADABILITY: All new variables should be immediately above this line and decrement the gap array

    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[13] private __gap; // Array size + the sum of all storage slots used (except this member) should be 15

    // Constants become literals during compile with no impact on the data layout
    uint256 private constant AMOUNT_MAX = 500_000_000_000_000_000; // An upper bound sanity check
    uint256 internal constant DISPLAY_DIVISOR = 10 ** 18;

    /// @dev Upgradeable contracts have a 2 part initialization: constructor(empty) + init(args), for more info see:
    ///  https://docs.openzeppelin.com/contracts/4.x/upgradeable#usage
    function __Royalty_init(address[] memory receivers, uint256[] memory amounts) internal onlyInitializing {
        _setRoyaltyPayees(receivers, amounts);
    }

    /// @return An array of receivers and their respective fees based on the salePrice along with the sum of fees
    function getRoyaltyFees(uint256 salePrice) external view returns(address[] memory, uint256[] memory, uint256) {
        uint256 sumOfFees;
        uint256[] memory fees = _royaltyAmounts; // copy as initial value, more performant than iterative reads?
        unchecked {
            // slither-disable-next-line uninitialized-local // value zero init is default behavior
            for(uint256 i; i < fees.length; ++i) // See ROYALTY_COUNT
                sumOfFees += fees[i] = (salePrice * fees[i]) / DISPLAY_DIVISOR;
        }
        return(_royaltyReceivers, fees, sumOfFees);
    }

    function getRoyaltyPayees() external view returns(address[] memory, uint256[] memory) {
        return(_royaltyReceivers, _royaltyAmounts); // See ROYALTY_COUNT
    }

    function _setRoyaltyPayees(address[] memory receivers, uint256[] memory amounts) internal {
        _checkArrayLength(Tag.receiversLength, receivers.length, amounts.length);
        uint256 amountSum;
        unchecked {
            // slither-disable-next-line uninitialized-local // value zero init is default behavior
            for(uint256 i; i < receivers.length; ++i) { // ROYALTY_COUNT: likely 1 or 2, paging is not a concern
                _checkAddress(Tag.receiver, receivers[i]);
                _checkRange(Tag.royaltyAmount, 1, AMOUNT_MAX, amounts[i]);
                amountSum += amounts[i];
            }
        }
        _checkRange(Tag.amountsSum, amounts.length, AMOUNT_MAX, amountSum);
        _royaltyReceivers = receivers;
        _royaltyAmounts = amounts;
        emit RoyaltyPayeesUpdate(receivers, amounts, msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

/**
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@dev This library uses 'unchecked' and 'assembly' blocks to reduce gas and allow on-chain metadata
*/
library String {
    // Constants become literals during compile
    uint256 public constant WORD = 32; // An EVM word length in bytes (256 bits)

    error MergeOverflow(uint256 main, uint256 offset, uint256 input);
    error BadOffset(uint256 offset);
    error NoShortString(uint256 input);

    /**
    @dev Copy input's content to main[offset], main is not resized so a sufficient preallocation is required
    @param main preallocated storage allowing the string to be built across several calls with a single allocation
    @param input the segment to merge into main, calldata prevents a copy of a potentially large string
    @param offset the number of chars from the beginning of main to begin writing input, must be multiple of WORD
    @dev Offsets are restricted to WORD boundaries to avoid handling unaligned writes with mask + carry
    @dev Assembly allows us to allocate a string once and then copy segments into it, avoiding reallocations
    @dev Assembly multibyte copies are substantially more efficient than iterating a single byte at a time
    @dev String storage: https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html#bytes-and-string
    */
    function merge(string storage main, string calldata input, uint256 offset) external {
        unchecked {
            uint256 inLen = bytes(input).length;
            if(inLen == 0) return;
            uint256 mainLen; // preallocated buffer length
            uint256 mainPtr; // buffer begin location
            {
                uint256 slot;
                uint256 isLong;
                assembly { // solhint-disable-line no-inline-assembly
                    slot := main.slot
                    mainLen := sload(slot)
                    isLong := and(mainLen, 1) // Get lowest bit
                }
                if(isLong == 0) revert NoShortString(mainLen); // on error, mainLen has byte[0]=len*2, bytes[1-31]=data
                mainLen >>= 1; // value in slot was: length*2+1, the shift gets us length
                mainPtr = uint256(keccak256(abi.encode(slot)));
            }
            if(mainLen < offset + inLen) revert MergeOverflow(mainLen, offset, inLen); // ensures memory preallocation
            if(offset % WORD != 0) revert BadOffset(offset); // avoids mask-and-carry logic and inefficiencies
            uint256 src;
            // solhint-disable-next-line no-inline-assembly
            assembly { src := input.offset }

            uint256 dst = mainPtr + (offset / WORD);
            for(; inLen >= WORD; inLen -= WORD) { // Copy full word(s)
                // solhint-disable-next-line no-inline-assembly
                assembly { sstore(dst, calldataload(src)) }
                src += WORD;
                ++dst;
            }
            if (inLen == 0) return;

            // Copy partial word
            uint256 mask = 256 ** (WORD - inLen) - 1; // filter out-of-bounds bytes
            assembly { // solhint-disable-line no-inline-assembly
                let dstPart := and(sload(dst), mask)
                let srcPart := and(calldataload(src), not(mask))
                sstore(dst, or(dstPart, srcPart)) // merge prev dst and new src
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import './ITier.sol';
import './Checks.sol';
import './String.sol';

error UnknownTierId(uint256 tierId);
error InvertedIndexes(uint256 begin, uint256 end);
error ShortURI(uint256 length);
error BadPageId(uint256 segmentId);
error BadPageLength(uint256 length);
error BadSegmentLength(uint256 length);
error BadURILength(uint256 length);

error DebugX(uint256 length);

/**
@title A CRD utility for tier features
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@notice See terms in {CRD} contract comments.
@dev This contract modularizes features in the {CRD} contract such as having an iterable collection of unique tier ids
    and allows for storing tier related data via TierInfo.
*/
contract Tier is ITier, Initializable {
    // UPGRADABILITY: https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts
    mapping(uint256 => TierInfo) private _tiers; // key = tier id
    EnumerableSetUpgradeable.UintSet internal _tierIds; // tierIds to enumerate for allocations
    uint256 internal _tierIdSeed;
    // UPGRADABILITY: All new variables should be immediately above this line
    
    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[12] private __gap; // Array size + the sum of all storage slots used (except this member) should be 15

    /// @dev Upgradeable contracts have a 2 part initialization: constructor(empty) + init(args), for more info see:
    ///  https://docs.openzeppelin.com/contracts/4.x/upgradeable#usage
    function __Tier_init() internal onlyInitializing {} // solhint-disable-line no-empty-blocks

    function getTier(uint256 tierId) external view returns(string memory, uint256, uint256) {
        TierInfo storage tier = _getTier(tierId);
        return(tier.name, tier.tokenRevPercent, EnumerableSetUpgradeable.length(tier.tokenIds));
    }

    function getTierCount() external view returns(uint256) { return EnumerableSetUpgradeable.length(_tierIds); }

    function getTiers(uint256 indexBegin, uint256 indexEnd)
        external view returns(uint256[] memory, string[] memory, uint256[] memory, uint256[] memory)
    {
        if(indexBegin > indexEnd) revert InvertedIndexes(indexBegin, indexEnd);
        uint256 tierCount = EnumerableSetUpgradeable.length(_tierIds);
        uint256 end = indexEnd < tierCount ? indexEnd : tierCount - 1;
        uint256[] memory tierIds = new uint256[](tierCount);
        string[] memory names = new string[](tierCount);
        uint256[] memory tokenRevPercents = new uint256[](tierCount);
        uint256[] memory tokenCounts = new uint256[](tierCount);
        unchecked {
            for(uint256 i = indexBegin; i <= end; ++i) { // See TIER_COUNT. Likely few, caller must page
                TierInfo storage tier = _tiers[EnumerableSetUpgradeable.at(_tierIds, i)];
                tierIds[i] = tier.tierId;
                names[i] = tier.name;
                tokenRevPercents[i] = tier.tokenRevPercent;
                tokenCounts[i] = EnumerableSetUpgradeable.length(tier.tokenIds);
            }
        }
        return(tierIds, names, tokenRevPercents, tokenCounts);
    }

    function _createTier(uint256 tierId, string memory name_, uint256 tokenRevPercent) internal {
        _checkString(Tag.tierName, name_);
        // slither-disable-next-line unused-return
        EnumerableSetUpgradeable.add(_tierIds, tierId);
        TierInfo storage tier = _tiers[tierId];
        tier.tierId = tierId; // useful if tier found by index
        tier.name = name_; // uniqueness should be guaranteed by caller
        tier.tokenRevPercent = tokenRevPercent;
    }

    function _getTier(uint256 tierId) internal view returns(TierInfo storage) {
        TierInfo storage tier = _tiers[tierId];
        if(tier.tokenRevPercent == 0) revert UnknownTierId(tierId);
        return tier;
    }

    function _destroyTier(uint256 tierId) internal {
        // slither-disable-next-line unused-return
        EnumerableSetUpgradeable.remove(_tierIds, tierId);
        TierInfo storage tier = _getTier(tierId);
        // Ensure TierInfo.tokenIds is empty since deleting the struct does not delete items in a nested mapping
        _checkZero(Tag.tierTokenIds, EnumerableSetUpgradeable.length(tier.tokenIds));
        delete _tiers[tierId];
    }

    // Constants become literals during compile
    uint256 public constant URI_PAGES = 4; // uriA, uriB, uriC, uriD
    uint256 public constant URI_PAGE_MAX_BYTES = 128 * 1024; // 175 KB may be possible w/ more testing
    uint256 public constant URI_MAX_BYTES = URI_PAGE_MAX_BYTES * URI_PAGES;

    /// @dev pages are allocated (length > 0) and deallocated (length = 0) individually due to gas limits
    /// @dev tests have allowed a URI capacity of 512 KB with page sizes of 128 KB
    function _allocateURIPage(uint256 tierId, uint256 pageId, uint256 length) internal {
        if(length > URI_PAGE_MAX_BYTES) revert BadPageLength(length);
        TierInfo storage tier = _getTier(tierId);
        if(pageId == 0) tier.uriA = new string(length);
        else if(pageId == 1) tier.uriB = new string(length);
        else if(pageId == 2) tier.uriC = new string(length);
        else if(pageId == 3) tier.uriD = new string(length);
        else revert BadPageId(pageId);
    }

    /// @dev See function usage for parameter descriptions
    /// @dev tests have allowed segments of 32 KB in the context of 128 KB pages w/ a 512 KB capacity, these
    ///     segments are on the larger side as they used ~23.3M gas in a transaction block w/ a 30M gas limit
    function _setURISegment(uint256 tierId, uint256 offset, uint256 uriLength, string calldata segment) internal {
        unchecked {
            // uint256 segLen = bytes(segment).length; // avoiding 'stack too deep'
            if(bytes(segment).length == 0) revert BadSegmentLength(bytes(segment).length);
            if(uriLength < 32 || URI_MAX_BYTES < uriLength) revert BadURILength(uriLength);
            TierInfo storage tier = _getTier(tierId);
            // The page is determined here but the caller must ensure the segment fits else String.merge will fail
            uint256 aLen = bytes(tier.uriA).length;
            if(aLen == 0) revert BadPageId(0);
            if(offset < aLen)
                String.merge(tier.uriA, segment, offset);
            else {
                uint256 bLen = bytes(tier.uriB).length;
                if(bLen == 0) revert BadPageId(1);
                if(offset < aLen + bLen) {
                    String.merge(tier.uriB, segment, offset - aLen);
                } else {
                    uint256 cLen = bytes(tier.uriC).length;
                    if(cLen == 0) revert BadPageId(2);
                    if(offset < aLen + bLen + cLen) {
                        String.merge(tier.uriC, segment, offset - aLen - bLen);
                    } else {
                        if(bytes(tier.uriD).length == 0) revert BadPageId(3);
                        String.merge(tier.uriD, segment, offset - aLen - bLen - cLen);
                    }
                }
            }
            if(offset + bytes(segment).length >= uriLength) { // last segment
                // It would be nice to swap the incrementally built URI at this point to prevent users from seeing a
                // partially-built URI. While too much gas to reallocate, a double buffer + pointer swap could work.
                emit URIUpdated(tierId, msg.sender);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol';
import './IToken.sol';

error UnknownTokenId(uint256 tokenId);

/**
@title A CRD utility for token features
@author Jason Aubrey (GigaStar)
@notice Copyright 2023, GigaStar Technologies LLC, All Rights Reserved, https://gigastar.io
@notice See terms in {CRD} contract comments.
@dev This contract modularizes features in the {CRD} contract such as having a collection of unique token ids and
    allows for storing token related data via TokenInfo
*/
abstract contract Token is IToken, Initializable {
    // UPGRADABILITY: https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts
    mapping(uint256 => TokenInfo) private _tokens; // key = token id
    uint256 internal _tokenIdSeed;
    // UPGRADABILITY: All new variables should be immediately above this line and decrement the gap array
    
    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[13] private __gap; // Array size + the sum of all storage slots used (except this member) should be 15

    /// @dev Upgradeable contracts have a 2 part initialization: constructor(empty) + init(args), for more info see:
    ///  https://docs.openzeppelin.com/contracts/4.x/upgradeable#usage
    function __Token_init() internal onlyInitializing {} // solhint-disable-line no-empty-blocks

    function getToken(uint256 tokenId) external view override returns(address, uint256, uint256) {
        TokenInfo storage token = _getToken(tokenId);
        return(token.owner, token.tierId, token.holdPeriodEnd);
    }

    function _createToken(address tokenOwner, uint256 tierId, uint256 holdPeriodEnd) internal {
        // slither-disable-next-line uninitialized-local // value zero init is default behavior
        uint256[7] memory gap;
        _tokens[++_tokenIdSeed] = TokenInfo(tokenOwner, tierId, holdPeriodEnd, gap);
    }

    function _getToken(uint256 tokenId) internal view returns(TokenInfo storage) {
        TokenInfo storage token = _tokens[tokenId];
        if(token.tierId == 0) revert UnknownTokenId(tokenId);
        return token;
    }

    function _deleteToken(uint256 tokenId) internal { delete _tokens[tokenId]; }
}