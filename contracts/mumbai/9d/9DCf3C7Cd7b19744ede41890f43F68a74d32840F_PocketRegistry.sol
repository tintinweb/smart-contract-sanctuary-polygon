// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
pragma solidity 0.8.19;

import "./Types.sol";

library Params {
	/**
	 * @dev Define pocket item
	 */
	struct CreatePocketParams {
		/**
		 * @dev Each pocket would have a unique id
		 */
		string id;
		address owner;
		/**
		 * @dev AMM configurations
		 */
		address ammRouterAddress;
		address baseTokenAddress;
		address targetTokenAddress;
		/**
		 * @dev Pocket trade config
		 **/
		uint256 startAt;
		uint256 batchVolume;
		Types.StopCondition[] stopConditions;
		uint256 frequency;
		/**
		 * @dev Pocket opening position config
		 */
		Types.ValueComparison openingPositionCondition;
		/**
		 * @dev Pocket closing position config
		 */
		Types.TradingStopCondition takeProfitCondition;
		Types.TradingStopCondition stopLossCondition;
	}

	/**
	 * @dev Define pocket item
	 */
	struct UpdatePocketParams {
		/**
		 * @dev Each pocket would have a unique id
		 */
		string id;
		/**
		 * @dev Pocket trade config
		 **/
		uint256 startAt;
		uint256 batchVolume;
		Types.StopCondition[] stopConditions;
		uint256 frequency;
		/**
		 * @dev Pocket opening position config
		 */
		Types.ValueComparison openingPositionCondition;
		/**
		 * @dev Pocket closing position config
		 */
		Types.TradingStopCondition takeProfitCondition;
		Types.TradingStopCondition stopLossCondition;
	}

	/// @dev Define params
	struct UpdatePocketClosingPositionStatsParams {
		string id;
		address actor;
		/**
		 * @dev Archived info is used for statistic
		 */
		uint256 swappedTargetTokenAmount;
		uint256 receivedBaseTokenAmount;
	}

	/// @dev Define params
	struct UpdatePocketTradingStatsParams {
		address actor;
		string id;
		/**
		 * @dev Archived info is used for statistic
		 */
		uint256 swappedBaseTokenAmount;
		uint256 receivedTargetTokenAmount;
	}

	/// @dev Depositing params
	struct UpdatePocketWithdrawalParams {
		address actor;
		string id;
	}

	/// @dev Define params
	struct UpdatePocketDepositParams {
		address actor;
		string id;
		uint256 amount;
		address tokenAddress;
	}

	/// @dev Define params
	struct UpdatePocketStatusParams {
		address actor;
		string id;
		Types.PocketStatus status;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./Types.sol";
import "./Params.sol";

/**
 * @notice HamsterPocket allows users to create and manage their own dollar-cost averaging pools
 * (“pockets”) that will automatically execute the chosen strategies over tim,
 **/
/// @custom:security-contact [email protected]
contract PocketRegistry is
	Initializable,
	PausableUpgradeable,
	ReentrancyGuardUpgradeable,
	AccessControlUpgradeable,
	OwnableUpgradeable
{
	using SafeMathUpgradeable for uint256;

	/// @notice Operator that is allowed to run swap
	bytes32 public constant OPERATOR = keccak256("OPERATOR");

	/// @notice Relayer that is specific to internal components such as router or vault
	bytes32 public constant RELAYER = keccak256("RELAYER");

	/// @notice We use precision as 1 million for the more accurate percentage
	uint256 public constant PERCENTAGE_PRECISION = 1000000;

	/// @notice Store pocket configuration
	mapping(address => bool) public allowedInteractiveAddresses;

	/// @notice Store user pocket data
	mapping(string => Types.Pocket) public pockets;

	/// @notice Utility check
	mapping(string => bool) public blacklistedIdMap;

	/// @notice Event emitted when whitelisting/blacklisting address
	event AddressWhitelisted(
		address indexed actor,
		address indexed mintAddress,
		bool value
	);

	/// @notice Event emitted when initializing user pocket
	event PocketInitialized(
		address indexed actor,
		string indexed pocketId,
		address indexed owner,
		Types.Pocket pocketData
	);

	/// @notice Event emitted when initializing user pocket
	event PocketUpdated(
		address indexed actor,
		string indexed pocketId,
		address indexed owner,
		string reason,
		Types.Pocket pocketData
	);

	/// @notice Check if id is unique
	/// @dev should be used as a modifier
	modifier idMustBeAvailable(string calldata id) {
		require(blacklistedIdMap[id] == false, "ID: the id is not unique");
		blacklistedIdMap[id] = true;

		_;
	}

	/// @notice Check if id is unique
	/// @dev should be used as a modifier
	modifier mustBeValidPocket(string calldata id) {
		require(blacklistedIdMap[id] == true, "ID: the id must be existed");
		require(pockets[id].owner != address(0), "Pocket: invalid pocket");

		_;
	}

	/// @notice Check if the target is the owner of a given pocket id
	/// @dev should be used as a modifier
	modifier mustBeOwnerOf(string calldata pocketId, address target) {
		require(
			isOwnerOf(pocketId, target),
			"Permission: not permitted operation"
		);

		_;
	}

	/// @notice Check whether an address is the pocket owner
	function isOwnerOf(string calldata pocketId, address target)
		public
		view
		returns (bool)
	{
		return pockets[pocketId].owner == target;
	}

	/// @notice Check whether an address is the pocket owner
	function getStopConditionsOf(string calldata pocketId)
		public
		view
		returns (Types.StopCondition[] memory)
	{
		return pockets[pocketId].stopConditions;
	}

	/// @notice Check whether a pocket meet stop condition. The pocket should be settled before checking this condition.
	function shouldClosePocket(string calldata pocketId)
		public
		view
		returns (bool)
	{
		Types.Pocket storage pocket = pockets[pocketId];
		Types.StopCondition[] storage stopConditions = pockets[pocketId]
			.stopConditions;

		/// @dev Save some gas
		if (stopConditions.length == 0) return false;

		for (uint256 index = 0; index < stopConditions.length; index++) {
			Types.StopCondition storage condition = stopConditions[index];

			/// @dev Check for condition here
			if (
				condition.operator == Types.StopConditionOperator.EndTimeReach
			) {
				return condition.value <= block.timestamp;
			}

			if (
				condition.operator ==
				Types.StopConditionOperator.BatchAmountReach
			) {
				return pocket.executedBatchAmount >= condition.value;
			}

			if (
				condition.operator ==
				Types.StopConditionOperator.SpentBaseTokenAmountReach
			) {
				return pocket.totalSwappedBaseAmount >= condition.value;
			}

			if (
				condition.operator ==
				Types.StopConditionOperator.ReceivedTargetTokenAmountReach
			) {
				return pocket.totalReceivedTargetAmount >= condition.value;
			}
		}

		return false;
	}

	/// @notice Check whether a pocket meet buy condition. The pocket should not be settled until this condition is verified.
	function shouldOpenPosition(
		string calldata pocketId,
		uint256 swappedBaseTokenAmount,
		uint256 receivedTargetTokenAmount
	) public view returns (bool) {
		Types.Pocket storage pocket = pockets[pocketId];
		Types.ValueComparison storage condition = pockets[pocketId]
			.openingPositionCondition;

		if (condition.operator == Types.ValueComparisonOperator.Unset) {
			return true;
		}

		/// @dev Calculate price
		uint256 expectedAmountOut = receivedTargetTokenAmount
			.mul(pocket.batchVolume)
			.div(swappedBaseTokenAmount);

		if (condition.operator == Types.ValueComparisonOperator.Lt) {
			return expectedAmountOut < condition.value0;
		}

		if (condition.operator == Types.ValueComparisonOperator.Lte) {
			return expectedAmountOut <= condition.value0;
		}

		if (condition.operator == Types.ValueComparisonOperator.Gt) {
			return expectedAmountOut > condition.value0;
		}

		if (condition.operator == Types.ValueComparisonOperator.Gte) {
			return expectedAmountOut >= condition.value0;
		}

		if (condition.operator == Types.ValueComparisonOperator.Bw) {
			return
				expectedAmountOut >= condition.value0 &&
				expectedAmountOut <= condition.value1;
		}

		if (condition.operator == Types.ValueComparisonOperator.NBw) {
			return
				expectedAmountOut < condition.value0 ||
				expectedAmountOut > condition.value1;
		}

		/// @dev Default will be true
		return true;
	}

	/// @notice Check whether a pocket meet buy condition. The pocket should not be settled until this condition is verified.
	function shouldTakeProfit(
		string calldata pocketId,
		uint256 swappedTargetTokenAmount,
		uint256 receivedBaseTokenAmount
	) public view returns (bool) {
		Types.Pocket storage pocket = pockets[pocketId];
		Types.TradingStopCondition storage condition = pockets[pocketId]
			.takeProfitCondition;

		/// @dev Save some gas by early returns
		if (condition.stopType == Types.TradingStopConditionType.Unset) {
			return false;
		}

		/// @dev If pocket stop condition is based on price, return true if expectedAmountOut is greater than or equal condition value
		if (condition.stopType == Types.TradingStopConditionType.Price) {
			/// @dev Calculate price
			uint256 targetTokenDecimal = ERC20(pocket.targetTokenAddress)
				.decimals();
			uint256 expectedAmountOut = receivedBaseTokenAmount
				.mul(10**targetTokenDecimal)
				.div(swappedTargetTokenAmount);

			return expectedAmountOut >= condition.value;
		}

		/// @dev pocket stop condition is based on portfolio value diff
		if (
			condition.stopType ==
			Types.TradingStopConditionType.PortfolioValueDiff
		) {
			return
				receivedBaseTokenAmount >=
				pocket.totalSwappedBaseAmount.add(condition.value);
		}

		/// @dev Pocket stop condition is based on portfolio percentage diff
		if (
			condition.stopType ==
			Types.TradingStopConditionType.PortfolioPercentageDiff
		) {
			/// @dev Return false if the portfolio is in a loss position
			if (receivedBaseTokenAmount <= pocket.totalSwappedBaseAmount) {
				return false;
			}

			/// @dev Compute the position profit
			return
				receivedBaseTokenAmount
					.sub(pocket.totalSwappedBaseAmount)
					.mul(PERCENTAGE_PRECISION)
					.div(pocket.totalSwappedBaseAmount) >= condition.value;
		}

		return false;
	}

	/// @notice Check whether a pocket meet buy condition. The pocket should not be settled until this condition is verified.
	function shouldStopLoss(
		string calldata pocketId,
		uint256 swappedTargetTokenAmount,
		uint256 receivedBaseTokenAmount
	) public view returns (bool) {
		Types.Pocket storage pocket = pockets[pocketId];
		Types.TradingStopCondition storage condition = pockets[pocketId]
			.stopLossCondition;

		/// @dev Save some gas by early returns
		if (condition.stopType == Types.TradingStopConditionType.Unset) {
			return false;
		}

		/// @dev If pocket stop condition is based on price, return true if expectedAmountOut is less than or equal condition value
		if (condition.stopType == Types.TradingStopConditionType.Price) {
			/// @dev Calculate price
			uint256 targetTokenDecimals = ERC20(pocket.targetTokenAddress)
				.decimals();
			uint256 expectedAmountOut = receivedBaseTokenAmount
				.mul(10**targetTokenDecimals)
				.div(swappedTargetTokenAmount);

			return expectedAmountOut <= condition.value;
		}

		/// @dev pocket stop condition is based on portfolio value diff
		if (
			condition.stopType ==
			Types.TradingStopConditionType.PortfolioValueDiff
		) {
			return
				receivedBaseTokenAmount <= pocket.totalSwappedBaseAmount &&
				pocket.totalSwappedBaseAmount.sub(receivedBaseTokenAmount) >=
				condition.value;
		}

		/// @dev Pocket stop condition is based on portfolio percentage diff
		if (
			condition.stopType ==
			Types.TradingStopConditionType.PortfolioPercentageDiff
		) {
			/// @dev Return false if the portfolio is not in a loss position
			if (receivedBaseTokenAmount > pocket.totalSwappedBaseAmount) {
				return false;
			}

			/// @dev Compute the position loss
			return
				pocket
					.totalSwappedBaseAmount
					.sub(receivedBaseTokenAmount)
					.mul(PERCENTAGE_PRECISION)
					.div(pocket.totalSwappedBaseAmount) >= condition.value;
		}

		return false;
	}

	/// @notice Get trading pair info of a given pocket id
	function getTradingInfoOf(string calldata pocketId)
		public
		view
		returns (
			address,
			address,
			address,
			uint256,
			uint256,
			uint256,
			uint256,
			Types.ValueComparison memory,
			Types.TradingStopCondition memory,
			Types.TradingStopCondition memory
		)
	{
		return (
			pockets[pocketId].ammRouterAddress,
			pockets[pocketId].baseTokenAddress,
			pockets[pocketId].targetTokenAddress,
			pockets[pocketId].startAt,
			pockets[pocketId].batchVolume,
			pockets[pocketId].frequency,
			pockets[pocketId].nextScheduledExecutionAt,
			pockets[pocketId].openingPositionCondition,
			pockets[pocketId].takeProfitCondition,
			pockets[pocketId].stopLossCondition
		);
	}

	/// @notice Get balance info of a given pocket
	function getBalanceInfoOf(string calldata pocketId)
		public
		view
		returns (uint256, uint256)
	{
		return (
			pockets[pocketId].baseTokenBalance,
			pockets[pocketId].targetTokenBalance
		);
	}

	/// @notice Get owner address of a given pocket
	function getOwnerOf(string calldata pocketId)
		public
		view
		returns (address)
	{
		return (pockets[pocketId].owner);
	}

	/// @notice Check whether a pocket is available for depositing
	function isAbleToDeposit(string calldata pocketId, address owner)
		external
		view
		returns (bool)
	{
		return (pockets[pocketId].owner == owner &&
			pockets[pocketId].status != Types.PocketStatus.Closed &&
			pockets[pocketId].status != Types.PocketStatus.Withdrawn);
	}

	/// @notice Check whether a pocket is available for depositing
	function isAbleToUpdate(string calldata pocketId, address owner)
		external
		view
		returns (bool)
	{
		return (pockets[pocketId].owner == owner &&
			pockets[pocketId].status != Types.PocketStatus.Closed &&
			pockets[pocketId].status != Types.PocketStatus.Withdrawn);
	}

	/// @notice Check whether a pocket is available to close
	function isAbleToClose(string calldata pocketId, address owner)
		external
		view
		returns (bool)
	{
		return (pockets[pocketId].owner == owner &&
			pockets[pocketId].status != Types.PocketStatus.Closed &&
			pockets[pocketId].status != Types.PocketStatus.Withdrawn);
	}

	/// @notice Check whether a pocket is available to withdraw
	function isAbleToWithdraw(string calldata pocketId, address owner)
		external
		view
		returns (bool)
	{
		return (pockets[pocketId].owner == owner &&
			pockets[pocketId].status == Types.PocketStatus.Closed);
	}

	/// @notice Check whether a pocket is available to restart
	function isAbleToRestart(string calldata pocketId, address owner)
		external
		view
		returns (bool)
	{
		return (pockets[pocketId].owner == owner &&
			pockets[pocketId].status == Types.PocketStatus.Paused);
	}

	/// @notice Check whether a pocket is available to pause
	function isAbleToPause(string calldata pocketId, address owner)
		external
		view
		returns (bool)
	{
		return (pockets[pocketId].owner == owner &&
			pockets[pocketId].status == Types.PocketStatus.Active);
	}

	/// @notice Check whether a pocket is ready to swap
	function isReadyToSwap(string calldata pocketId)
		external
		view
		returns (bool)
	{
		return (pockets[pocketId].status == Types.PocketStatus.Active &&
			pockets[pocketId].startAt <= block.timestamp &&
			pockets[pocketId].nextScheduledExecutionAt <= block.timestamp);
	}

	/// @notice Check whether a pocket is ready to swap
	function isReadyToClosePosition(string calldata pocketId)
		external
		view
		returns (bool)
	{
		return (pockets[pocketId].status != Types.PocketStatus.Withdrawn &&
			pockets[pocketId].startAt <= block.timestamp &&
			pockets[pocketId].targetTokenBalance > 0);
	}

	/// @notice Users initialize their pocket
	function initializeUserPocket(Params.CreatePocketParams calldata params)
		external
		onlyRole(RELAYER)
		idMustBeAvailable(params.id)
	{
		/// @dev Validate input
		require(
			params.startAt >= block.timestamp,
			"Timestamp: must be equal or greater than block time"
		);
		require(
			params.batchVolume >= 0,
			"Batch volume: must be equal or greater than 0"
		);
		require(
			params.frequency >= 1 hours,
			"Frequency: must be equal or greater than 1 hour"
		);
		require(params.owner != address(0), "Address: invalid owner");
		require(
			params.ammRouterAddress != address(0),
			"Address: invalid ammRouterAddress"
		);
		require(
			allowedInteractiveAddresses[params.ammRouterAddress],
			"Address: ammRouterAddress is not whitelisted"
		);
		require(
			params.baseTokenAddress != address(0),
			"Address: invalid baseTokenAddress"
		);
		require(
			allowedInteractiveAddresses[params.baseTokenAddress],
			"Address: baseTokenAddress is not whitelisted"
		);
		require(
			params.targetTokenAddress != address(0),
			"Address: invalid targetTokenAddress"
		);
		require(
			allowedInteractiveAddresses[params.targetTokenAddress],
			"Address: targetTokenAddress is not whitelisted"
		);
		/// @dev Validate stop condition through loop
		for (uint256 index = 0; index < params.stopConditions.length; index++) {
			require(
				params.stopConditions[index].value > 0,
				"StopCondition: value must not be zero"
			);
		}
		/// @dev Validate value comparison struct
		if (
			params.openingPositionCondition.operator !=
			Types.ValueComparisonOperator.Unset
		) {
			if (
				params.openingPositionCondition.operator ==
				Types.ValueComparisonOperator.Bw ||
				params.openingPositionCondition.operator ==
				Types.ValueComparisonOperator.NBw
			) {
				require(
					params.openingPositionCondition.value0 > 0 &&
						params.openingPositionCondition.value1 >=
						params.openingPositionCondition.value0,
					"ValueComparison: invalid value"
				);
			} else {
				require(
					params.openingPositionCondition.value0 > 0,
					"ValueComparison: invalid value"
				);
			}
		}
		/// @dev Validate value comparison struct
		if (
			params.takeProfitCondition.stopType !=
			Types.TradingStopConditionType.Unset
		) {
			require(
				params.takeProfitCondition.value > 0,
				"ValueComparison: invalid value"
			);
		}
		/// @dev Validate value comparison struct
		if (
			params.stopLossCondition.stopType !=
			Types.TradingStopConditionType.Unset
		) {
			require(
				params.stopLossCondition.value > 0,
				"ValueComparison: invalid value"
			);
		}

		/// @dev Initialize user pocket data
		pockets[params.id] = Types.Pocket({
			id: params.id,
			owner: params.owner,
			ammRouterAddress: params.ammRouterAddress,
			baseTokenAddress: params.baseTokenAddress,
			targetTokenAddress: params.targetTokenAddress,
			startAt: params.startAt,
			batchVolume: params.batchVolume,
			frequency: params.frequency,
			stopConditions: params.stopConditions,
			openingPositionCondition: params.openingPositionCondition,
			takeProfitCondition: params.takeProfitCondition,
			stopLossCondition: params.stopLossCondition,
			/// @dev Those fields are updated during the relayers operation
			status: Types.PocketStatus.Active,
			totalDepositedBaseAmount: 0,
			totalReceivedTargetAmount: 0,
			totalSwappedBaseAmount: 0,
			totalClosedPositionInTargetTokenAmount: 0,
			totalReceivedFundInBaseTokenAmount: 0,
			baseTokenBalance: 0,
			targetTokenBalance: 0,
			executedBatchAmount: 0,
			nextScheduledExecutionAt: 0
		});

		/// @dev Emit event
		emit PocketInitialized(
			msg.sender,
			params.id,
			params.owner,
			pockets[params.id]
		);
	}

	/// @notice Users initialize their pocket
	function updatePocket(
		Params.UpdatePocketParams calldata params,
		string calldata reason
	) external onlyRole(RELAYER) mustBeValidPocket(params.id) {
		/// @dev Validate input
		require(
			params.startAt >= block.timestamp,
			"Timestamp: must be equal or greater than block time"
		);
		require(
			params.batchVolume >= 0,
			"Batch volume: must be equal or greater than 0"
		);
		require(
			params.frequency >= 1 hours,
			"Frequency: must be equal or greater than 1 hour"
		);
		/// @dev Validate stop condition through loop
		for (uint256 index = 0; index < params.stopConditions.length; index++) {
			require(
				params.stopConditions[index].value > 0,
				"StopCondition: value must not be zero"
			);
		}
		/// @dev Validate value comparison struct
		if (
			params.openingPositionCondition.operator !=
			Types.ValueComparisonOperator.Unset
		) {
			if (
				params.openingPositionCondition.operator ==
				Types.ValueComparisonOperator.Bw ||
				params.openingPositionCondition.operator ==
				Types.ValueComparisonOperator.NBw
			) {
				require(
					params.openingPositionCondition.value0 > 0 &&
						params.openingPositionCondition.value1 >=
						params.openingPositionCondition.value0,
					"ValueComparison: invalid value"
				);
			} else {
				require(
					params.openingPositionCondition.value0 > 0,
					"ValueComparison: invalid value"
				);
			}
		}
		/// @dev Validate value comparison struct
		if (
			params.takeProfitCondition.stopType !=
			Types.TradingStopConditionType.Unset
		) {
			require(
				params.takeProfitCondition.value > 0,
				"ValueComparison: invalid value"
			);
		}
		/// @dev Validate value comparison struct
		if (
			params.stopLossCondition.stopType !=
			Types.TradingStopConditionType.Unset
		) {
			require(
				params.stopLossCondition.value > 0,
				"ValueComparison: invalid value"
			);
		}

		Types.Pocket storage currentPocket = pockets[params.id];

		/// @dev Initialize user pocket data
		pockets[params.id] = Types.Pocket({
			/// @dev Those fields are updated
			startAt: params.startAt,
			batchVolume: params.batchVolume,
			frequency: params.frequency,
			stopConditions: params.stopConditions,
			openingPositionCondition: params.openingPositionCondition,
			takeProfitCondition: params.takeProfitCondition,
			stopLossCondition: params.stopLossCondition,
			/// @dev Reserve those fields
			id: currentPocket.id,
			owner: currentPocket.owner,
			ammRouterAddress: currentPocket.ammRouterAddress,
			baseTokenAddress: currentPocket.baseTokenAddress,
			targetTokenAddress: currentPocket.targetTokenAddress,
			status: currentPocket.status,
			totalDepositedBaseAmount: currentPocket.totalDepositedBaseAmount,
			totalReceivedTargetAmount: currentPocket.totalReceivedTargetAmount,
			totalSwappedBaseAmount: currentPocket.totalSwappedBaseAmount,
			totalClosedPositionInTargetTokenAmount: currentPocket
				.totalClosedPositionInTargetTokenAmount,
			totalReceivedFundInBaseTokenAmount: currentPocket
				.totalReceivedFundInBaseTokenAmount,
			baseTokenBalance: currentPocket.baseTokenBalance,
			targetTokenBalance: currentPocket.targetTokenBalance,
			executedBatchAmount: currentPocket.executedBatchAmount,
			nextScheduledExecutionAt: currentPocket.nextScheduledExecutionAt
		});

		/// @dev Emit event
		emit PocketUpdated(
			msg.sender,
			currentPocket.id,
			currentPocket.owner,
			reason,
			pockets[params.id]
		);
	}

	/// @notice The function to provide a method for relayers to update pocket stats
	function updatePocketClosingPositionStats(
		Params.UpdatePocketClosingPositionStatsParams calldata params,
		string calldata reason
	) external onlyRole(RELAYER) {
		/// @dev Check for permission
		require(
			hasRole(OPERATOR, params.actor) ||
				isOwnerOf(params.id, params.actor),
			"Operation error: operation is not permitted"
		);

		Types.Pocket storage pocket = pockets[params.id];

		/// @dev Assigned value
		pocket.totalClosedPositionInTargetTokenAmount = params
			.swappedTargetTokenAmount;
		pocket.totalReceivedFundInBaseTokenAmount = params
			.receivedBaseTokenAmount;

		/// @dev Update balance properly
		pocket.baseTokenBalance = pocket.baseTokenBalance.add(
			params.receivedBaseTokenAmount
		);
		pocket.targetTokenBalance = 0;

		/// @dev Emit events
		emit PocketUpdated(msg.sender, params.id, params.actor, reason, pocket);
	}

	/// @notice The function to provide a method for relayers to update pocket stats
	function updatePocketTradingStats(
		Params.UpdatePocketTradingStatsParams calldata params,
		string calldata reason
	) external onlyRole(RELAYER) {
		/// @dev Check for permission
		require(
			hasRole(OPERATOR, params.actor) ||
				isOwnerOf(params.id, params.actor),
			"Operation error: operation is not permitted"
		);

		Types.Pocket storage pocket = pockets[params.id];

		/// @dev Assigned value
		pocket.nextScheduledExecutionAt = block.timestamp.add(pocket.frequency);
		pocket.executedBatchAmount = pocket.executedBatchAmount.add(1);

		/// @dev Update balance properly
		pocket.totalSwappedBaseAmount = pocket.totalSwappedBaseAmount.add(
			params.swappedBaseTokenAmount
		);
		pocket.totalReceivedTargetAmount = pocket.totalReceivedTargetAmount.add(
			params.receivedTargetTokenAmount
		);
		pocket.baseTokenBalance = pocket.baseTokenBalance.sub(
			params.swappedBaseTokenAmount
		);
		pocket.targetTokenBalance = pocket.targetTokenBalance.add(
			params.receivedTargetTokenAmount
		);

		/// @dev Emit events
		emit PocketUpdated(msg.sender, params.id, params.actor, reason, pocket);
	}

	/// @notice The function to provide a method for relayers to update pocket stats
	function updatePocketWithdrawalStats(
		Params.UpdatePocketWithdrawalParams calldata params,
		string calldata reason
	) external onlyRole(RELAYER) mustBeOwnerOf(params.id, params.actor) {
		Types.Pocket storage pocket = pockets[params.id];

		/// @dev Assigned value
		pocket.baseTokenBalance = 0;
		pocket.targetTokenBalance = 0;
		pocket.status = Types.PocketStatus.Withdrawn;

		/// @dev Emit events
		emit PocketUpdated(msg.sender, params.id, params.actor, reason, pocket);
	}

	/// @notice The function to provide a method for relayers to update pocket stats
	function updatePocketDepositStats(
		Params.UpdatePocketDepositParams calldata params,
		string calldata reason
	) external onlyRole(RELAYER) mustBeOwnerOf(params.id, params.actor) {
		Types.Pocket storage pocket = pockets[params.id];

		/// @dev Assigned value
		pocket.totalDepositedBaseAmount = pocket.totalDepositedBaseAmount.add(
			params.amount
		);
		pocket.baseTokenBalance = pocket.baseTokenBalance.add(params.amount);

		/// @dev Emit events
		emit PocketUpdated(msg.sender, params.id, params.actor, reason, pocket);
	}

	/// @notice The function to provide a method for relayers to update pocket stats
	function updatePocketStatus(
		Params.UpdatePocketStatusParams calldata params,
		string calldata reason
	) external onlyRole(RELAYER) {
		require(
			hasRole(OPERATOR, params.actor) ||
				isOwnerOf(params.id, params.actor),
			"Operation error: operation is not permitted"
		);

		Types.Pocket storage pocket = pockets[params.id];

		/// @dev Assigned value
		pocket.status = params.status;

		/// @dev Emit events
		emit PocketUpdated(msg.sender, params.id, params.actor, reason, pocket);
	}

	/// @notice Admin can update whitelisted address
	/// @dev Simply assign value to the mapping
	function whitelistAddress(address interactiveAddress, bool value)
		external
		onlyOwner
	{
		allowedInteractiveAddresses[interactiveAddress] = value;
		emit AddressWhitelisted(msg.sender, interactiveAddress, value);
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
	function grantRole(bytes32 role, address account)
		public
		override
		onlyOwner
	{
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
	function revokeRole(bytes32 role, address account)
		public
		override
		onlyOwner
	{
		_revokeRole(role, account);
	}

	/// ================ System methods ================== ///
	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	/// @notice Initialization func
	function initialize() public initializer {
		__Pausable_init();
		__Ownable_init();
		__AccessControl_init();
		__ReentrancyGuard_init();

		// Grant default role
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	function pause() public onlyOwner onlyRole(DEFAULT_ADMIN_ROLE) {
		_pause();
	}

	function unpause() public onlyOwner onlyRole(DEFAULT_ADMIN_ROLE) {
		_unpause();
	}
	/// ================ End System methods ================== ///
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Types {
	/**
	 * @dev Pocket status which has 4 statuses
	 */
	enum PocketStatus {
		Unset,
		Active,
		Paused,
		Closed,
		Withdrawn
	}

	/**
	 * @dev Value comparison
	 */
	enum ValueComparisonOperator {
		Unset,
		Gt,
		Gte,
		Lt,
		Lte,
		Bw,
		NBw
	}
	struct ValueComparison {
		uint256 value0;
		uint256 value1;
		ValueComparisonOperator operator;
	}

	/// @dev Declare trading stop condition
	enum TradingStopConditionType {
		Unset,
		Price,
		PortfolioPercentageDiff,
		PortfolioValueDiff
	}
	struct TradingStopCondition {
		TradingStopConditionType stopType;
		uint256 value;
	}

	/**
	 * @dev Stop condition
	 */
	enum StopConditionOperator {
		EndTimeReach,
		BatchAmountReach,
		SpentBaseTokenAmountReach,
		ReceivedTargetTokenAmountReach
	}
	struct StopCondition {
		uint256 value;
		StopConditionOperator operator;
	}

	/**
	 * @dev Define Pocket
	 */
	struct Pocket {
		/**
		 * @dev Each pocket would have a unique id
		 */
		string id;
		/**
		 * @dev Info is used for statistic
		 * @dev Following fields will be assigned during runtime.
		 */
		uint256 totalDepositedBaseAmount;
		uint256 totalSwappedBaseAmount;
		uint256 totalReceivedTargetAmount;
		uint256 totalClosedPositionInTargetTokenAmount;
		uint256 totalReceivedFundInBaseTokenAmount;
		uint256 baseTokenBalance;
		uint256 targetTokenBalance;
		uint256 executedBatchAmount;
		uint256 nextScheduledExecutionAt;
		PocketStatus status;
		/**
		 * @dev Owner
		 */
		address owner;
		/**
		 * @dev AMM configurations
		 */
		address ammRouterAddress;
		address baseTokenAddress;
		address targetTokenAddress;
		/**
		 * @dev Pocket trade config
		 **/

		uint256 startAt;
		uint256 batchVolume;
		uint256 frequency;
		ValueComparison openingPositionCondition;
		StopCondition[] stopConditions;
		TradingStopCondition takeProfitCondition;
		TradingStopCondition stopLossCondition;
	}
}