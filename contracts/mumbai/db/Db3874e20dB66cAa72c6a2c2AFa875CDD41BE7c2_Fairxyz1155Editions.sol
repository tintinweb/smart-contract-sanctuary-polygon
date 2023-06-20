// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

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
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
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
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract MulticallUpgradeable is Initializable {
    function __Multicall_init() internal onlyInitializing {
    }

    function __Multicall_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = AddressUpgradeable.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
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
 * ```solidity
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
library EnumerableSet {
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

// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

import {FairxyzEditionsUpgradeable} from "./FairxyzEditionsUpgradeable.sol";
import {Fairxyz1155Upgradeable} from "../ERC1155/Fairxyz1155Upgradeable.sol";
import {FairxyzOperatorFiltererUpgradeable} from "../OperatorFilterer/FairxyzOperatorFiltererUpgradeable.sol";

import {EditionCreateParams} from "../interfaces/IFairxyzEditions.sol";
import {IFairxyz1155Editions} from "../interfaces/IFairxyz1155Editions.sol";
import {Stage} from "../interfaces/IFairxyzMintStagesRegistry.sol";

/**
 * @title Fair.xyz 1155 Editions
 * @author Fair.xyz Developers
 *
 * @dev This contract is the ERC-1155 implementation for the Fair.xyz Editions Collections.
 * @dev It inherits the FairxyzEditionsUpgradeable contract, adding ERC-1155 specific functionality.
 * @dev It also inherits the FairxyzOperatorFiltererUpgradeable contract, adding operator filtering functionality for token approvals and transfers.
 */
contract Fairxyz1155Editions is
    Fairxyz1155Upgradeable,
    FairxyzOperatorFiltererUpgradeable,
    IFairxyz1155Editions,
    FairxyzEditionsUpgradeable
{
    // Token name
    string public name;

    // Token symbol
    string public symbol;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        uint256 fairxyzMintFee_,
        address fairxyzReceiver_,
        address fairxyzSigner_,
        address fairxyzStagesRegistry_,
        uint256 maxRecipientsPerAirdrop_,
        address operatorFilterRegistry_,
        address operatorFilterSubscription_
    )
        FairxyzEditionsUpgradeable(
            fairxyzMintFee_,
            fairxyzReceiver_,
            fairxyzSigner_,
            fairxyzStagesRegistry_,
            type(uint40).max,
            maxRecipientsPerAirdrop_
        )
        FairxyzOperatorFiltererUpgradeable(
            operatorFilterRegistry_,
            operatorFilterSubscription_
        )
    {
        _disableInitializers();
    }

    /**
     * @notice Initialise the collection.
     *
     * @param name_ The name of the collection.
     * @param symbol_ The symbol of the collection.
     * @param owner_ The address which should own the contract after initialization.
     * @param defaultRoyalty_ The default royalty fraction/percentage for the collection.
     * @param editions_ Initial editions to create.
     * @param operatorFilterEnabled_ Whether operator filtering should be enabled.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint96 defaultRoyalty_,
        EditionCreateParams[] calldata editions_,
        bool operatorFilterEnabled_
    ) external initializer {
        __Fairxyz1155_init();
        __FairxyzEditions_init(owner_);
        __FairxyzOperatorFilterer_init(operatorFilterEnabled_);

        _batchCreateEditionsWithStages(editions_);

        if (defaultRoyalty_ > 0) {
            _setDefaultRoyalty(owner_, defaultRoyalty_);
        }

        name = name_;
        symbol = symbol_;
    }

    // * PUBLIC * //

    /**
     * @dev See {IFairxyz1155Editions-burn}.
     */
    function burn(
        address from,
        uint256 editionId,
        uint256 amount
    ) external override {
        address operator = msg.sender;
        if (operator != from && !isApprovedForAll(from, operator))
            revert NotApprovedOrOwner();

        if (!_editions[editionId].burnable) revert NotBurnable();
        _burn(from, editionId, amount);
        _editionBurnedCount[editionId] += amount;
    }

    // * OVERRIDES * //

    /**
     * @dev See {IERC2981Upgradeable-royaltyInfo}.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        Royalty memory royalty = _editionRoyalty[tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyalty;
        }

        receiver = royalty.receiver;
        royaltyAmount =
            (salePrice * royalty.royaltyFraction) /
            ROYALTY_DENOMINATOR;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     * @dev Modified to check operator against Operator Filter Registry.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC165Upgradeable-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(Fairxyz1155Upgradeable, FairxyzEditionsUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IFairxyz1155Editions).interfaceId ||
            Fairxyz1155Upgradeable.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataUpgradeable-uri}.
     */
    function uri(uint256 id) external view override returns (string memory) {
        if (!_editionExists(id)) return "";
        return _editionURI[id];
    }

    /**
     * @dev See {Fairxyz1155Upgradeable-_beforeTokenTransfer}.
     * @dev Modified to check `msg.sender` against Operator Filter Registry.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal virtual override onlyAllowedOperator(operator, from) {
        // we only want to implement soulbound guard if the token is being transferred between two non-zero addresses
        if (from == address(0) || to == address(0)) {
            return;
        }

        for (uint256 i; i < ids.length; ) {
            uint256 id = ids[i];
            if (_editions[id].soulbound) {
                revert NotTransferable();
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {FairxyzEditionsUpgradeable-_emitMetadataUpdateEvent}.
     */
    function _emitMetadataUpdateEvent(
        uint256 editionId,
        string memory editionURI
    ) internal override {
        emit URI(editionURI, editionId);
    }

    /**
     * @dev See {OperatorFiltererUpgradeable-_isOperatorFilterAdmin}.
     */
    function _isOperatorFilterAdmin(
        address sender
    ) internal view virtual override returns (bool) {
        return sender == owner() || hasRole(DEFAULT_ADMIN_ROLE, sender);
    }

    /**
     * @dev See {FairxyzEditionsUpgradeable-_mintEditionTokens}.
     */
    function _mintEditionTokens(
        address recipient,
        uint256 editionId,
        uint256 quantity,
        uint256
    ) internal override {
        if (quantity == 0) revert InvalidMintQuantity();

        _mint(recipient, editionId, quantity, "");
    }
}

// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {MulticallUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

/**
 * @title Fair.xyz Editions Base Upgradeable
 * @dev This contract is the base contract for all Fair.xyz Editions contracts.
 * @dev It inherits the OpenZeppelin AccessControlUpgradeable, Ownable2StepUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, and MulticallUpgradeable contracts.
 */
abstract contract FairxyzEditionsBaseUpgradeable is
    Initializable,
    AccessControlUpgradeable,
    MulticallUpgradeable,
    Ownable2StepUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     * @dev See {IERC165Upgradeable-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

/**
 * @title Fair.xyz Editions Constants
 * @dev This contract contains all of the constants and immutable values used in the Fair.xyz Editions contracts.
 * @dev IMPORTANT: This should not have any variables which use storage slots - as a result it is possible to be inherited by upgradeable contracts without the need for a storage 'gap'.
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable
 */
contract FairxyzEditionsConstants {
    // * SIGNATURES * //
    bytes32 internal constant EIP712_NAME_HASH = keccak256("Fair.xyz");
    bytes32 internal constant EIP712_VERSION_HASH = keccak256("2.0.0");
    bytes32 internal constant EIP712_DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 internal constant EIP712_EDITION_MINT_TYPE_HASH =
        keccak256(
            "EditionMint(uint256 editionId,address recipient,uint256 quantity,uint256 nonce,uint256 maxMints)"
        );

    // * ROLES * //
    bytes32 internal constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    bytes32 internal constant EXTERNAL_MINTER_ROLE =
        keccak256("EXTERNAL_MINTER_ROLE");

    uint256 internal constant ROYALTY_DENOMINATOR = 10000;
    uint256 internal constant SIGNATURE_VALID_BLOCKS = 75;

    // * IMMUTABLES * //
    uint256 internal immutable FAIRXYZ_MINT_FEE;
    address internal immutable FAIRXYZ_RECEIVER_ADDRESS;
    address internal immutable FAIRXYZ_FAIRXYZ_SIGNER_ADDRESS;
    address internal immutable FAIRXYZ_STAGES_REGISTRY;

    uint256 internal immutable MAX_EDITION_SIZE;
    uint256 internal immutable MAX_RECIPIENTS_PER_AIRDROP;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        uint256 fairxyzMintFee_,
        address fairxyzReceiver_,
        address fairxyzSigner_,
        address fairxyzStagesRegistry_,
        uint256 maxEditionSize_,
        uint256 maxRecipientsPerAirdrop_
    ) {
        FAIRXYZ_MINT_FEE = fairxyzMintFee_;
        FAIRXYZ_RECEIVER_ADDRESS = fairxyzReceiver_;
        FAIRXYZ_FAIRXYZ_SIGNER_ADDRESS = fairxyzSigner_;
        FAIRXYZ_STAGES_REGISTRY = fairxyzStagesRegistry_;

        MAX_EDITION_SIZE = maxEditionSize_;
        MAX_RECIPIENTS_PER_AIRDROP = maxRecipientsPerAirdrop_;
    }
}

// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {IERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

import {FairxyzEditionsBaseUpgradeable} from "./FairxyzEditionsBaseUpgradeable.sol";
import {FairxyzEditionsConstants} from "./FairxyzEditionsConstants.sol";

import {IERC2981Upgradeable} from "../interfaces/IERC2981Upgradeable.sol";
import {Edition, EditionCreateParams, EditionMinter, IFairxyzEditions} from "../interfaces/IFairxyzEditions.sol";

import {IFairxyzMintStagesRegistry, Stage} from "../interfaces/IFairxyzMintStagesRegistry.sol";

abstract contract FairxyzEditionsUpgradeable is
    FairxyzEditionsBaseUpgradeable,
    FairxyzEditionsConstants,
    IERC2981Upgradeable,
    IFairxyzEditions
{
    using AddressUpgradeable for address payable;
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    address internal _primarySaleReceiver;

    Royalty internal _defaultRoyalty;

    uint256 private _editionsCount;

    mapping(uint256 => Edition) internal _editions;

    mapping(uint256 => bool) internal _editionDeleted;

    mapping(uint256 => uint256) internal _editionBurnedCount;

    mapping(uint256 => uint256) internal _editionMintedCount;

    mapping(uint256 => mapping(address => EditionMinter))
        private _editionMinters;

    mapping(uint256 => Royalty) internal _editionRoyalty;

    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        private _editionStageMints;

    mapping(uint256 => string) internal _editionURI;

    modifier onlyDefaultAdmin() {
        _checkRole(DEFAULT_ADMIN_ROLE);
        _;
    }

    modifier onlyAirdropRoles() {
        if (!hasRole(CREATOR_ROLE, msg.sender)) {
            _checkRole(EXTERNAL_MINTER_ROLE);
        }
        _;
    }

    modifier onlyCreator() {
        _checkRole(CREATOR_ROLE);
        _;
    }

    modifier onlyExistingEdition(uint256 editionId) {
        if (!_editionExists(editionId)) revert EditionDoesNotExist();
        _;
    }

    modifier onlyValidRoyaltyFraction(uint256 royaltyFraction) {
        if (royaltyFraction > ROYALTY_DENOMINATOR)
            revert InvalidRoyaltyFraction();
        _;
    }

    receive() external payable virtual {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        uint256 fairxyzMintFee_,
        address fairxyzReceiver_,
        address fairxyzSigner_,
        address fairxyzStagesRegistry_,
        uint256 maxEditionSize_,
        uint256 maxRecipientsPerAirdrop_
    )
        FairxyzEditionsConstants(
            fairxyzMintFee_,
            fairxyzReceiver_,
            fairxyzSigner_,
            fairxyzStagesRegistry_,
            maxEditionSize_,
            maxRecipientsPerAirdrop_
        )
    {
        _disableInitializers();
    }

    // * INITIALIZERS * //

    function __FairxyzEditions_init(address owner_) internal onlyInitializing {
        __FairxyzEditions_init_unchained(owner_);
    }

    function __FairxyzEditions_init_unchained(
        address owner_
    ) internal onlyInitializing {
        if (owner_ == address(0)) {
            revert ZeroAddress();
        }

        _primarySaleReceiver = owner_;
        _transferOwnership(owner_);
    }

    // * PUBLIC * //

    /**
     * @dev See {IFairxyzEditions-mintEdition}.
     */
    function mintEdition(
        uint256 editionId,
        address recipient,
        uint256 quantity,
        uint40 signatureNonce,
        uint256 signatureMaxMints,
        bytes memory signature
    ) external payable override whenNotPaused {
        _checkMintSignature(
            editionId,
            recipient,
            quantity,
            signatureNonce,
            signatureMaxMints,
            signature
        );

        (uint256 stageIndex, Stage memory stage) = _stagesRegistry()
            .viewActiveStage(address(this), editionId);

        uint256 costPerToken = stage.price + FAIRXYZ_MINT_FEE;

        if (msg.value != quantity * costPerToken) {
            revert IncorrectEthValue();
        }

        EditionMinter memory editionMinter = _editionMinters[editionId][
            recipient
        ];

        uint256 recipientStageMints = _editionStageMints[editionId][stageIndex][
            recipient
        ];

        uint256 editionMintedTotal = _editionMintedCount[editionId];

        uint256 allowedQuantity = _calculateAllowedMintQuantity(
            quantity,
            editionId,
            editionMintedTotal,
            stage,
            editionMinter.mintedCount,
            recipientStageMints,
            signatureMaxMints
        );

        unchecked {
            _editionMinters[editionId][recipient] = EditionMinter(
                editionMinter.mintedCount + uint40(allowedQuantity),
                signatureNonce
            );

            _editionStageMints[editionId][stageIndex][
                recipient
            ] += allowedQuantity;
            _editionMintedCount[editionId] += allowedQuantity;

            _mintEditionTokens(
                recipient,
                editionId,
                allowedQuantity,
                editionMintedTotal
            );

            emit EditionStageMint(
                editionId,
                stageIndex,
                recipient,
                allowedQuantity,
                editionMintedTotal + allowedQuantity
            );

            payable(FAIRXYZ_RECEIVER_ADDRESS).sendValue(
                FAIRXYZ_MINT_FEE * allowedQuantity
            );

            // refund for excess quantity not allowed to mint
            if (allowedQuantity < quantity) {
                uint256 refundAmount = (quantity - allowedQuantity) *
                    costPerToken;
                payable(msg.sender).sendValue(refundAmount);
            }
        }
    }

    /**
     * @dev See {IFairxyzEditions-editionTotalSupply}.
     */
    function editionTotalSupply(
        uint256 editionId
    ) public view virtual override returns (uint256) {
        return _editionMintedCount[editionId] - _editionBurnedCount[editionId];
    }

    /**
     * @dev See {IFairxyzEditions-getEdition}.
     */
    function getEdition(
        uint256 editionId
    )
        public
        view
        virtual
        onlyExistingEdition(editionId)
        returns (Edition memory)
    {
        return _editions[editionId];
    }

    /**
     * @dev See {IFairxyzEditions-totalSupply}.
     */
    function totalSupply()
        external
        view
        virtual
        override
        returns (uint256 supply)
    {
        for (uint256 i = 1; i <= _editionsCount; ) {
            supply += editionTotalSupply(i);
            unchecked {
                ++i;
            }
        }
    }

    // * ADMIN * //

    /**
     * @notice Airdrop Tokens for a Single Edition to Multiple Wallets
     * @dev See {IFairEditionsUpgradeable-airdropEdition}.
     *
     * Requirements:
     * - the edition must exist
     * - number of recipients must not be greater than `MAX_RECIPIENTS_PER_AIRDROP`
     * - quantity must not be greater than `MAX_MINTS_PER_TRANSACTION`
     *
     * Emits an {EditionAirdrop} event.
     */
    function airdropEdition(
        uint256 editionId,
        uint256 quantity,
        address[] memory recipients
    )
        external
        virtual
        override
        onlyAirdropRoles
        onlyExistingEdition(editionId)
        whenNotPaused
    {
        uint256 numberOfRecipients = recipients.length;
        if (
            numberOfRecipients == 0 ||
            numberOfRecipients > _maxRecipientsPerAirdrop()
        ) revert InvalidNumberOfRecipients();

        // check and update available supply
        uint256 totalQuantity = numberOfRecipients * quantity;
        uint256 editionMintedTotal = _editionMintedCount[editionId];

        if (
            totalQuantity + editionMintedTotal >
            _editionMintLimit(_editions[editionId].maxSupply)
        ) revert NotEnoughSupplyRemaining();

        _editionMintedCount[editionId] = editionMintedTotal + totalQuantity;

        uint256 i;
        do {
            address recipient = recipients[i];
            _mintEditionTokens(
                recipient,
                editionId,
                quantity,
                editionMintedTotal
            );

            unchecked {
                editionMintedTotal += quantity;
                ++i;
            }
        } while (i < numberOfRecipients);

        emit EditionAirdrop(
            editionId,
            _stagesRegistry().viewLatestStageIndex(address(this), editionId), // even though airdrops do not count towards stage mints, it is useful to know at what stage it occurred
            recipients,
            quantity,
            editionMintedTotal
        );
    }

    /**
     * @notice Add a New Edition
     * @dev See {IFairxyzEditions-createEdition}.
     */
    function createEditions(
        EditionCreateParams[] calldata editions
    ) external virtual override onlyCreator {
        _batchCreateEditionsWithStages(editions);
    }

    /**
     * @notice Delete Edition
     * @dev See {IFairxyzEditions-deleteEdition}.
     */
    function deleteEdition(
        uint256 editionId
    ) external virtual override onlyCreator onlyExistingEdition(editionId) {
        if (_editionMintedCount[editionId] > 0) revert EditionAlreadyMinted();
        _deleteEdition(editionId);
    }

    /**
     * @notice Disable Signature Requirement for an Edition
     * @dev See {IFairxyzEditions-releaseEditionSignature}.
     */
    function releaseEditionSignature(
        uint256 editionId
    ) external virtual override onlyCreator onlyExistingEdition(editionId) {
        if (_editions[editionId].signatureReleased)
            revert EditionSignatureAlreadyReleased();
        _editions[editionId].signatureReleased = true;
        emit EditionSignatureReleased(editionId);
    }

    /**
     * @notice Set Default Royalty
     * @dev See {IFairxyzEditions-setDefaultRoyalty}.
     *
     * Emits a {DefaultRoyalty} event.
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 royaltyFraction
    ) external virtual override onlyDefaultAdmin {
        _setDefaultRoyalty(receiver, royaltyFraction);
    }

    /**
     * @dev See {IFairxyzEditions-setEditionBurnable}.
     *
     * Emits an {EditionBurnable} event.
     */
    function setEditionBurnable(
        uint256 editionId,
        bool burnable
    ) external virtual override onlyCreator onlyExistingEdition(editionId) {
        _editions[editionId].burnable = burnable;
        emit EditionBurnable(editionId, burnable);
    }

    /**
     * @notice Set Edition Maximum Mints Per Wallet
     * @dev See {IFairxyzEditions-setEditionMaxMintsPerWallet}.
     */
    function setEditionMaxMintsPerWallet(
        uint256 editionId,
        uint40 maxMintsPerWallet
    ) external virtual override onlyCreator onlyExistingEdition(editionId) {
        _editions[editionId].maxMintsPerWallet = maxMintsPerWallet;
        emit EditionMaxMintsPerWallet(editionId, maxMintsPerWallet);
    }

    /**
     * @notice Set Edition Maximum Supply
     * @dev See {IFairxyzEditions-setEditionMaxSupply}.
     *
     * Requirements:
     *
     * - the new max supply can't be greater than the current max supply
     * - the new max supply can't be less than the number of tokens already minted
     * - the new max supply can't be less than scheduled in current/upcoming mint stages
     */
    function setEditionMaxSupply(
        uint256 editionId,
        uint40 maxSupply
    ) external virtual override onlyCreator onlyExistingEdition(editionId) {
        if (maxSupply == 0) revert EditionSupplyCanOnlyBeReduced();
        if (maxSupply >= _editionMintLimit(_editions[editionId].maxSupply))
            revert EditionSupplyCanOnlyBeReduced();

        // check that max supply is not less than minted count
        // it's possible for the owner to airdrop more than stage phase limits so need to be checked separately
        if (maxSupply < _editionMintedCount[editionId])
            revert EditionSupplyLessThanMintedCount();

        (, Stage memory finalStage) = _stagesRegistry().viewFinalStage(
            address(this),
            editionId
        );

        // if final stage has not yet ended, check that max supply is not less than final stage phaseLimit
        if (
            finalStage.startTime > 0 && // if final stage startTime is 0, it means there is no final stage
            (finalStage.endTime >= block.timestamp || finalStage.endTime == 0) // if final stage endTime is 0, it means it never ends
        ) {
            // if final stage phaseLimit is 0, it means there is no limit and supply can't be reduced
            if (finalStage.phaseLimit == 0) {
                revert EditionSupplyLessThanScheduledStagesPhaseLimit();
            }

            if (maxSupply < finalStage.phaseLimit) {
                revert EditionSupplyLessThanScheduledStagesPhaseLimit();
            }
        }

        _editions[editionId].maxSupply = maxSupply;
        emit EditionMaxSupply(editionId, maxSupply);
    }

    /**
     * @notice Set Edition Royalties
     * @dev See {IFairxyzEditions-setEditionRoyalty}.
     */
    function setEditionRoyalty(
        uint256 editionId,
        address receiver,
        uint96 royaltyFraction
    )
        external
        virtual
        override
        onlyCreator
        onlyExistingEdition(editionId)
        onlyValidRoyaltyFraction(royaltyFraction)
    {
        if (receiver == address(0)) {
            delete _editionRoyalty[editionId];
            emit EditionRoyalty(editionId, address(0), 0);
            return;
        }

        _editionRoyalty[editionId] = Royalty(receiver, royaltyFraction);
        emit EditionRoyalty(editionId, receiver, royaltyFraction);
    }

    /**
     * @notice Set Edition Mint Stages
     * @dev See {IFairxyzEditions-setEditionStages}.
     * @dev Allows the stages admin to set new stages for an existing edition.
     *
     * Requirements:
     *
     * - The edition must already exist.
     * - The new stages phase limits must greater than the number of tokens already minted for the edition.
     * - The new stages phase limits must be less than or equal to the max supply of the edition.
     */
    function setEditionStages(
        uint256 editionId,
        uint256 fromIndex,
        Stage[] calldata stages
    ) external virtual override onlyCreator onlyExistingEdition(editionId) {
        if (stages.length == 0) {
            _stagesRegistry().cancelStages(address(this), editionId, fromIndex);
        } else {
            _stagesRegistry().setStages(
                address(this),
                editionId,
                fromIndex,
                stages,
                _editionMintedCount[editionId],
                _editions[editionId].maxSupply
            );
        }
    }

    /**
     * @notice Set Edition Metadata URI
     * @dev See {IFairxyzEditions-setEditionURI}.
     */
    function setEditionURI(
        uint256 editionId,
        string calldata uri
    ) external virtual override onlyCreator onlyExistingEdition(editionId) {
        _setEditionURI(editionId, uri);

        if (_editionMintedCount[editionId] > 0)
            _emitMetadataUpdateEvent(editionId, uri);
    }

    /**
     * @notice Set Primary Sale Receiver
     * @dev See {IFairxyzEditions-setPrimarySaleReceiver}.
     *
     * Emits a {PrimarySaleReceiver} event.
     */
    function setPrimarySaleReceiver(
        address primarySaleReceiver
    ) external virtual override onlyDefaultAdmin {
        if (primarySaleReceiver == address(0)) revert ZeroAddress();

        _primarySaleReceiver = primarySaleReceiver;
        emit PrimarySaleReceiver(primarySaleReceiver);
    }

    /**
     * @dev See {IFairxyzEditions-pause}.
     */
    function pause() external virtual override onlyDefaultAdmin {
        _pause();
    }

    /**
     * @dev See {IFairxyzEditions-unpause}.
     */
    function unpause() external virtual override onlyDefaultAdmin {
        _unpause();
    }

    /**
     * @dev See {IFairxyzEditions-withdraw}.
     */
    function withdraw() external override onlyDefaultAdmin {
        payable(_primarySaleReceiver).sendValue(address(this).balance);
    }

    // * OWNER * //

    /**
     * @dev See {IFairxyzEditions-grantDefaultAdmin}.
     */
    function grantDefaultAdmin(
        address admin
    ) external virtual override onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    // * INTERNAL * //

    /**
     * @dev Creates multiple editions and stores the mint stages for them if provided.
     *
     * @param editions the editions to create
     */
    function _batchCreateEditionsWithStages(
        EditionCreateParams[] calldata editions
    ) internal {
        uint256 editionsCount = _editionsCount;

        unchecked {
            for (uint256 i; i < editions.length; ) {
                // check edition supply is valid
                if (editions[i].edition.maxSupply > MAX_EDITION_SIZE) {
                    revert EditionSupplyTooLarge();
                }

                editionsCount++;

                // store the edition and emit the created event
                Edition memory edition = editions[i].edition;
                _editions[editionsCount] = edition;

                emit EditionCreated(
                    editionsCount,
                    editions[i].externalId,
                    edition
                );

                _setEditionURI(editionsCount, editions[i].uri);

                // set the initial minting schedule if given for the edition
                if (editions[i].mintStages.length > 0) {
                    _stagesRegistry().setStages(
                        address(this),
                        editionsCount,
                        0,
                        editions[i].mintStages,
                        0,
                        edition.maxSupply
                    );
                }

                ++i;
            }
        }

        _editionsCount = editionsCount;
    }

    /**
     * @dev Calculates the allowed mint quantity based on the requested quantity and current recipient, edition and stage data
     * @dev Reverts if the calculated quantity is zero
     *
     * @param requestedQuantity the desired quantity
     * @param editionId the ID of the edition to mint from
     * @param editionMintedTotal the total number of tokens already minted for the edition
     * @param stage the stage data
     * @param recipientEditionMints the number of tokens already minted to the recipient for the edition
     * @param recipientStageMints the number of tokens already minted to the recipient for the stage
     * @param signatureMaxMints an additional maximum mints restriction encoded in the signature, specific to the recipient at the time of minting
     */
    function _calculateAllowedMintQuantity(
        uint256 requestedQuantity,
        uint256 editionId,
        uint256 editionMintedTotal,
        Stage memory stage,
        uint256 recipientEditionMints,
        uint256 recipientStageMints,
        uint256 signatureMaxMints
    ) internal view virtual returns (uint256 quantity) {
        quantity = requestedQuantity;

        // recipient stage mints (including previously minted) cannot exceed signature max mints per wallet
        if (signatureMaxMints > 0) {
            if (recipientStageMints >= signatureMaxMints) {
                revert RecipientAllowanceUsed();
            }
            uint256 recipientRemainingMints = signatureMaxMints -
                recipientStageMints;
            if (quantity > recipientRemainingMints) {
                quantity = recipientRemainingMints;
            }
        }

        // recipient stage mints cannot exceed stage mints per wallet
        if (stage.mintsPerWallet > 0) {
            if (recipientStageMints >= stage.mintsPerWallet) {
                revert RecipientStageAllowanceUsed();
            }
            uint256 recipientStageRemainingMints = stage.mintsPerWallet -
                recipientStageMints;
            if (quantity > recipientStageRemainingMints) {
                quantity = recipientStageRemainingMints;
            }
        }

        Edition memory edition = getEdition(editionId);

        // recipient cannot exceed edition max mints per wallet
        if (edition.maxMintsPerWallet > 0) {
            if (recipientEditionMints >= edition.maxMintsPerWallet) {
                revert RecipientEditionAllowanceUsed();
            }
            uint256 recipientEditionRemainingMints = edition.maxMintsPerWallet -
                recipientEditionMints;
            if (quantity > recipientEditionRemainingMints) {
                quantity = recipientEditionRemainingMints;
            }
        }

        uint256 stagePhaseLimit = stage.phaseLimit;
        if (stagePhaseLimit == 0) {
            stagePhaseLimit = MAX_EDITION_SIZE;
        }

        // quantity cannot exceed stage remaining mints
        if (editionMintedTotal >= stagePhaseLimit) {
            revert StageSoldOut();
        }
        uint256 stageRemainingMints = stagePhaseLimit - editionMintedTotal;
        if (quantity > stageRemainingMints) {
            quantity = stageRemainingMints;
        }
    }

    /**
     * @dev Checks the mint signature is valid and also compares nonce to the state of the contract for the recipient.
     *
     * @param editionId the ID of the edition being minted
     * @param recipient the address of the intended recipient of minted tokens
     * @param quantity the requested quantity to mint
     * @param nonce the blocknumber at the time the signature was generated, used to determine reuse/expiry of the signature
     * @param maxMints an additional limitation on the number of max mints for the recipient and stage for this particular signature (0 is unlimited)
     * @param signature the signature to check
     */
    function _checkMintSignature(
        uint256 editionId,
        address recipient,
        uint256 quantity,
        uint256 nonce,
        uint256 maxMints,
        bytes memory signature
    ) internal virtual {
        if (_editions[editionId].signatureReleased) {
            return;
        }

        if (nonce > block.number) {
            revert InvalidSignatureNonce();
        }

        if (nonce + SIGNATURE_VALID_BLOCKS < block.number) {
            revert SignatureExpired();
        }

        if (nonce <= _editionMinters[editionId][recipient].lastUsedNonce) {
            revert SignatureAlreadyUsed();
        }

        bytes32 messageHash = _hashMintParams(
            editionId,
            recipient,
            quantity,
            nonce,
            maxMints
        );

        // Ensure the recovered address from the signature is the Fairxyz.xyz signer address
        if (messageHash.recover(signature) != FAIRXYZ_FAIRXYZ_SIGNER_ADDRESS)
            revert InvalidSignature();
    }

    /**
     * @dev Marks an edition as deleted.
     * @dev Deleted editions will be considered as none existent.
     *
     * Requirements:
     * - the edition must exist / not have already been deleted.
     *
     * Emits an {EditionDeleted} event.
     *
     * @param editionId the ID of the edition
     */
    function _deleteEdition(uint256 editionId) internal virtual {
        _editionDeleted[editionId] = true;
        emit EditionDeleted(editionId);
    }

    /**
     * @dev Checks for the existence of an edition based on created and not deleted edition IDs.
     *
     * @param editionId the ID of the edition to check
     */
    function _editionExists(uint256 editionId) internal view returns (bool) {
        if (
            editionId == 0 ||
            editionId > _editionsCount ||
            _editionDeleted[editionId]
        ) return false;
        return true;
    }

    /**
     * @dev Calculate the mint limit for an edition.
     *
     * @param editionMaxSupply the max supply of an edition
     *
     * @return limit
     */
    function _editionMintLimit(
        uint256 editionMaxSupply
    ) internal view virtual returns (uint256 limit) {
        if (editionMaxSupply == 0) {
            limit = MAX_EDITION_SIZE;
        } else {
            limit = editionMaxSupply;
        }
    }

    /**
     * @dev Emits metadata update event used by marketplaces to refresh token metadata.
     * @dev To be overridden by specific token implementation.
     *
     * - ERC-721 should emit ERC-4906 (Batch)MetadataUpdate event.
     * - ERC-1155 should emit the standard URI event.
     *
     * @param editionId the ID of the edition
     * @param uri the new URI
     */
    function _emitMetadataUpdateEvent(
        uint256 editionId,
        string memory uri
    ) internal virtual;

    /**
     * @dev Regenerates the expected signature digest for the mint params.
     */
    function _hashMintParams(
        uint256 editionId,
        address recipient,
        uint256 quantity,
        uint256 nonce,
        uint256 maxMints
    ) internal view returns (bytes32) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    EIP712_EDITION_MINT_TYPE_HASH,
                    editionId,
                    recipient,
                    quantity,
                    nonce,
                    maxMints
                )
            )
        );
        return digest;
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     */
    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPE_HASH,
                EIP712_NAME_HASH,
                EIP712_VERSION_HASH,
                block.chainid,
                address(this)
            )
        );

        return ECDSAUpgradeable.toTypedDataHash(domainSeparator, structHash);
    }

    /**
     * @dev Returns the maximum number of recipients that can be minted to in a single airdrop.
     */
    function _maxRecipientsPerAirdrop()
        internal
        view
        virtual
        returns (uint256)
    {
        return MAX_RECIPIENTS_PER_AIRDROP;
    }

    /**
     * @dev Mints `quantity` tokens of edition `editionId` to `recipient`.
     * @dev Intended to be overridden by inheriting contract which implements a particular token standard.
     *
     * @param recipient the address the tokens should be minted to
     * @param editionId the ID of the edition to mint tokens of
     * @param quantity the quantity of tokens to mint
     * @param editionMintedCount the number of tokens already minted for the edition
     */
    function _mintEditionTokens(
        address recipient,
        uint256 editionId,
        uint256 quantity,
        uint256 editionMintedCount
    ) internal virtual;

    /**
     * @dev Sets the default royalty details for the collection.
     *
     * @param receiver the address royalty payments should be sent to
     * @param royaltyFraction the numerator used to calculate the royalty percentage of a sale
     */
    function _setDefaultRoyalty(
        address receiver,
        uint96 royaltyFraction
    ) internal virtual onlyValidRoyaltyFraction(royaltyFraction) {
        if (receiver == address(0)) {
            delete _defaultRoyalty;
            emit DefaultRoyalty(address(0), 0);
            return;
        }

        _defaultRoyalty = Royalty(receiver, royaltyFraction);
        emit DefaultRoyalty(receiver, royaltyFraction);
    }

    function _setEditionURI(
        uint256 editionId,
        string memory uri
    ) internal virtual {
        if (bytes(uri).length == 0) {
            revert InvalidURI();
        }

        _editionURI[editionId] = uri;
        emit EditionURI(editionId, uri);
    }

    /**
     * @dev Returns the stages registry used for managing mint stages.
     */
    function _stagesRegistry()
        internal
        view
        virtual
        returns (IFairxyzMintStagesRegistry)
    {
        return IFairxyzMintStagesRegistry(FAIRXYZ_STAGES_REGISTRY);
    }

    // * OVERRIDES * //

    /**
     * @dev See {IERC165Upgradeable-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(FairxyzEditionsBaseUpgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IFairxyzEditions).interfaceId ||
            interfaceId == type(IERC2981Upgradeable).interfaceId ||
            FairxyzEditionsBaseUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IAccessControlUpgradeable-_checkRole}.
     * @dev Overriden to supersede any access control roles with contract ownership.
     */
    function _checkRole(bytes32 role) internal view virtual override {
        if (_msgSender() != owner()) _checkRole(role, _msgSender());
    }

    // * PRIVATE * //

    uint256[39] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/IERC1155MetadataURIUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
abstract contract Fairxyz1155Upgradeable is
    Initializable,
    ContextUpgradeable,
    ERC165Upgradeable,
    IERC1155Upgradeable,
    IERC1155MetadataURIUpgradeable
{
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function __Fairxyz1155_init() internal {
        __Fairxyz1155_init_unchained();
    }

    function __Fairxyz1155_init_unchained() internal {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(
        address account,
        uint256 id
    ) public view virtual override returns (uint256) {
        require(
            account != address(0),
            "ERC1155: address zero is not a valid owner"
        );
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(
            accounts.length == ids.length,
            "ERC1155: accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(
        address account,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(
            fromBalance >= amount,
            "ERC1155: insufficient balance for transfer"
        );
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(
            ids.length == amounts.length,
            "ERC1155: ids and amounts length mismatch"
        );
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(
                fromBalance >= amount,
                "ERC1155: insufficient balance for transfer"
            );
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual;

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155ReceiverUpgradeable.onERC1155Received.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(
        uint256 element
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    error InvalidRoyaltyFraction();

    struct Royalty {
        address receiver;
        uint96 royaltyFraction;
    }

    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     *
     * @param tokenId - the ID of the token being sold
     * @param salePrice - the sale price
     *
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount in the same unit of exchange as salePrice
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

interface IFairxyz1155Editions {
    /**
     * @notice Burn Tokens
     * @dev Burns an amount of a single edition/token, reducing the balance of `from`.
     *
     * @param from the address of the owner to burn tokens for
     * @param editionId the ID of the edition to burn
     * @param amount the number of tokens to burn
     */
    function burn(address from, uint256 editionId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

import {Stage} from "../interfaces/IFairxyzMintStagesRegistry.sol";

/**
 * @param maxMintsPerWallet the maximum number of tokens that can be minted per wallet/account
 * @param maxSupply the maximum supply for the edition including paid mints and airdrops
 * @param burnable_ the burnable state of the edition
 * @param signatureReleased whether the signature is required to mint tokens for the edition
 * @param soulbound whether the edition tokens are soulbound
 */
struct Edition {
    uint40 maxMintsPerWallet;
    uint40 maxSupply;
    bool burnable;
    bool signatureReleased;
    bool soulbound;
}

/**
 * @param externalId the external ID of the edition used to identify it off-chain
 * @param edition the edition struct
 * @param uri the URI for the edition/token metadata
 * @param mintStages the mint stages for the edition
 */
struct EditionCreateParams {
    uint256 externalId;
    Edition edition;
    string uri;
    Stage[] mintStages;
}

struct EditionMinter {
    uint40 mintedCount;
    uint40 lastUsedNonce;
}

interface IFairxyzEditions {
    error EditionAlreadyMinted();
    error EditionDoesNotExist();
    error EditionSignatureAlreadyReleased();
    error EditionSupplyCanOnlyBeReduced();
    error EditionSupplyLessThanMintedCount();
    error EditionSupplyLessThanScheduledStagesPhaseLimit();
    error EditionSupplyTooLarge();
    error IncorrectEthValue();
    error InvalidMintQuantity();
    error InvalidNumberOfRecipients();
    error InvalidSignatureNonce();
    error InvalidSignature();
    error InvalidURI();
    error NotApprovedOrOwner();
    error NotBurnable();
    error NotEnoughSupplyRemaining();
    error NotTransferable();
    error RecipientAllowanceUsed();
    error RecipientEditionAllowanceUsed();
    error RecipientStageAllowanceUsed();
    error SignatureAlreadyUsed();
    error SignatureExpired();
    error StageSoldOut();
    error TokenDoesNotExist();
    error ZeroAddress();

    /// @dev Emitted when the metadata of a range of tokens is changed.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    /// @dev Emitted when the default royalty details are changed.
    event DefaultRoyalty(address receiver, uint96 royaltyFraction);

    /// @dev Emitted when edition tokens are airdropped.
    event EditionAirdrop(
        uint256 indexed editionId,
        uint256 indexed stageIndex,
        address[] recipients,
        uint256 quantity,
        uint256 editionMintedCount
    );

    /// @dev Emitted when the burnable state of an edition is changed.
    event EditionBurnable(uint256 indexed editionId, bool burnable);

    /// @dev Emitted when a new edition is added.
    event EditionCreated(
        uint256 indexed editionId,
        uint256 externalId,
        Edition edition
    );

    /// @dev Emitted when an edition is deleted and can no longer be minted.
    event EditionDeleted(uint256 indexed editionId);

    /// @dev Emitted when the maximum mints per wallet for an edition is changed.
    event EditionMaxMintsPerWallet(
        uint256 indexed editionId,
        uint256 maxMintsPerWallet
    );

    /// @dev Emitted when the maximum supply for an edition is changed.
    event EditionMaxSupply(uint256 indexed editionId, uint256 maxSupply);

    /// @dev Emitted when the royalty details for an edition are changed.
    event EditionRoyalty(
        uint256 indexed editionId,
        address receiver,
        uint96 royaltyFraction
    );

    /// @dev Emitted when a signature is no longer required to mint tokens for a specific edition.
    event EditionSignatureReleased(uint256 indexed editionId);

    // /// @dev Emitted when the soulbound state of an edition is changed.
    // event EditionSoulbound(uint256 indexed editionId, bool soulbound);

    /// @dev Emitted when edition tokens are minted during a mint stage.
    event EditionStageMint(
        uint256 indexed editionId,
        uint256 indexed stageIndex,
        address indexed recipient,
        uint256 quantity,
        uint256 editionMintedCount
    );

    /// @dev Emitted when the metadata URI for an edition is changed.
    event EditionURI(uint256 indexed editionId, string uri);

    /// @dev Emitted when the metadata of a token is changed.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev Emitted when the primary sale receiver address is changed.
    event PrimarySaleReceiver(address primarySaleReceiver_);

    /**
     * @dev Mints the same quantity of tokens from an edition to multiple recipients.
     *
     * @param editionId the ID of the edition to mint
     * @param quantity the number of tokens to mint to each recipient
     * @param recipients addresses to mint to
     */
    function airdropEdition(
        uint256 editionId,
        uint256 quantity,
        address[] memory recipients
    ) external;

    /**
     * @dev Adds new editions at the next token ID/range (depending on standard implemented)
     *
     * @param editions the editions to add
     */
    function createEditions(EditionCreateParams[] calldata editions) external;

    /**
     * @dev Delete an edition i.e. make it no longer editable or mintable.
     *
     * @param editionId the ID of the edition to delete
     */
    function deleteEdition(uint256 editionId) external;

    /**
     * @dev Returns the current total supply of tokens for an edition, taking both mints and burns into account.
     *
     * @param editionId the ID of the edition
     *
     * @return totalSupply the number of tokens in circulation
     */
    function editionTotalSupply(
        uint256 editionId
    ) external view returns (uint256 totalSupply);

    /**
     * @dev Returns the edition with ID `editionId`.
     * @dev Should revert if the edition does not exist.
     *
     * @param editionId the ID of the edition
     *
     * @return edition
     */
    function getEdition(
        uint256 editionId
    ) external view returns (Edition memory);

    /**
     * @dev Grants the `DEFAULT_ADMIN_ROLE` role to an address.
     * @dev Intended to be used only by the contract owner. Other admin management is done via AccessControl contract functions.
     *
     * @param admin the address to grant the default admin role to
     */
    function grantDefaultAdmin(address admin) external;

    /**
     * @dev Mint a quantity of tokens for an edition to a single recipient.
     * @dev Can be called by any account with a valid signature and the correct value.
     *
     * @param editionId the ID of the edition
     * @param recipient the address to transfer the minted tokens to
     * @param quantity the quantity of tokens to mint
     * @param signatureNonce a value that is recorded for signature expiry and reuse prevention, typically a recent block number
     * @param signatureMaxMints the maximum number of mints specific to the recipient and validated in the signature
     * @param signature a signature containing the other function params for authorizing the execution
     */
    function mintEdition(
        uint256 editionId,
        address recipient,
        uint256 quantity,
        uint40 signatureNonce,
        uint256 signatureMaxMints,
        bytes memory signature
    ) external payable;

    /**
     * @dev Turns off signature validation for calls to `mintEdition` for a specific edition i.e. allows signature-less minting.
     *
     * @param editionId the ID of the edition
     */
    function releaseEditionSignature(uint256 editionId) external;

    /**
     * @dev Set the default royalty receiver and fraction for the collection.
     *
     * @param receiver the address to receive royalties
     * @param royaltyFraction the fraction of the sale price to pay as royalties (out of 10000)
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 royaltyFraction
    ) external;

    /**
     * @dev Changes the burnable state for a specific edition.
     *
     * @param editionId the ID of the edition
     * @param burnable the burnable value to set
     */
    function setEditionBurnable(uint256 editionId, bool burnable) external;

    /**
     * @dev Updates the maximum number of tokens each wallet can mint for an edition.
     *
     * @param editionId the ID of the edition to update
     * @param maxMintsPerWallet the new maximum number of mints
     */
    function setEditionMaxMintsPerWallet(
        uint256 editionId,
        uint40 maxMintsPerWallet
    ) external;

    /**
     * @dev Updates the maximum supply available for an edition.
     *
     * @param editionId the ID of the edition to update
     * @param maxSupply the new maximum supply of tokens for the edition
     */
    function setEditionMaxSupply(uint256 editionId, uint40 maxSupply) external;

    /**
     * @notice Set Edition Royalty
     * @dev updates the edition royalty receiver and fraction, which overrides the collection default
     *
     * @param editionId the ID of the edition to update
     * @param receiver the address that should receive royalty payments
     * @param royaltyFraction the portion of the defined denominator that the receiver should be sent from a secondary sale
     */
    function setEditionRoyalty(
        uint256 editionId,
        address receiver,
        uint96 royaltyFraction
    ) external;

    /**
     * @notice Update Edition Mint Stages
     * @dev Add and update a range of mint stages for an edition.
     *
     * @param editionId the ID of the edition
     * @param firstStageIndex the index of the first stage being det
     * @param newStages the new stage data to set
     */
    function setEditionStages(
        uint256 editionId,
        uint256 firstStageIndex,
        Stage[] calldata newStages
    ) external;

    /**
     * @notice Set Edition Metadata URI
     * @dev updates the edition metadata URI
     *
     * @param editionId the ID of the edition to update
     * @param uri the URI of the metadata for the edition
     */
    function setEditionURI(uint256 editionId, string calldata uri) external;

    /**
     * @dev Updates the address that the contract balance is withdrawn to.
     *
     * @param primarySaleReceiver_ the address that should receive funds when withdraw is called
     */
    function setPrimarySaleReceiver(address primarySaleReceiver_) external;

    /**
     * @dev returns the current total supply of tokens for the collection, taking both mints and burns into account.
     *
     * @return supply the number of tokens in circulation
     */
    function totalSupply() external view returns (uint256 supply);

    /**
     * @dev See {PausableUpgradeable-_pause}.
     */
    function pause() external;

    /**
     * @dev See {PausableUpgradeable-_unpause}.
     */
    function unpause() external;

    /**
     * @dev Sends the contract balance to the primary sale receiver address stored in the contract.
     */
    function withdraw() external;
}

// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

struct Stage {
    uint40 startTime;
    uint40 endTime;
    uint40 mintsPerWallet;
    uint40 phaseLimit;
    uint96 price;
}

interface IFairxyzMintStagesRegistry {
    error NoActiveStage();
    error NoStages();
    error NoStagesSpecified();
    error PhaseLimitsOverlap();
    error SkippedStages();
    error StageDoesNotExist();
    error StageHasEnded();
    error StageHasAlreadyStarted();
    error StageLimitAboveMax();
    error StageLimitBelowMin();
    error StageTimesOverlap();
    error TooManyUpcomingStages();
    error Unauthorized();

    /// @dev Emitted when a range of stages for a schedule are updated.
    event ScheduleStagesUpdated(
        address indexed registrant,
        uint256 indexed scheduleId,
        uint256 startIndex,
        Stage[] stages
    );

    /// @dev Emitted when a range of stages for a schedule are cancelled.
    event ScheduleStagesCancelled(
        address indexed registrant,
        uint256 indexed scheduleId,
        uint256 startIndex
    );

    /**
     * @dev Cancels all stages from the specified index onwards.
     *
     * Requirements:
     * - `fromIndex` must be less than the total number of stages
     *
     * @param registrant the address of the registrant the schedule is managed by
     * @param scheduleId the id of the schedule to cancel the stages for
     * @param fromIndex the index from which to cancel stages
     */
    function cancelStages(
        address registrant,
        uint256 scheduleId,
        uint256 fromIndex
    ) external;

    /**
     * @dev Sets a new series of stages, overwriting any existing stages and cancelling any stages after the last new stage.
     *
     * @param registrant the address of the registrant the schedule is managed by
     * @param scheduleId the id of the schedule to update the stages for
     * @param firstStageIndex the index from which to update stages
     * @param stages array of new stages to add to / overwrite existing stages
     * @param minPhaseLimit the minimum phaseLimit for the new stages e.g. current supply of the token the schedule is for
     * @param maxPhaseLimit the maximum phaseLimit for the new stages e.g. maximum supply of the token the schedule is for
     */
    function setStages(
        address registrant,
        uint256 scheduleId,
        uint256 firstStageIndex,
        Stage[] calldata stages,
        uint256 minPhaseLimit,
        uint256 maxPhaseLimit
    ) external;

    /**
     * @dev Finds the active stage for a schedule based on the current time being between the start and end times.
     * @dev Reverts if no active stage is found.
     *
     * @param scheduleId The id of the schedule to find the active stage for
     *
     * @return index The index of the active stage
     * @return stage The active stage data
     */
    function viewActiveStage(
        address registrant,
        uint256 scheduleId
    ) external view returns (uint256 index, Stage memory stage);

    /**
     * @dev Finds the final stage for a schedule.
     * @dev Does not revert. Instead, it returns an empty Stage if no stages exist for the schedule.
     *
     * @param scheduleId The id of the schedule to find the final stage for
     *
     * @return index The index of the final stage
     * @return stage The final stage data
     */
    function viewFinalStage(
        address registrant,
        uint256 scheduleId
    ) external view returns (uint256 index, Stage memory stage);

    /**
     * @dev Finds the index of the current/upcoming stage which has not yet ended.
     * @dev A stage may not exist at the returned index if all existing stages have ended.
     *
     * @param scheduleId The id of the schedule to find the latest stage index for
     *
     * @return index
     */
    function viewLatestStageIndex(
        address registrant,
        uint256 scheduleId
    ) external view returns (uint256 index);

    /**
     * @dev Returns the stage data for the specified schedule id and stage index.
     * @dev Reverts if a stage does not exist or has been deleted at the index.
     *
     * @param scheduleId The id of the schedule to get the stage from
     * @param stageIndex The index of the stage to get
     *
     * @return stage
     */
    function viewStage(
        address registrant,
        uint256 scheduleId,
        uint256 stageIndex
    ) external view returns (Stage memory stage);
}

// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

interface IFairxyzOperatorFiltererUpgradeable {
    error OnlyAdmin();

    /// @dev Emitted when the operator filter is disabled/enabled.
    event OperatorFilterDisabled(bool disabled);

    /**
     * @notice Enable/Disable Operator Filter
     * @dev Used to turn the operator filter on/off without updating the registry.
     */
    function toggleOperatorFilterDisabled() external;
}

// SPDX-License-Identifier: MIT

// @author: Fair.xyz dev

pragma solidity 0.8.19;

import {IOperatorFilterRegistry} from "operator-filter-registry/src/OperatorFilterRegistry.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IFairxyzOperatorFiltererUpgradeable.sol";

abstract contract FairxyzOperatorFiltererUpgradeable is
    Initializable,
    IFairxyzOperatorFiltererUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable REGISTRY_ADDRESS;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable DEFAULT_SUBSCRIPTION_ADDRESS;

    bool public operatorFilterDisabled;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address registry_, address defaultSubscription_) {
        REGISTRY_ADDRESS = registry_;
        DEFAULT_SUBSCRIPTION_ADDRESS = defaultSubscription_;
    }

    function __FairxyzOperatorFilterer_init(
        bool enabled
    ) internal onlyInitializing {
        __FairxyzOperatorFilterer_init_unchained(enabled);
    }

    function __FairxyzOperatorFilterer_init_unchained(
        bool enabled
    ) internal onlyInitializing {
        if (
            enabled &&
            REGISTRY_ADDRESS.code.length > 0 &&
            DEFAULT_SUBSCRIPTION_ADDRESS != address(0)
        ) {
            IOperatorFilterRegistry(REGISTRY_ADDRESS).registerAndSubscribe(
                address(this),
                DEFAULT_SUBSCRIPTION_ADDRESS
            );
        } else {
            operatorFilterDisabled = true;
        }
    }

    // * MODIFIERS * //

    /**
     * @dev Used to modify transfer functions to check the msg.sender is an allowed operator.
     * @dev Checks are bypassed if the filter is disabled or msg.sender owns the tokens.
     *
     * @param operator the address of the operator that transfer is being attempted by
     * @param from the address tokens are being transferred from
     */
    modifier onlyAllowedOperator(address operator, address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (REGISTRY_ADDRESS.code.length > 0 && !operatorFilterDisabled) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (operator != from) {
                // The OperatorFilterRegistry is responsible for checking if the operator is allowed
                // Reverts with AddressFiltered() if not.
                IOperatorFilterRegistry(REGISTRY_ADDRESS).isOperatorAllowed(
                    address(this),
                    operator
                );
            }
        }
        _;
    }

    /**
     * @dev Used to modify approval functions to check the operator is an allowed operator.
     * @dev Checks are bypassed if the filter is disabled.
     *
     * @param operator the address of the operator that approval is being attempted for
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (REGISTRY_ADDRESS.code.length > 0 && !operatorFilterDisabled) {
            // The OperatorFilterRegistry is responsible for checking if the operator is allowed
            // Reverts with AddressFiltered() if not.
            IOperatorFilterRegistry(REGISTRY_ADDRESS).isOperatorAllowed(
                address(this),
                operator
            );
        }
        _;
    }

    modifier onlyOperatorFilterAdmin() {
        if (!_isOperatorFilterAdmin(msg.sender)) {
            revert OnlyAdmin();
        }
        _;
    }

    // * ADMIN * //

    /**
     * @dev See {IFairxyzOperatorFiltererUpgradeable-toggleOperatorFilterDisabled}.
     */
    function toggleOperatorFilterDisabled()
        external
        virtual
        override
        onlyOperatorFilterAdmin
    {
        bool disabled = !operatorFilterDisabled;
        operatorFilterDisabled = disabled;
        emit OperatorFilterDisabled(disabled);
    }

    // * INTERNAL * //

    /**
     * @dev Inheriting contract is responsible for implementation
     */
    function _isOperatorFilterAdmin(
        address operator
    ) internal view virtual returns (bool);

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {OperatorFilterRegistryErrorsAndEvents} from "./OperatorFilterRegistryErrorsAndEvents.sol";

/**
 * @title  OperatorFilterRegistry
 * @notice Borrows heavily from the QQL BlacklistOperatorFilter contract:
 *         https://github.com/qql-art/contracts/blob/main/contracts/BlacklistOperatorFilter.sol
 * @notice This contracts allows tokens or token owners to register specific addresses or codeHashes that may be
 * *       restricted according to the isOperatorAllowed function.
 */
contract OperatorFilterRegistry is IOperatorFilterRegistry, OperatorFilterRegistryErrorsAndEvents {
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    /// @dev initialized accounts have a nonzero codehash (see https://eips.ethereum.org/EIPS/eip-1052)
    /// Note that this will also be a smart contract's codehash when making calls from its constructor.
    bytes32 constant EOA_CODEHASH = keccak256("");

    mapping(address => EnumerableSet.AddressSet) private _filteredOperators;
    mapping(address => EnumerableSet.Bytes32Set) private _filteredCodeHashes;
    mapping(address => address) private _registrations;
    mapping(address => EnumerableSet.AddressSet) private _subscribers;

    /**
     * @notice Restricts method caller to the address or EIP-173 "owner()"
     */
    modifier onlyAddressOrOwner(address addr) {
        if (msg.sender != addr) {
            try Ownable(addr).owner() returns (address owner) {
                if (msg.sender != owner) {
                    revert OnlyAddressOrOwner();
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert NotOwnable();
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
        _;
    }

    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     *         Note that this method will *revert* if an operator or its codehash is filtered with an error that is
     *         more informational than a false boolean, so smart contracts that query this method for informational
     *         purposes will need to wrap in a try/catch or perform a low-level staticcall in order to handle the case
     *         that an operator is filtered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool) {
        address registration = _registrations[registrant];
        if (registration != address(0)) {
            EnumerableSet.AddressSet storage filteredOperatorsRef;
            EnumerableSet.Bytes32Set storage filteredCodeHashesRef;

            filteredOperatorsRef = _filteredOperators[registration];
            filteredCodeHashesRef = _filteredCodeHashes[registration];

            if (filteredOperatorsRef.contains(operator)) {
                revert AddressFiltered(operator);
            }
            if (operator.code.length > 0) {
                bytes32 codeHash = operator.codehash;
                if (filteredCodeHashesRef.contains(codeHash)) {
                    revert CodeHashFiltered(operator, codeHash);
                }
            }
        }
        return true;
    }

    //////////////////
    // AUTH METHODS //
    //////////////////

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external onlyAddressOrOwner(registrant) {
        if (_registrations[registrant] != address(0)) {
            revert AlreadyRegistered();
        }
        _registrations[registrant] = registrant;
        emit RegistrationUpdated(registrant, true);
    }

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address registrant) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            _subscribers[registration].remove(registrant);
            emit SubscriptionUpdated(registrant, registration, false);
        }
        _registrations[registrant] = address(0);
        emit RegistrationUpdated(registrant, false);
    }

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration != address(0)) {
            revert AlreadyRegistered();
        }
        if (registrant == subscription) {
            revert CannotSubscribeToSelf();
        }
        address subscriptionRegistration = _registrations[subscription];
        if (subscriptionRegistration == address(0)) {
            revert NotRegistered(subscription);
        }
        if (subscriptionRegistration != subscription) {
            revert CannotSubscribeToRegistrantWithSubscription(subscription);
        }

        _registrations[registrant] = subscription;
        _subscribers[subscription].add(registrant);
        emit RegistrationUpdated(registrant, true);
        emit SubscriptionUpdated(registrant, subscription, true);
    }

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy)
        external
        onlyAddressOrOwner(registrant)
    {
        if (registrantToCopy == registrant) {
            revert CannotCopyFromSelf();
        }
        address registration = _registrations[registrant];
        if (registration != address(0)) {
            revert AlreadyRegistered();
        }
        address registrantRegistration = _registrations[registrantToCopy];
        if (registrantRegistration == address(0)) {
            revert NotRegistered(registrantToCopy);
        }
        _registrations[registrant] = registrant;
        emit RegistrationUpdated(registrant, true);
        _copyEntries(registrant, registrantToCopy);
    }

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered)
        external
        onlyAddressOrOwner(registrant)
    {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.AddressSet storage filteredOperatorsRef = _filteredOperators[registrant];

        if (!filtered) {
            bool removed = filteredOperatorsRef.remove(operator);
            if (!removed) {
                revert AddressNotFiltered(operator);
            }
        } else {
            bool added = filteredOperatorsRef.add(operator);
            if (!added) {
                revert AddressAlreadyFiltered(operator);
            }
        }
        emit OperatorUpdated(registrant, operator, filtered);
    }

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     *         Note that this will allow adding the bytes32(0) codehash, which could result in unexpected behavior,
     *         since calling `isCodeHashFiltered` will return true for bytes32(0), which is the codeHash of any
     *         un-initialized account. Since un-initialized accounts have no code, the registry will not validate
     *         that an un-initalized account's codeHash is not filtered. By the time an account is able to
     *         act as an operator (an account is initialized or a smart contract exclusively in the context of its
     *         constructor),  it will have a codeHash of EOA_CODEHASH, which cannot be filtered.
     */
    function updateCodeHash(address registrant, bytes32 codeHash, bool filtered)
        external
        onlyAddressOrOwner(registrant)
    {
        if (codeHash == EOA_CODEHASH) {
            revert CannotFilterEOAs();
        }
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.Bytes32Set storage filteredCodeHashesRef = _filteredCodeHashes[registrant];

        if (!filtered) {
            bool removed = filteredCodeHashesRef.remove(codeHash);
            if (!removed) {
                revert CodeHashNotFiltered(codeHash);
            }
        } else {
            bool added = filteredCodeHashesRef.add(codeHash);
            if (!added) {
                revert CodeHashAlreadyFiltered(codeHash);
            }
        }
        emit CodeHashUpdated(registrant, codeHash, filtered);
    }

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered)
        external
        onlyAddressOrOwner(registrant)
    {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.AddressSet storage filteredOperatorsRef = _filteredOperators[registrant];
        uint256 operatorsLength = operators.length;
        if (!filtered) {
            for (uint256 i = 0; i < operatorsLength;) {
                address operator = operators[i];
                bool removed = filteredOperatorsRef.remove(operator);
                if (!removed) {
                    revert AddressNotFiltered(operator);
                }
                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i = 0; i < operatorsLength;) {
                address operator = operators[i];
                bool added = filteredOperatorsRef.add(operator);
                if (!added) {
                    revert AddressAlreadyFiltered(operator);
                }
                unchecked {
                    ++i;
                }
            }
        }
        emit OperatorsUpdated(registrant, operators, filtered);
    }

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     *         Note that this will allow adding the bytes32(0) codehash, which could result in unexpected behavior,
     *         since calling `isCodeHashFiltered` will return true for bytes32(0), which is the codeHash of any
     *         un-initialized account. Since un-initialized accounts have no code, the registry will not validate
     *         that an un-initalized account's codeHash is not filtered. By the time an account is able to
     *         act as an operator (an account is initialized or a smart contract exclusively in the context of its
     *         constructor),  it will have a codeHash of EOA_CODEHASH, which cannot be filtered.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered)
        external
        onlyAddressOrOwner(registrant)
    {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        EnumerableSet.Bytes32Set storage filteredCodeHashesRef = _filteredCodeHashes[registrant];
        uint256 codeHashesLength = codeHashes.length;
        if (!filtered) {
            for (uint256 i = 0; i < codeHashesLength;) {
                bytes32 codeHash = codeHashes[i];
                bool removed = filteredCodeHashesRef.remove(codeHash);
                if (!removed) {
                    revert CodeHashNotFiltered(codeHash);
                }
                unchecked {
                    ++i;
                }
            }
        } else {
            for (uint256 i = 0; i < codeHashesLength;) {
                bytes32 codeHash = codeHashes[i];
                if (codeHash == EOA_CODEHASH) {
                    revert CannotFilterEOAs();
                }
                bool added = filteredCodeHashesRef.add(codeHash);
                if (!added) {
                    revert CodeHashAlreadyFiltered(codeHash);
                }
                unchecked {
                    ++i;
                }
            }
        }
        emit CodeHashesUpdated(registrant, codeHashes, filtered);
    }

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address newSubscription) external onlyAddressOrOwner(registrant) {
        if (registrant == newSubscription) {
            revert CannotSubscribeToSelf();
        }
        if (newSubscription == address(0)) {
            revert CannotSubscribeToZeroAddress();
        }
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration == newSubscription) {
            revert AlreadySubscribed(newSubscription);
        }
        address newSubscriptionRegistration = _registrations[newSubscription];
        if (newSubscriptionRegistration == address(0)) {
            revert NotRegistered(newSubscription);
        }
        if (newSubscriptionRegistration != newSubscription) {
            revert CannotSubscribeToRegistrantWithSubscription(newSubscription);
        }

        if (registration != registrant) {
            _subscribers[registration].remove(registrant);
            emit SubscriptionUpdated(registrant, registration, false);
        }
        _registrations[registrant] = newSubscription;
        _subscribers[newSubscription].add(registrant);
        emit SubscriptionUpdated(registrant, newSubscription, true);
    }

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external onlyAddressOrOwner(registrant) {
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration == registrant) {
            revert NotSubscribed();
        }
        _subscribers[registration].remove(registrant);
        _registrations[registrant] = registrant;
        emit SubscriptionUpdated(registrant, registration, false);
        if (copyExistingEntries) {
            _copyEntries(registrant, registration);
        }
    }

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external onlyAddressOrOwner(registrant) {
        if (registrant == registrantToCopy) {
            revert CannotCopyFromSelf();
        }
        address registration = _registrations[registrant];
        if (registration == address(0)) {
            revert NotRegistered(registrant);
        }
        if (registration != registrant) {
            revert CannotUpdateWhileSubscribed(registration);
        }
        address registrantRegistration = _registrations[registrantToCopy];
        if (registrantRegistration == address(0)) {
            revert NotRegistered(registrantToCopy);
        }
        _copyEntries(registrant, registrantToCopy);
    }

    /// @dev helper to copy entries from registrantToCopy to registrant and emit events
    function _copyEntries(address registrant, address registrantToCopy) private {
        EnumerableSet.AddressSet storage filteredOperatorsRef = _filteredOperators[registrantToCopy];
        EnumerableSet.Bytes32Set storage filteredCodeHashesRef = _filteredCodeHashes[registrantToCopy];
        uint256 filteredOperatorsLength = filteredOperatorsRef.length();
        uint256 filteredCodeHashesLength = filteredCodeHashesRef.length();
        for (uint256 i = 0; i < filteredOperatorsLength;) {
            address operator = filteredOperatorsRef.at(i);
            bool added = _filteredOperators[registrant].add(operator);
            if (added) {
                emit OperatorUpdated(registrant, operator, true);
            }
            unchecked {
                ++i;
            }
        }
        for (uint256 i = 0; i < filteredCodeHashesLength;) {
            bytes32 codehash = filteredCodeHashesRef.at(i);
            bool added = _filteredCodeHashes[registrant].add(codehash);
            if (added) {
                emit CodeHashUpdated(registrant, codehash, true);
            }
            unchecked {
                ++i;
            }
        }
    }

    //////////////////
    // VIEW METHODS //
    //////////////////

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address registrant) external view returns (address subscription) {
        subscription = _registrations[registrant];
        if (subscription == address(0)) {
            revert NotRegistered(registrant);
        } else if (subscription == registrant) {
            subscription = address(0);
        }
    }

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external view returns (address[] memory) {
        return _subscribers[registrant].values();
    }

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external view returns (address) {
        return _subscribers[registrant].at(index);
    }

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external view returns (bool) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredOperators[registration].contains(operator);
        }
        return _filteredOperators[registrant].contains(operator);
    }

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external view returns (bool) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].contains(codeHash);
        }
        return _filteredCodeHashes[registrant].contains(codeHash);
    }

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external view returns (bool) {
        bytes32 codeHash = operatorWithCode.codehash;
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].contains(codeHash);
        }
        return _filteredCodeHashes[registrant].contains(codeHash);
    }

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address registrant) external view returns (bool) {
        return _registrations[registrant] != address(0);
    }

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address registrant) external view returns (address[] memory) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredOperators[registration].values();
        }
        return _filteredOperators[registrant].values();
    }

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address registrant) external view returns (bytes32[] memory) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].values();
        }
        return _filteredCodeHashes[registrant].values();
    }

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external view returns (address) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredOperators[registration].at(index);
        }
        return _filteredOperators[registrant].at(index);
    }

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external view returns (bytes32) {
        address registration = _registrations[registrant];
        if (registration != registrant) {
            return _filteredCodeHashes[registration].at(index);
        }
        return _filteredCodeHashes[registrant].at(index);
    }

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address a) external view returns (bytes32) {
        return a.codehash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract OperatorFilterRegistryErrorsAndEvents {
    /// @notice Emitted when trying to register an address that has no code.
    error CannotFilterEOAs();

    /// @notice Emitted when trying to add an address that is already filtered.
    error AddressAlreadyFiltered(address operator);

    /// @notice Emitted when trying to remove an address that is not filtered.
    error AddressNotFiltered(address operator);

    /// @notice Emitted when trying to add a codehash that is already filtered.
    error CodeHashAlreadyFiltered(bytes32 codeHash);

    /// @notice Emitted when trying to remove a codehash that is not filtered.
    error CodeHashNotFiltered(bytes32 codeHash);

    /// @notice Emitted when the caller is not the address or EIP-173 "owner()"
    error OnlyAddressOrOwner();

    /// @notice Emitted when the registrant is not registered.
    error NotRegistered(address registrant);

    /// @notice Emitted when the registrant is already registered.
    error AlreadyRegistered();

    /// @notice Emitted when the registrant is already subscribed.
    error AlreadySubscribed(address subscription);

    /// @notice Emitted when the registrant is not subscribed.
    error NotSubscribed();

    /// @notice Emitted when trying to update a registration where the registrant is already subscribed.
    error CannotUpdateWhileSubscribed(address subscription);

    /// @notice Emitted when trying to subscribe to itself.
    error CannotSubscribeToSelf();

    /// @notice Emitted when trying to subscribe to the zero address.
    error CannotSubscribeToZeroAddress();

    /// @notice Emitted when trying to register and the contract is not ownable (EIP-173 "owner()")
    error NotOwnable();

    /// @notice Emitted when an address is filtered.
    error AddressFiltered(address filtered);

    /// @notice Emitted when a codeHash is filtered.
    error CodeHashFiltered(address account, bytes32 codeHash);

    /// @notice Emited when trying to register to a registrant with a subscription.
    error CannotSubscribeToRegistrantWithSubscription(address registrant);

    /// @notice Emitted when trying to copy a registration from itself.
    error CannotCopyFromSelf();

    /// @notice Emitted when a registration is updated.
    event RegistrationUpdated(address indexed registrant, bool indexed registered);

    /// @notice Emitted when an operator is updated.
    event OperatorUpdated(address indexed registrant, address indexed operator, bool indexed filtered);

    /// @notice Emitted when multiple operators are updated.
    event OperatorsUpdated(address indexed registrant, address[] operators, bool indexed filtered);

    /// @notice Emitted when a codeHash is updated.
    event CodeHashUpdated(address indexed registrant, bytes32 indexed codeHash, bool indexed filtered);

    /// @notice Emitted when multiple codeHashes are updated.
    event CodeHashesUpdated(address indexed registrant, bytes32[] codeHashes, bool indexed filtered);

    /// @notice Emitted when a subscription is updated.
    event SubscriptionUpdated(address indexed registrant, address indexed subscription, bool indexed subscribed);
}