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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
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
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
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
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
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

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
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
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

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
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

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
    ) internal virtual {}

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
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
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
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155SupplyUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Supply_init() internal onlyInitializing {
    }

    function __ERC1155Supply_init_unchained() internal onlyInitializing {
    }
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155SupplyUpgradeable.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.16;

// TODO clean this whole thing up
// Allows anyone to claim a token if they exist in a merkle root.
interface IQuest {
    event Claimed(address indexed account, address rewardAddress, uint256 amount);
    event ClaimedSingle(address indexed account, address rewardAddress, uint256 amount);
    event Queued(uint timestamp);
    event JsonSpecCIDSet(string cid);

    error AlreadyClaimed();
    error AmountExceedsBalance();
    error ClaimWindowNotStarted();
    error EndTimeInPast();
    error EndTimeLessThanOrEqualToStartTime();
    error MustImplementInChild();
    error NotQuestFactory();
    error NoTokensToClaim();
    error NoWithdrawDuringClaim();
    error NotStarted();
    error TotalAmountExceedsBalance();

    function isClaimed(uint256 tokenId_) external view returns (bool);

    function getRewardAmount() external view returns (uint256);

    function getRewardToken() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.16;

interface IQuestFactory {
    error AddressAlreadyMinted();
    error AddressNotSigned();
    error AddressZeroNotAllowed();
    error Erc20QuestAddressNotSet();
    error InvalidHash();
    error OnlyOwnerCanCreate1155Quest();
    error OverMaxAllowedToMint();
    error QuestEnded();
    error QuestFeeTooHigh();
    error QuestIdUsed();
    error QuestNotQueued();
    error QuestNotStarted();
    error QuestTypeInvalid();
    error RewardNotAllowed();
    error ZeroAddressNotAllowed();

    event QuestCreated(
        address indexed creator,
        address indexed contractAddress,
        string questId,
        string contractType,
        address rewardTokenAddress,
        uint256 endTime,
        uint256 startTime,
        uint256 totalParticipants,
        uint256 rewardAmountOrTokenId
    );
    event ReceiptMinted(address indexed recipient, address indexed questAddress, uint indexed tokenId, string questId);
    event QuestNFTMinted(address indexed recipient, address indexed questAddress, uint indexed tokenId, string questId);
    event MintFeeSet(uint percent);
    event ExtraMintFeeReturned(address indexed recipient, uint amount);
    event NftQuestFeeSet(uint fee);
    event QuestNFTCreated(address indexed newQuestNFT, address questCreator, string collectionName);
    event QuestClaimed(address indexed recipient, address indexed questAddress, string questId, address rewardToken, uint rewardAmountInWei);

    function questInfo(string memory questId_) external view returns (address, uint, uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// Modified to pass in the owner address to the constructor

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
    function __Ownable_init(address owner_) internal onlyInitializing {
        __Ownable_init_unchained(owner_);
    }

    function __Ownable_init_unchained(address owner_) internal onlyInitializing {
        _transferOwnership(owner_);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.16;

import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {IERC20, SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {PausableUpgradeable} from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import {ReentrancyGuardUpgradeable} from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import {RabbitHoleReceipt} from './RabbitHoleReceipt.sol';
import {QuestFactory} from './QuestFactory.sol';
import {IQuest} from './interfaces/IQuest.sol';

/// @title Quest
/// @author RabbitHole.gg
/// @notice This contract is the Erc20Quest contract. It is a quest that is redeemable for ERC20 tokens
contract Quest is ReentrancyGuardUpgradeable, PausableUpgradeable, OwnableUpgradeable, IQuest {
    using SafeERC20 for IERC20;

    RabbitHoleReceipt public rabbitHoleReceiptContract;
    QuestFactory public questFactoryContract;
    address public rewardToken;
    uint256 public endTime;
    uint256 public startTime;
    uint256 public totalParticipants;
    uint256 public rewardAmountInWei;
    bool public queued;
    string public questId;
    uint256 public redeemedTokens;
    uint16 public questFee;
    bool public hasWithdrawn;
    address public protocolFeeRecipient;
    mapping(uint256 => bool) private claimedList;
    string public jsonSpecCID;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address rewardTokenAddress_,
        uint256 endTime_,
        uint256 startTime_,
        uint256 totalParticipants_,
        uint256 rewardAmountInWei_,
        string memory questId_,
        address receiptContractAddress_,
        uint16 questFee_,
        address protocolFeeRecipient_
    ) external initializer {
        if (endTime_ <= block.timestamp) revert EndTimeInPast();
        if (endTime_ <= startTime_) revert EndTimeLessThanOrEqualToStartTime();
        endTime = endTime_;
        startTime = startTime_;
        rewardToken = rewardTokenAddress_;
        totalParticipants = totalParticipants_;
        rewardAmountInWei = rewardAmountInWei_;
        questId = questId_;
        questFactoryContract = QuestFactory(payable(msg.sender));
        rabbitHoleReceiptContract = RabbitHoleReceipt(receiptContractAddress_);
        questFee = questFee_;
        hasWithdrawn = false;
        protocolFeeRecipient = protocolFeeRecipient_;
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /// @dev set jsonSpecCID only if its empty
    /// @param jsonSpecCID_ The jsonSpecCID to set
    function setJsonSpecCID(string memory jsonSpecCID_) external onlyOwner {
        require(bytes(jsonSpecCID_).length > 0, 'jsonSpecCID cannot be empty');
        require(bytes(jsonSpecCID).length == 0, 'jsonSpecCID already set');

        jsonSpecCID = jsonSpecCID_;
        emit JsonSpecCIDSet(jsonSpecCID_);
    }

    /// @dev The amount of tokens the quest needs to pay all redeemers plus the protocol fee
    function totalTransferAmount() external view returns (uint256) {
        return this.maxTotalRewards() + this.maxProtocolReward();
    }

    /// @notice Queues the quest by marking it ready to start at the contract level. Marking a quest as queued does not mean that it is live. It also requires that the start time has passed
    /// @dev Requires that the balance of the rewards in the contract is greater than or equal to the maximum amount of rewards that can be claimed by all users and the protocol
    function queue() public virtual onlyOwner {
        if (IERC20(rewardToken).balanceOf(address(this)) < this.totalTransferAmount())
            revert TotalAmountExceedsBalance();
        queued = true;
        emit Queued(block.timestamp);
    }

    /// @notice Pauses the Quest
    /// @dev Only the owner of the Quest can call this function. Also requires that the Quest has started (not by date, but by calling the start function)
    function pause() external onlyOwner onlyStarted {
        _pause();
    }

    /// @notice Unpauses the Quest
    /// @dev Only the owner of the Quest can call this function. Also requires that the Quest has started (not by date, but by calling the start function)
    function unPause() external onlyOwner onlyStarted {
        _unpause();
    }

    /// @notice Marks token ids as claimed
    /// @param tokenIds_ The token ids to mark as claimed
    function _setClaimed(uint256[] memory tokenIds_) private {
        for (uint i = 0; i < tokenIds_.length; ) {
            claimedList[tokenIds_[i]] = true;
            unchecked {
                i++;
            }
        }
    }

    /// @notice Prevents reward withdrawal until the Quest has ended
    modifier onlyWithdrawAfterEnd() {
        if (block.timestamp < endTime) revert NoWithdrawDuringClaim();
        _;
    }

    /// @notice Checks if the Quest has started at the function level
    modifier onlyStarted() {
        if (!queued) revert NotStarted();
        _;
    }

    /// @notice Checks if quest has started both at the function level and at the start time
    modifier onlyQuestActive() {
        if (!queued) revert NotStarted();
        if (block.timestamp < startTime) revert ClaimWindowNotStarted();
        _;
    }

    modifier onlyProtocolFeeRecipientOrOwner() {
        require(msg.sender == protocolFeeRecipient || msg.sender == owner(), 'Not protocol fee recipient or owner');
        _;
    }

    modifier onlyQuestFactory() {
        if (msg.sender != address(questFactoryContract)) revert NotQuestFactory();
        _;
    }

    /// @dev transfers rewards to the account, can only be called once per account per quest and only by the quest factory
    /// @param account_ The account to transfer rewards to
    function singleClaim(address account_) external virtual nonReentrant onlyQuestActive whenNotPaused onlyQuestFactory {
        uint256 totalRedeemableRewards = _calculateRewards(1);
        _transferRewards(account_, totalRedeemableRewards);
        redeemedTokens = redeemedTokens + 1;
        emit ClaimedSingle(account_, rewardToken, totalRedeemableRewards);
    }

    /// @notice Allows user to claim the rewards entitled to them
    /// @dev User can claim based on the (unclaimed) number of tokens they own of the Quest
    function claim() external virtual nonReentrant onlyQuestActive whenNotPaused {
        uint[] memory tokens = rabbitHoleReceiptContract.getOwnedTokenIdsOfQuest(questId, msg.sender);

        if (tokens.length == 0) revert NoTokensToClaim();

        uint256 redeemableTokenCount = 0;
        for (uint i = 0; i < tokens.length; ) {
            if (!this.isClaimed(tokens[i])) {
                unchecked {
                    redeemableTokenCount++;
                }
            }
            unchecked {
                i++;
            }
        }

        if (redeemableTokenCount == 0) revert AlreadyClaimed();

        uint256 totalRedeemableRewards = _calculateRewards(redeemableTokenCount);
        _setClaimed(tokens);
        _transferRewards(msg.sender, totalRedeemableRewards);
        redeemedTokens = redeemedTokens + redeemableTokenCount;

        emit Claimed(msg.sender, rewardToken, totalRedeemableRewards);
    }

    /// @dev Function that gets the maximum amount of rewards that can be claimed by all users. It does not include the protocol fee
    /// @return The maximum amount of rewards that can be claimed by all users
    function maxTotalRewards() external view returns (uint256) {
        return totalParticipants * rewardAmountInWei;
    }

    /// @notice Function that gets the maximum amount of rewards that can be claimed by the protocol or the quest deployer
    /// @dev The 10_000 comes from Basis Points: https://www.investopedia.com/terms/b/basispoint.asp
    /// @return The maximum amount of rewards that can be claimed by the protocol or the quest deployer
    function maxProtocolReward() external view returns (uint256) {
        return (this.maxTotalRewards() * questFee) / 10_000;
    }

    /// @notice Internal function that transfers the rewards to the msg.sender
    /// @param sender_ The address to send the rewards to
    /// @param amount_ The amount of rewards to transfer
    function _transferRewards(address sender_, uint256 amount_) internal {
        IERC20(rewardToken).safeTransfer(sender_, amount_);
    }

    /// @notice Internal function that calculates the reward amount
    /// @dev It is possible for users to have multiple receipts (if they buy others on secondary markets)
    /// @param redeemableTokenCount_ The amount of tokens that can be redeemed
    /// @return The total amount of rewards that can be claimed by a user
    function _calculateRewards(uint256 redeemableTokenCount_) internal view returns (uint256) {
        return redeemableTokenCount_ * rewardAmountInWei;
    }

    /// @notice Function that allows either the protocol fee recipient or the owner to withdraw the remaining tokens in the contract
    /// @dev Every receipt minted should still be able to claim rewards (and cannot be withdrawn). This function can only be called after the quest end time
    function withdrawRemainingTokens() external onlyProtocolFeeRecipientOrOwner onlyWithdrawAfterEnd {
        require(!hasWithdrawn, 'Already withdrawn');

        uint unclaimedTokens = (this.receiptRedeemers() - redeemedTokens) * rewardAmountInWei;
        uint256 nonClaimableTokens = IERC20(rewardToken).balanceOf(address(this)) -
            this.protocolFee() -
            unclaimedTokens;
        hasWithdrawn = true;

        IERC20(rewardToken).safeTransfer(owner(), nonClaimableTokens);
        IERC20(rewardToken).safeTransfer(protocolFeeRecipient, this.protocolFee());
    }

    /// @notice Function that calculates the protocol fee
    function protocolFee() external view returns (uint256) {
        return (this.receiptRedeemers() * rewardAmountInWei * questFee) / 10_000;
    }

    // @notice Call the QuestFactory contract to get the amount of receipts that have been minted
    /// @return The amount of receipts that have been minted for the given quest
    function receiptRedeemers() public view returns (uint256) {
        return questFactoryContract.getNumberMinted(questId);
    }

    /// @notice Checks if a Receipt token id has been used to claim a reward
    /// @param tokenId_ The token id to check
    function isClaimed(uint256 tokenId_) external view returns (bool) {
        return claimedList[tokenId_] == true;
    }

    /// @dev Returns the reward amount
    function getRewardAmount() external view returns (uint256) {
        return rewardAmountInWei;
    }

    /// @dev Returns the reward token address
    function getRewardToken() external view returns (address) {
        return rewardToken;
    }

    /// @dev transfer all coins and tokens that is not the rewardToken to the contract owner.
    /// @param erc20Address_ The address of the ERC20 token to refund
    function refund(address erc20Address_) external onlyOwner {
        require(erc20Address_ != rewardToken, 'Cannot refund reward token');

        uint balance = address(this).balance;
        if (balance > 0) payable(msg.sender).transfer(balance);

        uint erc20Balance = IERC20(erc20Address_).balanceOf(address(this));
        if (erc20Balance > 0) IERC20(erc20Address_).safeTransfer(msg.sender, erc20Balance);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.16;
pragma experimental ABIEncoderV2;

import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {IQuestFactory} from './interfaces/IQuestFactory.sol';
import {Quest as QuestContract} from './Quest.sol';
import {RabbitHoleReceipt} from './RabbitHoleReceipt.sol';
import {OwnableUpgradeable} from './OwnableUpgradeable.sol';
import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {ECDSAUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';
import {AccessControlUpgradeable} from '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {QuestTerminalKey} from "./QuestTerminalKey.sol";
import {QuestNFT as QuestNFTContract} from "./QuestNFT.sol";

/// @title QuestFactory
/// @author RabbitHole.gg
/// @dev This contract is used to create quests and mint receipts
contract QuestFactory is Initializable, OwnableUpgradeable, AccessControlUpgradeable, IQuestFactory {
    using SafeERC20 for IERC20;

    // storage vars. Insert new vars at the end to keep the storage layout the same.
    struct Quest {
        mapping(address => bool) addressMinted;
        address questAddress;
        uint totalParticipants;
        uint numberMinted;
    }
    address public claimSignerAddress;
    address public protocolFeeRecipient;
    address public erc20QuestAddress;
    address public erc1155QuestAddress;
    mapping(string => Quest) public quests;
    RabbitHoleReceipt public rabbitHoleReceiptContract;
    address public rabbitHoleTicketsContract;
    mapping(address => bool) public rewardAllowlist;
    uint16 public questFee;
    uint public mintFee;
    address public mintFeeRecipient;
    uint256 private locked;
    QuestTerminalKey private questTerminalKeyContract;
    uint public nftQuestFee;
    address public questNFTAddress;
    struct QuestNFTData {
        uint256 startTime;
        uint256 endTime;
        uint256 totalParticipants;
        string questId;
        string description;
        string imageIPFSHash;
    }
    struct QuestData {
        address questAddress;
        address rewardToken;
        bool queued;
        uint16 questFee;
        uint startTime;
        uint endTime;
        uint totalParticipants;
        uint numberMinted;
        uint redeemedTokens;
        uint rewardAmountInWei;
        bool hasWithdrawn;
    }
    mapping(address => address[]) public ownerCollections;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address claimSignerAddress_,
        address rabbitHoleReceiptContract_,
        address protocolFeeRecipient_,
        address erc20QuestAddress_,
        address ownerAddress_,
        address questTerminalKeyAddress_,
        address payable questNFTAddress_,
        uint nftQuestFee_
    ) external initializer {
        __Ownable_init(ownerAddress_);
        __AccessControl_init();
        claimSignerAddress = claimSignerAddress_;
        rabbitHoleReceiptContract = RabbitHoleReceipt(rabbitHoleReceiptContract_);
        protocolFeeRecipient = protocolFeeRecipient_;
        questFee = 2_000; // in BIPS
        erc20QuestAddress = erc20QuestAddress_;
        locked = 1;
        questTerminalKeyContract = QuestTerminalKey(questTerminalKeyAddress_);
        questNFTAddress = questNFTAddress_;
        nftQuestFee = nftQuestFee_;
    }

    /// @dev ReentrancyGuard modifier from solmate, copied here because it was added after storage layout was finalized on first deploy
    /// @dev from https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol
    modifier nonReentrant() virtual {
        if (locked == 0) locked = 1;
        require(locked == 1, "REENTRANCY");
        locked = 2;
        _;
        locked = 1;
    }

    modifier claimChecks(string memory questId_, bytes32 hash_, bytes memory signature_) {
        Quest storage currentQuest = quests[questId_];

        if (currentQuest.numberMinted + 1 > currentQuest.totalParticipants) revert OverMaxAllowedToMint();
        if (currentQuest.addressMinted[msg.sender]) revert AddressAlreadyMinted();
        if (keccak256(abi.encodePacked(msg.sender, questId_)) != hash_) revert InvalidHash();
        if (recoverSigner(hash_, signature_) != claimSignerAddress) revert AddressNotSigned();
        _;
    }

    modifier sufficientMintFee() {
        require(msg.value >= mintFee, "Insufficient mint fee");
        _;
    }

    /// @dev Create an erc20 quest, only accounts with the CREATE_QUEST_ROLE can create quests
    modifier checkQuest(string memory questId_, address rewardTokenAddress_) {
        Quest storage currentQuest = quests[questId_];
        if (currentQuest.questAddress != address(0)) revert QuestIdUsed();
        if (!rewardAllowlist[rewardTokenAddress_]) revert RewardNotAllowed();
        if (erc20QuestAddress == address(0)) revert Erc20QuestAddressNotSet();
        _;
    }

    modifier nonZeroAddress(address _address) {
        if (_address == address(0)) revert ZeroAddressNotAllowed();
        _;
    }

    function createQuestInternal(
        address rewardTokenAddress_,
        uint256 endTime_,
        uint256 startTime_,
        uint256 totalParticipants_,
        uint256 rewardAmount_,
        string memory questId_,
        uint256 discountTokenId_
    ) internal returns (address) {
        Quest storage currentQuest = quests[questId_];
        address newQuest = Clones.cloneDeterministic(erc20QuestAddress, keccak256(abi.encodePacked(msg.sender, questId_)));
        emit QuestCreated(
            msg.sender,
            address(newQuest),
            questId_,
            "erc20",
            rewardTokenAddress_,
            endTime_,
            startTime_,
            totalParticipants_,
            rewardAmount_
        );
        uint16 protocolFee;
        currentQuest.questAddress = address(newQuest);
        currentQuest.totalParticipants = totalParticipants_;

        if(discountTokenId_ == 0){
            protocolFee = questFee;
        }else{
            protocolFee = doDiscountedFee(discountTokenId_);
        }

        QuestContract(newQuest).initialize(
            rewardTokenAddress_,
            endTime_,
            startTime_,
            totalParticipants_,
            rewardAmount_,
            questId_,
            address(rabbitHoleReceiptContract),
            protocolFee,
            protocolFeeRecipient
        );

        return newQuest;
    }

    function doDiscountedFee(uint tokenId_) internal returns (uint16) {
        require(questTerminalKeyContract.ownerOf(tokenId_) == msg.sender, "QuestFactory: caller is not owner of discount token");

        (uint16 discountPercentage, ) = questTerminalKeyContract.discounts(tokenId_);

        questTerminalKeyContract.incrementUsedCount(tokenId_);
        return uint16((uint(questFee) * (10000 - uint(discountPercentage))) / 10000);
    }

    /// @dev Transfer the total transfer amount to the quest contract
    /// @dev Contract must be approved to transfer first
    /// @param newQuest_ The address of the new quest
    /// @param rewardTokenAddress_ The contract address of the reward token
    function transferTokensAndQueueQuest(address newQuest_, address rewardTokenAddress_) internal {
        IERC20(rewardTokenAddress_).safeTransferFrom(msg.sender, newQuest_, QuestContract(newQuest_).totalTransferAmount());
        QuestContract(newQuest_).queue();
    }

    /// @dev Create an erc20 quest
    /// @param rewardTokenAddress_ The contract address of the reward token
    /// @param endTime_ The end time of the quest
    /// @param startTime_ The start time of the quest
    /// @param totalParticipants_ The total amount of participants (accounts) the quest will have
    /// @param rewardAmount_ The reward amount for an erc20 quest
    /// @param questId_ The id of the quest
    /// @return address the quest contract address
    function createQuest(
        address rewardTokenAddress_,
        uint256 endTime_,
        uint256 startTime_,
        uint256 totalParticipants_,
        uint256 rewardAmount_,
        string memory, // was contractType_ , currently deprecated.
        string memory questId_
    ) external checkQuest(questId_, rewardTokenAddress_) returns (address) {
        address newQuest = createQuestInternal(
            rewardTokenAddress_,
            endTime_,
            startTime_,
            totalParticipants_,
            rewardAmount_,
            questId_,
            0
        );

        QuestContract(newQuest).transferOwnership(msg.sender);

        return newQuest;
    }

    /// @dev Create an erc20 quest and start it at the same time. The function will transfer the reward amount to the quest contract
    /// @param rewardTokenAddress_ The contract address of the reward token
    /// @param endTime_ The end time of the quest
    /// @param startTime_ The start time of the quest
    /// @param totalParticipants_ The total amount of participants (accounts) the quest will have
    /// @param rewardAmount_ The reward amount for an erc20 quest
    /// @param questId_ The id of the quest
    /// @param jsonSpecCID The CID of the JSON spec for the quest
    /// @param discountTokenId_ The id of the discount token
    /// @return address the quest contract address
    function createQuestAndQueue(
        address rewardTokenAddress_,
        uint256 endTime_,
        uint256 startTime_,
        uint256 totalParticipants_,
        uint256 rewardAmount_,
        string memory questId_,
        string memory jsonSpecCID,
        uint256 discountTokenId_
    ) external checkQuest(questId_, rewardTokenAddress_) returns (address) {
        address newQuest = createQuestInternal(
            rewardTokenAddress_,
            endTime_,
            startTime_,
            totalParticipants_,
            rewardAmount_,
            questId_,
            discountTokenId_
        );

        transferTokensAndQueueQuest(newQuest, rewardTokenAddress_);
        if(bytes(jsonSpecCID).length > 0) QuestContract(newQuest).setJsonSpecCID(jsonSpecCID);
        QuestContract(newQuest).transferOwnership(msg.sender);

        return newQuest;
    }

    /// @dev Create an ERC1155 QuestNFT collection
    /// @param collectionName_ The collection name of the 1155 NFT contract
    /// @return address the QuestNFT contract address
    function createCollection(string memory collectionName_) nonReentrant external returns (address) {
        address payable newQuestNFT = payable(Clones.cloneDeterministic(questNFTAddress, keccak256(abi.encodePacked(msg.sender, collectionName_))));

        QuestNFTContract(newQuestNFT).initialize(
            protocolFeeRecipient,
            address(this),
            collectionName_
        );
        QuestNFTContract(newQuestNFT).transferOwnership(msg.sender);

        ownerCollections[msg.sender].push(newQuestNFT);

        emit QuestNFTCreated(
            address(newQuestNFT),
            msg.sender,
            collectionName_
        );

        return newQuestNFT;
    }

    /// @dev Add a quest to a QuestNFT collection. The function will transfer the total questFee amount to the QuestNFT
    /// @param collectionAddress_ The address of the QuestNFT collection
    /// @param startTime_ The start time of the quest
    /// @param endTime_ The end time of the quest
    /// @param totalParticipants_ The total amount of participants (accounts) the quest will have
    /// @param questId_ The id of the quest
    /// @param description_ The description of the quest
    /// @param imageIPFSHash_ The IPFS hash of the image for the quest
    function addQuestToCollection(
        address payable collectionAddress_,
        uint256 startTime_,
        uint256 endTime_,
        uint256 totalParticipants_,
        string memory questId_,
        string memory description_,
        string memory imageIPFSHash_
    ) external payable nonReentrant {
        QuestNFTData memory data = QuestNFTData({
            startTime: startTime_,
            endTime: endTime_,
            totalParticipants: totalParticipants_,
            questId: questId_,
            description: description_,
            imageIPFSHash: imageIPFSHash_
        });

        Quest storage currentQuest = quests[data.questId];
        if (currentQuest.questAddress != address(0)) revert QuestIdUsed();
        require(msg.value >= totalQuestNFTFee(data.totalParticipants), "QuestFactory: msg.value is not equal to the total quest fee");
        require(msg.sender == QuestNFTContract(collectionAddress_).owner(), "QuestFactory: only the NFT quest owner can call this function");

        QuestNFTContract(collectionAddress_).addQuest(nftQuestFee, data.startTime, data.endTime, data.totalParticipants, data.questId, data.description, data.imageIPFSHash);

        currentQuest.questAddress = address(collectionAddress_);
        currentQuest.totalParticipants = data.totalParticipants;

        (bool success, ) = payable(collectionAddress_).call{value: msg.value}("");
        require(success, "QuestFactory: Failed to send coins to the QuestNFT contract");

        emit QuestCreated(
            msg.sender,
            collectionAddress_,
            data.questId,
            "nft",
            address(0), // rewardTokenAddress
            data.endTime,
            data.startTime,
            data.totalParticipants,
            1
        );
    }

    function ownerCollectionsByOwner(address owner_) external view returns (address[] memory) {
        return ownerCollections[owner_];
    }

    function totalQuestNFTFee(uint totalParticipants_) public view returns (uint256) {
        return nftQuestFee * totalParticipants_;
    }

    /// @dev set erc20QuestAddress
    /// @param erc20QuestAddress_ The address of the erc20 quest
    function setErc20QuestAddress(address erc20QuestAddress_) public onlyOwner {
        erc20QuestAddress = erc20QuestAddress_;
    }

    /// @dev set the claim signer address
    /// @param claimSignerAddress_ The address of the claim signer
    function setClaimSignerAddress(address claimSignerAddress_) public onlyOwner {
        claimSignerAddress = claimSignerAddress_;
    }

    /// @dev set the protocol fee recipient
    /// @param protocolFeeRecipient_ The address of the protocol fee recipient
    function setProtocolFeeRecipient(address protocolFeeRecipient_) public onlyOwner {
        if (protocolFeeRecipient_ == address(0)) revert AddressZeroNotAllowed();
        protocolFeeRecipient = protocolFeeRecipient_;
    }

    /// @dev set the mintFeeRecipient
    /// @param mintFeeRecipient_ The address of the mint fee recipient
    function setMintFeeRecipient(address mintFeeRecipient_) public onlyOwner {
        if (mintFeeRecipient_ == address(0)) revert AddressZeroNotAllowed();
        mintFeeRecipient = mintFeeRecipient_;
    }

    /// @dev get the mintFeeRecipient return the protocol fee recipient if the mint fee recipient is not set
    /// @return address the mint fee recipient
    function getMintFeeRecipient() public view returns (address) {
        if (mintFeeRecipient == address(0)) {
            return protocolFeeRecipient;
        }
        return mintFeeRecipient;
    }

    /// @dev set the rabbithole receipt contract
    /// @param rabbitholeReceiptContract_ The address of the rabbithole receipt contract
    function setRabbitHoleReceiptContract(address rabbitholeReceiptContract_) external onlyOwner {
        rabbitHoleReceiptContract = RabbitHoleReceipt(rabbitholeReceiptContract_);
    }

    /// @dev set the questNFT Address
    /// @param questNFTAddress_ The address of the questNFT
    function setQuestNFTAddress(address questNFTAddress_) external onlyOwner nonZeroAddress(questNFTAddress_) {
        questNFTAddress = questNFTAddress_;
    }

    /// @dev set the nftQuestFee
    /// @param nftQuestFee_ The value of the nftQuestFee
    function setNftQuestFee(uint nftQuestFee_) external onlyOwner {
        nftQuestFee = nftQuestFee_;
        emit NftQuestFeeSet(nftQuestFee_);
    }

    /// @dev set questTerminalKeyContract address
    /// @param questTerminalKeyContract_ The address of the questTerminalKeyContract
    function setQuestTerminalKeyContract(address questTerminalKeyContract_) external onlyOwner {
        questTerminalKeyContract = QuestTerminalKey(questTerminalKeyContract_);
    }

    /// @dev set or remave a contract address to be used as a reward
    /// @param rewardAddress_ The contract address to set
    /// @param allowed_ Whether the contract address is allowed or not
    function setRewardAllowlistAddress(address rewardAddress_, bool allowed_) public onlyOwner {
        rewardAllowlist[rewardAddress_] = allowed_;
    }

    /// @dev set the quest fee
    /// @notice the quest fee should be in Basis Point units
    /// @param questFee_ The quest fee value
    function setQuestFee(uint16 questFee_) public onlyOwner {
        if (questFee_ > 10_000) revert QuestFeeTooHigh();
        questFee = questFee_;
    }

    /// @dev set the mint fee
    /// @notice the mint fee in ether
    /// @param mintFee_ The mint fee value
    function setMintFee(uint mintFee_) public onlyOwner {
        mintFee = mintFee_;
        emit MintFeeSet(mintFee_);
    }

    /// @dev return the number of minted receipts for a quest
    /// @param questId_ The id of the quest
    function getNumberMinted(string memory questId_) external view returns (uint) {
        return quests[questId_].numberMinted;
    }

    /// @dev return extended quest data for a questId
    /// @param questId_ The id of the quest
    function questData(string memory questId_) external view returns (QuestData memory) {
        Quest storage thisQuest = quests[questId_];
        QuestContract questContract = QuestContract(thisQuest.questAddress);

        QuestData memory data = QuestData(
            thisQuest.questAddress,
            questContract.rewardToken(),
            questContract.queued(),
            questContract.questFee(),
            questContract.startTime(),
            questContract.endTime(),
            questContract.totalParticipants(),
            thisQuest.numberMinted,
            questContract.redeemedTokens(),
            questContract.rewardAmountInWei(),
            questContract.hasWithdrawn()
        );

        return data;
    }

    /// @dev return data in the quest struct for a questId
    /// @param questId_ The id of the quest
    function questInfo(string memory questId_) external view returns (address, uint, uint) {
        Quest storage currentQuest = quests[questId_];
        return (currentQuest.questAddress, currentQuest.totalParticipants, currentQuest.numberMinted);
    }

    /// @dev return status of whether an address has minted a receipt for a quest
    /// @param questId_ The id of the quest
    /// @param address_ The address to check
    /// @return Minted status
    function getAddressMinted(string memory questId_, address address_) external view returns (bool) {
        return quests[questId_].addressMinted[address_];
    }

    /// @dev recover the signer from a hash and signature
    /// @param hash_ The hash of the message
    /// @param signature_ The signature of the hash
    function recoverSigner(bytes32 hash_, bytes memory signature_) public pure returns (address) {
        bytes32 messageDigest = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', hash_));
        return ECDSAUpgradeable.recover(messageDigest, signature_);
    }

    function claimRewards(string memory questId_, bytes32 hash_, bytes memory signature_) external payable nonReentrant sufficientMintFee claimChecks(questId_, hash_, signature_) {
        Quest storage currentQuest = quests[questId_];
        QuestContract questContract_ = QuestContract(currentQuest.questAddress);
        if (!questContract_.queued()) revert QuestNotQueued();
        if (block.timestamp < questContract_.startTime()) revert QuestNotStarted();
        if (block.timestamp > questContract_.endTime()) revert QuestEnded();

        currentQuest.addressMinted[msg.sender] = true;
        ++currentQuest.numberMinted;
        questContract_.singleClaim(msg.sender);

        if(mintFee > 0) processMintFee();

        emit QuestClaimed(msg.sender, currentQuest.questAddress, questId_, questContract_.rewardToken(), questContract_.rewardAmountInWei());
    }

    /// @dev mint a QuestNFT.
    /// @notice this contract must be set as Minter on the QuestNFT
    /// @param questId_ The id of the quest
    /// @param hash_ The hash of the message
    /// @param signature_ The signature of the hash
    function mintQuestNFT(string memory questId_, bytes32 hash_, bytes memory signature_) external nonReentrant claimChecks(questId_, hash_, signature_) {
        Quest storage currentQuest = quests[questId_];

        currentQuest.addressMinted[msg.sender] = true;
        ++currentQuest.numberMinted;
        QuestNFTContract(payable(currentQuest.questAddress)).mint(msg.sender, questId_);
        emit QuestNFTMinted(msg.sender, currentQuest.questAddress, QuestNFTContract(payable(currentQuest.questAddress)).tokenIdFromQuestId(questId_), questId_);
    }

    /// @dev mint a RabbitHole Receipt. Note: this contract must be set as Minter on the receipt contract
    /// @param questId_ The id of the quest
    /// @param hash_ The hash of the message
    /// @param signature_ The signature of the hash
    function mintReceipt(string memory questId_, bytes32 hash_, bytes memory signature_) external payable nonReentrant sufficientMintFee claimChecks(questId_, hash_, signature_) {
        Quest storage currentQuest = quests[questId_];
        if (!QuestContract(currentQuest.questAddress).queued()) revert QuestNotQueued();
        if (block.timestamp < QuestContract(currentQuest.questAddress).startTime()) revert QuestNotStarted();
        if (block.timestamp > QuestContract(currentQuest.questAddress).endTime()) revert QuestEnded();

        currentQuest.addressMinted[msg.sender] = true;
        ++currentQuest.numberMinted;
        rabbitHoleReceiptContract.mint(msg.sender, questId_);

        emit ReceiptMinted(msg.sender, quests[questId_].questAddress, rabbitHoleReceiptContract.getTokenId(), questId_);

        if(mintFee > 0) processMintFee();
    }

    function processMintFee() private {
        uint change = msg.value - mintFee;
        if (change > 0) {
            // Refund any excess payment
            (bool changeSuccess, ) = msg.sender.call{value: change}("");
            require(changeSuccess, "Failed to return change");
            emit ExtraMintFeeReturned(msg.sender, change);
        }
        // Send the mint fee to the mint fee recipient
        (bool mintSuccess, ) = getMintFeeRecipient().call{value: mintFee}("");
        require(mintSuccess, "Failed to send mint fee");
    }

    // Receive function to receive ETH
    receive() external payable {}

    // Fallback function to receive ETH when other functions are not available
    fallback() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.16;

import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {ERC1155Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import {ERC1155SupplyUpgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol';
import {PausableUpgradeable} from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {IERC2981Upgradeable, IERC165Upgradeable} from '@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol';
import {SafeERC20, IERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {Base64} from '@openzeppelin/contracts/utils/Base64.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @title QuestNFT
/// @author RabbitHole.gg
/// @notice This contract is the Erc1155 Quest Collection contract. It is the NFT that can be minted after a quest is completed.
contract QuestNFT is Initializable, ERC1155Upgradeable, ERC1155SupplyUpgradeable, PausableUpgradeable, OwnableUpgradeable, IERC2981Upgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20 for IERC20;

    CountersUpgradeable.Counter private _tokenIdCounter;
    address public protocolFeeRecipient;
    address public minterAddress;
    string public collectionName;
    struct QuestData {
        uint256 startTime;
        uint256 endTime;
        uint256 totalParticipants;
        uint256 questFee;
        uint256 tokenId;
        string description;
        string imageIPFSHash;
    }
    mapping(string => QuestData) public quests; // questId => QuestData
    mapping(uint256 => string) public tokenIdToQuestId; // tokenId => questId

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address protocolFeeRecipient_,
        address minterAddress_, // should always be the QuestFactory contract
        string memory collectionName_
    ) external initializer {
        protocolFeeRecipient = protocolFeeRecipient_;
        minterAddress = minterAddress_;
        collectionName = collectionName_;
        __ERC1155_init("");
        __ERC1155Supply_init();
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /// @dev checks if the quest start time and end time are valid and the quest exists
    /// @param questId_ the questId to check
    modifier questChecks(string memory questId_) {
        QuestData storage quest = quests[questId_];
        require(quest.tokenId != 0, 'Quest does not exist');
        require(block.timestamp > quest.startTime, 'Quest not started');
        require(block.timestamp < quest.endTime, 'Quest ended');
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minterAddress, 'Only minter address');
        _;
    }

    function addQuest(
        uint256 questFee_,
        uint256 startTime_,
        uint256 endTime_,
        uint256 totalParticipants_,
        string memory questId_,
        string memory description_,
        string memory imageIPFSHash_
    ) public onlyMinter returns (uint256) {
        require (endTime_ > block.timestamp, 'endTime_ in the past');
        require (endTime_ > startTime_, 'startTime_ before endTime_');

        _tokenIdCounter.increment();
        QuestData storage quest = quests[questId_];
        quest.startTime = startTime_;
        quest.endTime = endTime_;
        quest.totalParticipants = totalParticipants_;
        quest.questFee = questFee_;
        quest.imageIPFSHash = imageIPFSHash_;
        quest.description = description_;
        quest.tokenId = _tokenIdCounter.current();
        tokenIdToQuestId[_tokenIdCounter.current()] = questId_;

        return _tokenIdCounter.current();
    }

    function mint(address to_, string memory questId_)
        public
        onlyMinter questChecks(questId_) whenNotPaused nonReentrant
    {
        QuestData storage quest = quests[questId_];

        _mint(to_, quest.tokenId, 1, "");

        (bool success, ) = protocolFeeRecipient.call{value: quest.questFee}("");
        require(success, 'protocol fee transfer failed');
    }

    function tokenIdFromQuestId(string memory questId_) public view returns (uint256) {
        QuestData storage quest = quests[questId_];
        return quest.tokenId;
    }

    /// @dev The maximum amount of coins the quest needs for the protocol fee
    function totalTransferAmount(string memory questId_) external view returns (uint256) {
        QuestData storage quest = quests[questId_];
        return quest.questFee * quest.totalParticipants;
    }

    /// @notice Pauses the Quest
    /// @dev Only the owner of the Quest can call this function.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the Quest
    /// @dev Only the owner of the Quest can call this function.
    function unPause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /// @dev Function that to withdraw the remaining coins in the contract to the owner
    /// @notice This function can only be called after all quests have ended
    function withdrawRemainingCoins() external nonReentrant {
        uint balance = address(this).balance;

        for (uint256 i = 1; i <= _tokenIdCounter.current(); i++) {
            require(quests[tokenIdToQuestId[i]].endTime < block.timestamp, 'Not all Quests have ended');
        }

        if (balance > 0) {
            (bool success, ) = owner().call{value: balance}("");
            require(success, 'withdraw remaining tokens failed');
        }

    }

    /// @dev saftey hatch function to transfer tokens sent to the contract to the contract owner.
    /// @param erc20Address_ The address of the ERC20 token to refund
    function refund(address erc20Address_) external nonReentrant {
        uint erc20Balance = IERC20(erc20Address_).balanceOf(address(this));
        if (erc20Balance > 0) IERC20(erc20Address_).safeTransfer(owner(), erc20Balance);
    }

    /// @dev returns the token uri
    /// @param tokenId_ the token id
    function uri(uint256 tokenId_)
        public
        view
        override(ERC1155Upgradeable)
        returns (string memory)
    {
        bytes memory dataURI = generateDataURI(tokenId_);
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(dataURI)));
    }

    /// @dev returns the data uri in json format
    function generateDataURI(uint256 tokenId_) internal view virtual returns (bytes memory) {
        QuestData storage quest = quests[tokenIdToQuestId[tokenId_]];
        bytes memory dataURI = abi.encodePacked(
            '{',
            '"name": "',
            collectionName,
            '",',
            '"description": "',
            quest.description,
            '",',
            '"image": "',
            tokenImage(quest.imageIPFSHash),
            '"',
            '}'
        );
        return dataURI;
    }

    function tokenImage(string memory imageIPFSHash_) internal view virtual returns (string memory) {
        return string(abi.encodePacked('ipfs://', imageIPFSHash_));
    }

    /// @dev See {IERC165-royaltyInfo}
    /// @param tokenId_ the token id
    /// @param salePrice_ the sale price
    function royaltyInfo(
        uint256 tokenId_,
        uint256 salePrice_
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        require(exists(tokenId_), 'Nonexistent token');

        uint256 royaltyPayment = (salePrice_ * 200) / 10_000; // 2% royalty
        return (owner(), royaltyPayment);
    }

    /// @dev returns true if the supplied interface id is supported
    /// @param interfaceId_ the interface id
    function supportsInterface(
        bytes4 interfaceId_
    ) public view virtual override(ERC1155Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId_ == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId_);
    }

    // Functions to receive ETH
    receive() external payable {}
    fallback() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import {OwnableUpgradeable} from './OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract QuestTerminalKey is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    IERC2981Upgradeable,
    ReentrancyGuardUpgradeable
{
    event RoyaltyFeeSet(uint256 indexed royaltyFee);
    event MinterAddressSet(address indexed minterAddress);
    event QuestFactoryAddressSet(address indexed questFactoryAddress);

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using Strings for uint256;
    using Strings for uint16;

    // storage
    CountersUpgradeable.Counter private _tokenIds;
    address public royaltyRecipient;
    address public minterAddress;
    address public questFactoryAddress;
    uint public royaltyFee;
    string public imageIPFSHash;
    string public animationUrlIPFSHash;
    mapping(uint256 => Discount) public discounts;
    struct Discount {
        uint16 percentage; //in BIPS
        uint16 usedCount;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address royaltyRecipient_,
        address minterAddress_,
        address questFactoryAddress_,
        uint royaltyFee_,
        address owner_,
        string memory imageIPFSHash_,
        string memory animationUrlIPFSHash_
    ) external initializer {
        __ERC721_init('QuestTerminalKey', 'QTK');
        __ERC721URIStorage_init();
        __Ownable_init(owner_);
        __ReentrancyGuard_init();
        royaltyRecipient = royaltyRecipient_;
        minterAddress = minterAddress_;
        questFactoryAddress = questFactoryAddress_;
        royaltyFee = royaltyFee_;
        imageIPFSHash = imageIPFSHash_;
        animationUrlIPFSHash = animationUrlIPFSHash_;
    }

    modifier onlyMinter() {
        require(msg.sender == minterAddress, 'Only minter');
        _;
    }

    modifier onlyQuestFactory() {
        require(msg.sender == questFactoryAddress, 'Only quest factory');
        _;
    }

    /// @dev modifier to check for zero address
    /// @param _address the address to check
    modifier nonZeroAddress(address _address) {
        require(_address != address(0), 'Zero address');
        _;
    }

    /// @dev set the image IPFS hash
    /// @param imageIPFSHash_ the image IPFS hash
    function setImageIPFSHash(string memory imageIPFSHash_) external onlyOwner {
        imageIPFSHash = imageIPFSHash_;
    }

    /// @dev set the animation URL IPFS hash
    /// @param animationUrlIPFSHash_ the animation URL IPFS hash
    function setAnimationUrlIPFSHash(string memory animationUrlIPFSHash_) external onlyOwner {
        animationUrlIPFSHash = animationUrlIPFSHash_;
    }

    /// @dev set the royalty recipient
    /// @param royaltyRecipient_ the address of the royalty recipient
    function setRoyaltyRecipient(address royaltyRecipient_) external nonZeroAddress(royaltyRecipient_) onlyOwner {
        royaltyRecipient = royaltyRecipient_;
    }

    /// @dev set the minter address
    /// @param minterAddress_ the address of the minter
    function setMinterAddress(address minterAddress_) external nonZeroAddress(minterAddress_) onlyOwner {
        minterAddress = minterAddress_;
        emit MinterAddressSet(minterAddress_);
    }

    /// @dev set the quest factory address
    /// @param questFactoryAddress_ the address of the quest factory
    function setQuestFactoryAddress(address questFactoryAddress_) external nonZeroAddress(questFactoryAddress_) onlyOwner {
        questFactoryAddress = questFactoryAddress_;
        emit QuestFactoryAddressSet(questFactoryAddress_);
    }

    /// @dev set the royalty fee
    /// @param royaltyFee_ the royalty fee
    function setRoyaltyFee(uint256 royaltyFee_) external onlyOwner {
        royaltyFee = royaltyFee_;
        emit RoyaltyFeeSet(royaltyFee_);
    }

    /// @dev mint a QuestTerminalKey NFT
    /// @param to_ the address to mint to
    /// @param discountPercentage_ the discount percentage
    function mint(address to_, uint16 discountPercentage_) external onlyMinter {
        require(discountPercentage_ <= 10000, 'Invalid discount percentage');

        mintWithDiscount(to_, discountPercentage_);
    }

    function bulkMintNoDiscount(address[] memory addresses_) external onlyMinter {
        for (uint256 i = 0; i < addresses_.length; i++) {
            mintWithDiscount(addresses_[i], 0);
        }
    }

    function mintWithDiscount(address to_, uint16 discountPercentage_) internal {
        _tokenIds.increment();
        uint tokenId = _tokenIds.current();
        discounts[tokenId] = Discount(discountPercentage_, 0);
        _mint(to_, tokenId);
    }

    /// @dev increment used count
    /// @param tokenId_ the token id
    function incrementUsedCount(uint tokenId_) external onlyQuestFactory {
        discounts[tokenId_].usedCount++;
    }

    /// @dev get the owned token ids of an address
    /// @param owner_ the address to get the token ids of
    function getOwnedTokenIds(address owner_) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner_);
        uint256[] memory tokenIds = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner_, i);
        }

        return tokenIds;
    }

    /// @dev before token transfer hook
    /// @param from the address from
    /// @param to the address to
    /// @param tokenId the token id
    /// @param batchSize the batch size
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    /// @dev burn a token
    /// @param tokenId the token id
    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    /// @dev returns the token uri
    /// @param tokenId_ the token id
    function tokenURI(uint256 tokenId_)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        bytes memory dataURI = generateDataURI(tokenId_);
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(dataURI)));
    }

    /// @dev returns the data uri in json format
    /// @param tokenId_ the token id
    function generateDataURI(
        uint tokenId_
    ) internal view virtual returns (bytes memory) {
        bytes memory attributes = abi.encodePacked(
            '[',
            generateAttribute('Discount Percentage BPS', discounts[tokenId_].percentage.toString()),
            ',',
            generateAttribute('Discount Used Count', discounts[tokenId_].usedCount.toString()),
            ']'
        );
        bytes memory dataURI = abi.encodePacked(
            '{',
            '"name": "Quest Terminal Key",',
            '"description": "A key that can be used to create quests in the Quest Terminal",',
            '"image": "',
            tokenImage(),
            '",',
            '"animation_url": "',
            animationUrl(),
            '",',
            '"attributes": ',
            attributes,
            '}'
        );
        return dataURI;
    }

    function tokenImage() internal view virtual returns (string memory) {
        return string(abi.encodePacked('ipfs://', imageIPFSHash));
    }

    function animationUrl() internal view virtual returns (string memory) {
        if (bytes(animationUrlIPFSHash).length == 0) {
            return '';
        }
        return string(abi.encodePacked('ipfs://', animationUrlIPFSHash));
    }

    /// @dev generates an attribute object for an ERC-721 token
    /// @param key The key for the attribute
    /// @param value The value for the attribute
    function generateAttribute(string memory key, string memory value) internal pure returns (string memory) {
        bytes memory attribute = abi.encodePacked(
            '{',
            '"trait_type": "',
            key,
            '",',
            '"value": "',
            value,
            '"',
            '}'
        );
        return string(attribute);
    }

    /// @dev See {IERC165-royaltyInfo}
    /// @param tokenId_ the token id
    /// @param salePrice_ the sale price
    function royaltyInfo(
        uint256 tokenId_,
        uint256 salePrice_
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId_), 'Nonexistent token');

        uint256 royaltyPayment = (salePrice_ * royaltyFee) / 10_000;
        return (royaltyRecipient, royaltyPayment);
    }

    /// @dev returns true if the supplied interface id is supported
    /// @param interfaceId_ the interface id
    function supportsInterface(
        bytes4 interfaceId_
    ) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId_ == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import './OwnableUpgradeable.sol';
import './ReceiptRenderer.sol';
import './interfaces/IQuestFactory.sol';
import './interfaces/IQuest.sol';

contract RabbitHoleReceipt is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    OwnableUpgradeable,
    IERC2981Upgradeable
{
    event RoyaltyFeeSet(uint256 indexed royaltyFee);
    event MinterAddressSet(address indexed minterAddress);

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    // storage
    mapping(uint => string) public questIdForTokenId;
    address public royaltyRecipient;
    address public minterAddress;
    uint public royaltyFee;
    mapping(uint => uint) public timestampForTokenId;
    ReceiptRenderer public ReceiptRendererContract;
    IQuestFactory public QuestFactoryContract;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address receiptRenderer_,
        address royaltyRecipient_,
        address minterAddress_,
        uint royaltyFee_,
        address owner_
    ) external initializer {
        __ERC721_init('RabbitHoleReceipt', 'RHR');
        __ERC721URIStorage_init();
        __Ownable_init(owner_);
        royaltyRecipient = royaltyRecipient_;
        minterAddress = minterAddress_;
        royaltyFee = royaltyFee_;
        ReceiptRendererContract = ReceiptRenderer(receiptRenderer_);
    }

    modifier onlyMinter() {
        require(msg.sender == minterAddress, 'Only minter');
        _;
    }

    /// @dev set the receipt renderer contract
    /// @param receiptRenderer_ the address of the receipt renderer contract
    function setReceiptRenderer(address receiptRenderer_) external onlyOwner {
        ReceiptRendererContract = ReceiptRenderer(receiptRenderer_);
    }

    /// @dev set the royalty recipient
    /// @param royaltyRecipient_ the address of the royalty recipient
    function setRoyaltyRecipient(address royaltyRecipient_) external onlyOwner {
        royaltyRecipient = royaltyRecipient_;
    }

    /// @dev set the quest factory contract
    /// @param questFactory_ the address of the quest factory contract
    function setQuestFactory(address questFactory_) external onlyOwner {
        QuestFactoryContract = IQuestFactory(questFactory_);
    }

    /// @dev set the minter address
    /// @param minterAddress_ the address of the minter
    function setMinterAddress(address minterAddress_) external onlyOwner {
        minterAddress = minterAddress_;
        emit MinterAddressSet(minterAddress_);
    }

    /// @dev set the royalty fee
    /// @param royaltyFee_ the royalty fee
    function setRoyaltyFee(uint256 royaltyFee_) external onlyOwner {
        royaltyFee = royaltyFee_;
        emit RoyaltyFeeSet(royaltyFee_);
    }

    /// @dev mint a receipt
    /// @param to_ the address to mint to
    /// @param questId_ the quest id
    function mint(address to_, string memory questId_) external onlyMinter {
        _tokenIds.increment();
        uint newTokenID = _tokenIds.current();
        questIdForTokenId[newTokenID] = questId_;
        timestampForTokenId[newTokenID] = block.timestamp;
        _safeMint(to_, newTokenID);
    }

    /// @dev get the token ids for a quest owned by an address
    /// @param questId_ the quest id
    /// @param claimingAddress_ the address claiming to own the tokens
    function getOwnedTokenIdsOfQuest(
        string memory questId_,
        address claimingAddress_
    ) external view returns (uint[] memory) {
        uint msgSenderBalance = balanceOf(claimingAddress_);
        uint[] memory tokenIdsForQuest = new uint[](msgSenderBalance);
        uint foundTokens = 0;
        bytes32 QUEST_ID = keccak256(bytes(questId_));

        for (uint i = 0; i < msgSenderBalance; i++) {
            uint tokenId = tokenOfOwnerByIndex(claimingAddress_, i);
            if (keccak256(bytes(questIdForTokenId[tokenId])) == QUEST_ID) {
                tokenIdsForQuest[i] = tokenId;
                foundTokens++;
            }
        }

        uint[] memory filteredTokens = new uint[](foundTokens);
        uint filterTokensIndexTracker = 0;

        for (uint i = 0; i < msgSenderBalance; i++) {
            if (tokenIdsForQuest[i] > 0) {
                filteredTokens[filterTokensIndexTracker] = tokenIdsForQuest[i];
                filterTokensIndexTracker++;
            }
        }
        return filteredTokens;
    }

    /// @dev burn a receipt
    /// @param tokenId_ the token id
    function _burn(uint256 tokenId_) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId_);
    }

    /// @dev before token transfer hook, called before any token transfer
    /// @param from_ the address from
    /// @param to_ the address to
    /// @param tokenId_ the token id
    /// @param batchSize_ the batch size
    function _beforeTokenTransfer(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 batchSize_
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from_, to_, tokenId_, batchSize_);
    }

    /// @dev return the token uri, this delegates to the receipt renderer contract
    function tokenURI(
        uint tokenId_
    ) public view virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        require(_exists(tokenId_), 'ERC721URIStorage: URI query for nonexistent token');
        require(QuestFactoryContract != IQuestFactory(address(0)), 'QuestFactory not set');

        string memory questId = questIdForTokenId[tokenId_];
        (address questAddress, uint totalParticipants, ) = QuestFactoryContract.questInfo(questId);
        IQuest questContract = IQuest(questAddress);

        bool claimed = questContract.isClaimed(tokenId_);
        uint rewardAmount = questContract.getRewardAmount();
        address rewardAddress = questContract.getRewardToken();

        return
            ReceiptRendererContract.generateTokenURI(
                tokenId_,
                questId,
                totalParticipants,
                claimed,
                rewardAmount,
                rewardAddress
            );
    }

    /// @dev get the current token id
    function getTokenId() public view returns (uint) {
        return _tokenIds.current();
    }

    /// @dev See {IERC165-royaltyInfo}
    /// @param tokenId_ the token id
    /// @param salePrice_ the sale price
    function royaltyInfo(
        uint256 tokenId_,
        uint256 salePrice_
    ) external view override returns (address receiver, uint256 royaltyAmount) {
        require(_exists(tokenId_), 'Nonexistent token');

        uint256 royaltyPayment = (salePrice_ * royaltyFee) / 10_000;
        return (royaltyRecipient, royaltyPayment);
    }

    /// @dev returns true if the supplied interface id is supported
    /// @param interfaceId_ the interface id
    function supportsInterface(
        bytes4 interfaceId_
    ) public view virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId_ == type(IERC2981Upgradeable).interfaceId || super.supportsInterface(interfaceId_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

/// @title ReceiptRenderer
/// @author RabbitHole.gg
/// @dev This contract is used to render on-chain data for RabbitHole Receipts (ERC-721 standard)
contract ReceiptRenderer {
    using Strings for uint256;
    string private constant GREEN_SVG = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="623" height="848"><defs><radialGradient id="A" cx="18.03" cy="-23.85" r="1" gradientTransform="matrix(-750 4.01 -3.89 -727.99 13738.75 -17063.51)" gradientUnits="userSpaceOnUse"><stop offset=".01" stop-color="#6aff67" stop-opacity=".39"/><stop offset=".14" stop-color="#59ff3e" stop-opacity=".22"/><stop offset=".3" stop-color="#4ad433" stop-opacity=".52"/><stop offset=".4" stop-color="#3eb42b" stop-opacity="0"/><stop offset="1" stop-opacity="0"/></radialGradient><radialGradient id="B" cx="17.91" cy="-23.86" r="1" gradientTransform="matrix(8,333,-579.59,13.92,-13669.05,-5581.04)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#59ff3e" stop-opacity=".35"/><stop offset="1" stop-opacity="0"/></radialGradient><radialGradient xlink:href="#B" id="C" cx="18.09" cy="-23.91" gradientTransform="matrix(0,-345,877.77,0,21305.27,7045.5)"/><radialGradient xlink:href="#B" id="D" cx="17.93" cy="-23.91" gradientTransform="matrix(268,-2,8.57,1148.65,-4548.99,27879.6)"/><radialGradient id="E" cx="18.07" cy="-23.87" r="1" gradientTransform="matrix(-242,0,0,-1277.43,4934.5,-30115.86)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#59ff3e" stop-opacity=".42"/><stop offset="1" stop-opacity="0"/></radialGradient><path id="F" d="M399.6 66H225.4A22 22 0 0 1 204 83h-39a22 22 0 0 1-21.4-17h-44L66 99.6V781h453.5l36.5-36.5v-641L518.5 66h-37.1A22 22 0 0 1 460 83h-39a22 22 0 0 1-21.4-17Z"/></defs><path d="M.5.5h622v847H.5z" stroke="#000" stroke-miterlimit="10"/><path d="M400.1 66.5H225.9a22 22 0 0 1-21.4 17h-39a22 22 0 0 1-21.4-17h-44l-33.6 33.6v681.4H520l36.5-36.5V104L519 66.5h-37.1a22 22 0 0 1-21.4 17h-39a22 22 0 0 1-21.4-17z" fill-opacity=".2"/><g transform="translate(.5 .5)"><use xlink:href="#F" fill="url(#A)"/><use xlink:href="#F" fill="url(#B)"/><use xlink:href="#F" fill="url(#C)"/><use xlink:href="#F" fill="url(#D)"/><use xlink:href="#F" fill="url(#E)"/></g><g fill="none" stroke="#42ff00" stroke-width="2"><path d="M204.5 84.5a23 23 0 0 0 22.2-17h172.6a23 23 0 0 0 22.2 17h39a23 23 0 0 0 22.2-17h35.9l36.9 36.9v640.2l-35.9 35.9H67.5v-680l33-33h42.8a23 23 0 0 0 22.2 17z" stroke-opacity=".97"/><path d="M312 305.3V68.5m-7.5 236.3V86.2L286 67.5m33.5 237.3V86.2L338 67.5M297.5 305V89.7l-22-22.2m52 237.3v-215l22-22.3M313 399.2v170.6m7.5-170.6v152.9l18.5 18.7m-33.5-171.6v152.9L287 570.8m40.5-171.3v149l22 22.2m-52-171.7v149.5l-22 22.2M209 602c0-17.397 14.103-31.5 31.5-31.5h140c17.397 0 31.5 14.103 31.5 31.5s-14.103 31.5-31.5 31.5h-140c-17.397 0-31.5-14.103-31.5-31.5zm276.3-260.7v12m0 0v12m0-12h-12m12 0h12m-12 7a7 7 0 1 1 0-14 7 7 0 1 1 0 14zm-353-19v12m0 0v12m0-12h-12m12 0h12m-12 7a7 7 0 1 1 0-14 7 7 0 1 1 0 14zm353 237v12m0 0v12m0-12h-12m12 0h12m-12 7a7 7 0 1 1 0-14 7 7 0 1 1 0 14zm-353-19v12m0 0v12m0-12h-12m12 0h12m-12 7a7 7 0 1 1 0-14 7 7 0 1 1 0 14z" stroke-opacity=".97"/></g><path d="M225.2 720.3v21h4.1v-9.1h3.6c1.2 0 1.9 1.3 1.9 4v5.1h3.8v-6.6c0-2.4-1-3.4-2.7-4 1.9-.8 2.6-2.5 2.6-4.6 0-4.1-1.4-5.8-4.7-5.8zm4.1 2.6h3.6c1.2 0 1.9 1.3 1.9 3.4s-.7 3.3-1.9 3.3h-3.6zm13.9-2.6v21h12.9v-2.6h-8.8V732h6.4v-2.5h-6.4v-6.6h8.8v-2.6zm17.5 0v21h9.4c2.4 0 4-2.5 4-5.7v-9.5c0-3.3-1.7-5.8-4-5.8zm4 2.6h3.7c1.1 0 1.8 1.5 1.8 3.2v9.5c0 1.6-.7 3.1-1.8 3.1h-3.7zm13.9-2.6v21h12.9v-2.6h-8.8V732h6.4v-2.5h-6.4v-6.6h8.8v-2.6zm17.7 0v21h12.9v-2.6h-8.8V732h6.4v-2.5h-6.4v-6.6h8.8v-2.6zm17.4 0v21h3.1v-13.2l2.1 13.2h3.1l2.3-13.3v13.3h2.9v-21h-4l-2.7 16-2.7-16zm27.5 21h4l-4.4-21h-5.3l-4.3 21h4.1l.6-4.4h4.6zm-3.2-18.4h.4l1.7 11.4h-3.8zm11-2.6v21h9.8c2.4 0 4-2.6 4-5.9s-.9-4.2-2.1-5c1.2-.9 1.7-2.3 1.7-4.3s-1.6-5.8-4-5.8zm4.1 2.6h3.6c1.2 0 1.9 1.2 1.9 3.3s-.7 3.1-1.9 3.1h-3.6zm0 9h4c1.1 0 1.8 1.5 1.8 3.4s-.7 3.4-1.8 3.4h-4zm13.8-11.6v21h13.4v-2.6H371v-18.4zm18 0v21h12.9v-2.6H389V732h6.4v-2.5H389v-6.6h8.8v-2.6z" fill="#f2f2f2"/><path d="M245.6 604.7v7.5H242v-20.1h8.3a8.67 8.67 0 0 1 5.4 1.6 6.11 6.11 0 0 1 1.8 4.7 5.7 5.7 0 0 1-4.1 5.7l4.9 8.1h-4l-4.4-7.5zm0-9.6v6.6h4.3a4.6 4.6 0 0 0 3.1-.8 3.59 3.59 0 0 0 0-5 4.6 4.6 0 0 0-3.1-.8zm26.6 17.1h-3.4c0-.4-.1-.8-.1-1.2a3.7 3.7 0 0 1-.1-1.1 3.89 3.89 0 0 1-1.7 1.9 6.12 6.12 0 0 1-2.9.7 4.51 4.51 0 0 1-3.3-1.2 3.5 3.5 0 0 1-1.3-3 3.7 3.7 0 0 1 1.2-2.9 6.65 6.65 0 0 1 3.8-1.4l4.1-.5v-.7a2.49 2.49 0 0 0-.7-1.9 2.72 2.72 0 0 0-1.9-.7 2.37 2.37 0 0 0-1.8.6 2.3 2.3 0 0 0-.8 1.6H260a4.49 4.49 0 0 1 1.8-3.5 6.35 6.35 0 0 1 4.2-1.3 6 6 0 0 1 4.4 1.4 5.29 5.29 0 0 1 1.5 4.1v7.5zm-9.4-4.1a1.7 1.7 0 0 0 .6 1.4 2.5 2.5 0 0 0 1.6.5 3.68 3.68 0 0 0 2.5-.9 3.22 3.22 0 0 0 1-2.5v-.8l-3.1.3a5.09 5.09 0 0 0-2 .7 1.49 1.49 0 0 0-.6 1.3zm20.2 4.4a5.21 5.21 0 0 1-2.7-.7 4.41 4.41 0 0 1-1.7-1.9v2.3h-3.4v-20.7h3.5v8.7a3.89 3.89 0 0 1 1.7-1.9 4.59 4.59 0 0 1 2.6-.7 5.61 5.61 0 0 1 4.4 2 9.42 9.42 0 0 1 0 10.8 5.4 5.4 0 0 1-4.4 2.1zm-1-12.3a3 3 0 0 0-2.5 1.2 5.68 5.68 0 0 0-.9 3.4v.5a5.92 5.92 0 0 0 .9 3.4 3 3 0 0 0 2.5 1.2 3.39 3.39 0 0 0 2.7-1.3 6.4 6.4 0 0 0 .9-3.6 6.08 6.08 0 0 0-.9-3.5 3.1 3.1 0 0 0-2.7-1.3zm17.4 12.3a5 5 0 0 1-2.7-.7 4.41 4.41 0 0 1-1.7-1.9v2.3h-3.4v-20.7h3.5v8.7a3.89 3.89 0 0 1 1.7-1.9 4.59 4.59 0 0 1 2.6-.7 5.61 5.61 0 0 1 4.4 2 9.42 9.42 0 0 1 0 10.8 5.4 5.4 0 0 1-4.4 2.1zm-1-12.3a3 3 0 0 0-2.5 1.2 5.68 5.68 0 0 0-.9 3.4v.5a5.92 5.92 0 0 0 .9 3.4 3 3 0 0 0 2.5 1.2 3.5 3.5 0 0 0 2.7-1.3 6.4 6.4 0 0 0 .9-3.6 6.08 6.08 0 0 0-.9-3.5 3.21 3.21 0 0 0-2.7-1.3zm13.2-4.7h-3.7V592h3.7zm-.2 16.7H308v-14.3h3.4zm9-2.7h.9l.9-.2v2.8l-1.4.3h-1.4a4.41 4.41 0 0 1-3.2-1 4.21 4.21 0 0 1-1.1-3.1v-7.8h-1.9v-2.6h1.9v-3.6h3.5v3.6h3.3v2.6h-3.3v7.2a2 2 0 0 0 .4 1.4 1.82 1.82 0 0 0 1.4.4zm7.9 2.7h-3.6v-20.1h3.6v8.4h10v-8.4h3.5v20.1h-3.5v-8.7h-10zm23.1-14.6a6.48 6.48 0 0 1 5 2 8.77 8.77 0 0 1 0 10.9 6.69 6.69 0 0 1-5 2 6.89 6.89 0 0 1-5.1-2 8.77 8.77 0 0 1 0-10.9 6.63 6.63 0 0 1 5.1-2zm0 2.6a3.22 3.22 0 0 0-2.6 1.3 5.77 5.77 0 0 0-.9 3.5 6.4 6.4 0 0 0 .9 3.6 3.1 3.1 0 0 0 2.6 1.2 2.9 2.9 0 0 0 2.5-1.2 5.68 5.68 0 0 0 1-3.6 5.4 5.4 0 0 0-1-3.5 3 3 0 0 0-2.5-1.3zm12.9-8.7v20.7h-3.5v-20.7zm12.5 16.2h3.2a5.19 5.19 0 0 1-2.2 3.5 6.07 6.07 0 0 1-4.1 1.3 6.88 6.88 0 0 1-5-2 8.77 8.77 0 0 1 0-10.9 6.69 6.69 0 0 1 5-2 5.49 5.49 0 0 1 4.6 2 7.29 7.29 0 0 1 1.7 5.2v1.1h-9.9a4.62 4.62 0 0 0 1.1 2.9 3.32 3.32 0 0 0 2.5 1.1 2.9 2.9 0 0 0 1.9-.6 3.41 3.41 0 0 0 1.2-1.6zm-3.1-7.5a3 3 0 0 0-2.3.9 4.55 4.55 0 0 0-1.2 2.5h6.5a3.61 3.61 0 0 0-.8-2.4 2.7 2.7 0 0 0-2.2-1zm121.1-431.6c12.565-4.904 20.136-17.775 18.317-31.14s-12.555-23.744-25.973-25.112-26.027 6.634-30.504 19.357.343 26.857 11.661 34.194a3.2 3.2 0 0 1 2.8-1.7c.2 0 .5-.3.4-.5a21.47 21.47 0 0 1-.7-5.1c0-10.7 8.1-19.3 18.1-19.3a1.92 1.92 0 0 0 1.6-1.1v-.2a2.6 2.6 0 0 0-1.6-3.3 18.91 18.91 0 0 1-13.7-14.1.81.81 0 0 1 1.4-.8l26.4 20.1a1.08 1.08 0 0 1 .4.9 18.25 18.25 0 0 0 .1 7.1.79.79 0 0 1-.3.9 8.1 8.1 0 0 1-8.6.5 1.38 1.38 0 0 0-1.1-.2 1.51 1.51 0 0 0-1.1 1.4v12.2a.9.9 0 0 1-.9.9h-1.6a.9.9 0 0 1-.9-.9 8.4 8.4 0 0 0-8.1-7.4h-.8a.6.6 0 1 0 .1 1.2 7.3 7.3 0 0 1 6 7.3 7.52 7.52 0 0 1-.2 1.5.9.9 0 0 0 .68 1.08h7.02a1.21 1.21 0 0 1 .5.5 2.58 2.58 0 0 1 .6 1.72zM467.4 137a.6.6 0 0 1 .4-1.1h16.6c.304-.138.662-.004.8.3s.004.662-.3.8a14.56 14.56 0 0 1-8.8 3.1 14 14 0 0 1-8.7-3.1zm31.5 5.3a1.6 1.6 0 0 1-3.197-.131 1.6 1.6 0 0 1 1.597-1.569 1.7 1.7 0 0 1 1.6 1.7z" fill="#dae0ff"/><text alignment-baseline="middle" text-anchor="middle" transform="translate(311 370.9)" font-size="44" fill="#fff" font-family="ArialMT, Arial">';
    string private constant PURPLE_SVG = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="623" height="848" xmlns:v="https://vecta.io/nano"><defs><radialGradient id="A" cx="18.03" cy="-23.85" r="1" gradientTransform="matrix(-778.44 0 0 -755.59 14341.92 -17655.24)" xlink:href="#G"><stop offset=".01" stop-color="#de80ff" stop-opacity=".39"/><stop offset=".14" stop-color="#ec7bff" stop-opacity=".22"/><stop offset=".27" stop-color="#f25aff" stop-opacity=".48"/><stop offset="1" stop-color="#1c231b" stop-opacity="0"/></radialGradient><radialGradient id="B" cx="17.91" cy="-23.86" r="1" gradientTransform="matrix(8,333,-579.59,13.92,-13669.05,-5581.04)" xlink:href="#G"><stop offset="0" stop-color="#8f00ff" stop-opacity=".51"/><stop offset="1" stop-color="#1c231b" stop-opacity="0"/></radialGradient><radialGradient id="C" cx="18.09" cy="-23.91" r="1" gradientTransform="matrix(0,-345,877.77,0,21305.27,7045.5)" xlink:href="#G"><stop offset="0" stop-color="#c13fff"/><stop offset="1" stop-color="#1c231b" stop-opacity="0"/></radialGradient><radialGradient id="D" cx="17.93" cy="-23.91" r="1" gradientTransform="matrix(268,-2,8.57,1148.65,-4548.99,27879.6)" xlink:href="#G"><stop offset="0" stop-color="#b946ff"/><stop offset="1" stop-color="#1c231b" stop-opacity="0"/></radialGradient><radialGradient id="E" cx="18.07" cy="-23.87" r="1" gradientTransform="matrix(-242,0,0,-1277.43,4934.5,-30115.86)" xlink:href="#G"><stop offset="0" stop-color="#dd0fff" stop-opacity=".91"/><stop offset="1" stop-color="#1c231b" stop-opacity="0"/></radialGradient><path id="F" d="M399.6 66H225.4A22 22 0 0 1 204 83h-39a22 22 0 0 1-21.4-17h-44L66 99.6V781h453.5l36.5-36.5v-641L518.5 66h-37.1A22 22 0 0 1 460 83h-39a22 22 0 0 1-21.4-17Z"/><linearGradient id="G" gradientUnits="userSpaceOnUse"/></defs><path d="M.5.5h622v847H.5z" stroke="#000" stroke-miterlimit="10"/><g fill-rule="evenodd"><path d="M400 66.5H225.8a22 22 0 0 1-21.4 17h-39a22 22 0 0 1-21.4-17h-44l-33.6 33.6v681.4h453.5l36.5-36.5V104l-37.5-37.5h-37.1a22 22 0 0 1-21.4 17h-39a22 22 0 0 1-21.4-17z" fill="#0c0b0f" fill-opacity=".26"/><g transform="translate(.4 .5)"><use xlink:href="#F" fill-opacity=".99" fill="url(#A)"/><use xlink:href="#F" fill-opacity=".5" fill="url(#B)"/><use xlink:href="#F" fill-opacity=".5" fill="url(#C)"/><use xlink:href="#F" fill-opacity=".5" fill="url(#D)"/><use xlink:href="#F" fill-opacity=".5" fill="url(#E)"/></g></g><g fill="none" stroke="#ad86ff" stroke-width="2"><path d="M204.4 84.5a23 23 0 0 0 22.2-17h172.6a23 23 0 0 0 22.2 17h39a23 23 0 0 0 22.2-17h35.9l36.9 36.9v640.2l-35.9 35.9H67.4v-680l33-33h42.8a23 23 0 0 0 22.2 17z"/><path d="M311.9 305.3V68.5m-7.5 236.3V86.2l-18.5-18.7m33.5 237.3V86.2l18.5-18.7M297.4 305V89.7l-22-22.2m52 237.3v-215l22-22.3m-36.5 331.7v170.6m7.5-170.6v152.9l18.5 18.7m-33.5-171.6v152.9l-18.5 18.7m40.5-171.3v149l22 22.2m-52-171.7v149.5l-22 22.2M208.9 602c0-17.397 14.103-31.5 31.5-31.5h140c17.397 0 31.5 14.103 31.5 31.5s-14.103 31.5-31.5 31.5h-140c-17.397 0-31.5-14.103-31.5-31.5zm276.8-260.7v12m0 0v12m0-12h-12m12 0h12m-12 7a7 7 0 1 1 0-14 7 7 0 1 1 0 14zm-353-19v12m0 0v12m0-12h-12m12 0h12m-12 7a7 7 0 1 1 0-14 7 7 0 1 1 0 14zm353 237v12m0 0v12m0-12h-12m12 0h12m-12 7a7 7 0 1 1 0-14 7 7 0 1 1 0 14zm-353-19v12m0 0v12m0-12h-12m12 0h12m-12 7a7 7 0 1 1 0-14 7 7 0 1 1 0 14z"/></g><path d="M242.7 714.5v21h4v-9.1h3.6c1.3 0 1.9 1.3 1.9 4v5.1h3.9v-6.6a3.7 3.7 0 0 0-2.8-4c2-.8 2.7-2.5 2.7-4.6 0-4.1-1.5-5.8-4.7-5.8zm4 2.6h3.7c1.2 0 1.9 1.3 1.9 3.4s-.7 3.3-1.9 3.3h-3.7zm14-2.6v21h12.8v-2.6h-8.7v-6.7h6.4v-2.5h-6.4v-6.6h8.7v-2.6zm17.4 0v21h9.5c2.4 0 3.9-2.5 3.9-5.7v-9.5c0-3.3-1.6-5.8-3.9-5.8zm4.1 2.6h3.7c1.1 0 1.8 1.5 1.8 3.2v9.5c0 1.6-.7 3.1-1.8 3.1h-3.7zm13.9-2.6v21H309v-2.6h-8.8v-6.7h6.4v-2.5h-6.4v-6.6h8.8v-2.6zm17.7 0v21h12.9v-2.6h-8.8v-6.7h6.4v-2.5h-6.4v-6.6h8.8v-2.6zm17.4 0v21h3v-13.2l2.1 13.2h3.2l2.3-13.3v13.3h2.9v-21h-4l-2.7 16-2.8-16zm18 0v21h12.9v-2.6h-8.8v-6.7h6.4v-2.5h-6.4v-6.6h8.8v-2.6zm17.5 0v21h9.4c2.4 0 4-2.5 4-5.7v-9.5c0-3.3-1.6-5.8-4-5.8zm4 2.6h3.7c1.2 0 1.9 1.5 1.9 3.2v9.5c0 1.6-.7 3.1-1.9 3.1h-3.7zM245.5 604.7v7.5h-3.6v-20.1h8.3a8.67 8.67 0 0 1 5.4 1.6 6.11 6.11 0 0 1 1.8 4.7 5.7 5.7 0 0 1-4.1 5.7l4.9 8.1h-4l-4.4-7.5zm0-9.6v6.6h4.3a4.6 4.6 0 0 0 3.1-.8 3.59 3.59 0 0 0 0-5 4.6 4.6 0 0 0-3.1-.8zm26.6 17.1h-3.4c0-.4-.1-.8-.1-1.2a3.7 3.7 0 0 1-.1-1.1 3.89 3.89 0 0 1-1.7 1.9 6.12 6.12 0 0 1-2.9.7 4.51 4.51 0 0 1-3.3-1.2 3.5 3.5 0 0 1-1.3-3 3.7 3.7 0 0 1 1.2-2.9 6.65 6.65 0 0 1 3.8-1.4l4.1-.5v-.7a2.49 2.49 0 0 0-.7-1.9 2.72 2.72 0 0 0-1.9-.7 2.37 2.37 0 0 0-1.8.6 2.3 2.3 0 0 0-.8 1.6h-3.3a4.49 4.49 0 0 1 1.8-3.5 6.35 6.35 0 0 1 4.2-1.3 6 6 0 0 1 4.4 1.4 5.29 5.29 0 0 1 1.5 4.1v7.5zm-9.4-4.1a1.7 1.7 0 0 0 .6 1.4 2.5 2.5 0 0 0 1.6.5 3.68 3.68 0 0 0 2.5-.9 3.22 3.22 0 0 0 1-2.5v-.8l-3.1.3a5.09 5.09 0 0 0-2 .7 1.49 1.49 0 0 0-.6 1.3zm20.2 4.4a5.21 5.21 0 0 1-2.7-.7 4.41 4.41 0 0 1-1.7-1.9v2.3h-3.4v-20.7h3.5v8.7a3.89 3.89 0 0 1 1.7-1.9 4.59 4.59 0 0 1 2.6-.7 5.61 5.61 0 0 1 4.4 2 9.42 9.42 0 0 1 0 10.8 5.4 5.4 0 0 1-4.4 2.1zm-1-12.3a3 3 0 0 0-2.5 1.2 5.68 5.68 0 0 0-.9 3.4v.5a5.92 5.92 0 0 0 .9 3.4 3 3 0 0 0 2.5 1.2 3.39 3.39 0 0 0 2.7-1.3 6.4 6.4 0 0 0 .9-3.6 6.08 6.08 0 0 0-.9-3.5 3.1 3.1 0 0 0-2.7-1.3zm17.4 12.3a5 5 0 0 1-2.7-.7 4.41 4.41 0 0 1-1.7-1.9v2.3h-3.4v-20.7h3.5v8.7a3.89 3.89 0 0 1 1.7-1.9 4.59 4.59 0 0 1 2.6-.7 5.61 5.61 0 0 1 4.4 2 9.42 9.42 0 0 1 0 10.8 5.4 5.4 0 0 1-4.4 2.1zm-1-12.3a3 3 0 0 0-2.5 1.2 5.68 5.68 0 0 0-.9 3.4v.5a5.92 5.92 0 0 0 .9 3.4 3 3 0 0 0 2.5 1.2 3.5 3.5 0 0 0 2.7-1.3 6.4 6.4 0 0 0 .9-3.6 6.08 6.08 0 0 0-.9-3.5 3.21 3.21 0 0 0-2.7-1.3zm13.2-4.7h-3.7V592h3.7zm-.2 16.7h-3.4v-14.3h3.4zm9-2.7h.9l.9-.2v2.8l-1.4.3h-1.4a4.41 4.41 0 0 1-3.2-1 4.21 4.21 0 0 1-1.1-3.1v-7.8h-1.9v-2.6h1.9v-3.6h3.5v3.6h3.3v2.6h-3.3v7.2a2 2 0 0 0 .4 1.4 1.82 1.82 0 0 0 1.4.4zm7.9 2.7h-3.6v-20.1h3.6v8.4h10v-8.4h3.5v20.1h-3.5v-8.7h-10zm23.1-14.6a6.48 6.48 0 0 1 5 2 8.77 8.77 0 0 1 0 10.9 6.69 6.69 0 0 1-5 2 6.89 6.89 0 0 1-5.1-2 8.77 8.77 0 0 1 0-10.9 6.63 6.63 0 0 1 5.1-2zm0 2.6a3.22 3.22 0 0 0-2.6 1.3 5.77 5.77 0 0 0-.9 3.5 6.4 6.4 0 0 0 .9 3.6 3.1 3.1 0 0 0 2.6 1.2 2.9 2.9 0 0 0 2.5-1.2 5.68 5.68 0 0 0 1-3.6 5.4 5.4 0 0 0-1-3.5 3 3 0 0 0-2.5-1.3zm12.9-8.7v20.7h-3.5v-20.7zm12.5 16.2h3.2a5.19 5.19 0 0 1-2.2 3.5 6.07 6.07 0 0 1-4.1 1.3 6.88 6.88 0 0 1-5-2 8.77 8.77 0 0 1 0-10.9 6.69 6.69 0 0 1 5-2 5.49 5.49 0 0 1 4.6 2 7.29 7.29 0 0 1 1.7 5.2v1.1H370a4.62 4.62 0 0 0 1.1 2.9 3.32 3.32 0 0 0 2.5 1.1 2.9 2.9 0 0 0 1.9-.6 3.41 3.41 0 0 0 1.2-1.6zm-3.1-7.5a3 3 0 0 0-2.3.9 4.55 4.55 0 0 0-1.2 2.5h6.5a3.61 3.61 0 0 0-.8-2.4 2.7 2.7 0 0 0-2.2-1zm121.1-431.6c12.565-4.904 20.136-17.775 18.317-31.14s-12.555-23.744-25.973-25.112-26.027 6.634-30.504 19.357.343 26.857 11.661 34.194a3.2 3.2 0 0 1 2.8-1.7c.2 0 .5-.3.4-.5a21.47 21.47 0 0 1-.7-5.1c0-10.7 8.1-19.3 18.1-19.3a1.92 1.92 0 0 0 1.6-1.1v-.2a2.6 2.6 0 0 0-1.6-3.3 18.91 18.91 0 0 1-13.7-14.1.81.81 0 0 1 1.4-.8l26.4 20.1a1.08 1.08 0 0 1 .4.9 18.25 18.25 0 0 0 .1 7.1.79.79 0 0 1-.3.9 8.1 8.1 0 0 1-8.6.5 1.38 1.38 0 0 0-1.1-.2 1.51 1.51 0 0 0-1.1 1.4v12.2a.9.9 0 0 1-.9.9h-1.6a.9.9 0 0 1-.9-.9 8.4 8.4 0 0 0-8.1-7.4h-.8a.6.6 0 1 0 .1 1.2 7.3 7.3 0 0 1 6 7.3 7.52 7.52 0 0 1-.2 1.5.9.9 0 0 0 .68 1.08h7.02a1.21 1.21 0 0 1 .5.5 2.58 2.58 0 0 1 .6 1.72zM467.3 137a.6.6 0 0 1 .4-1.1h16.6c.304-.138.662-.004.8.3s.004.662-.3.8a14.56 14.56 0 0 1-8.8 3.1 14 14 0 0 1-8.7-3.1zm31.5 5.3a1.6 1.6 0 0 1-3.197-.131 1.6 1.6 0 0 1 1.597-1.569 1.7 1.7 0 0 1 1.6 1.7z" fill="#dae0ff"/><text alignment-baseline="middle" text-anchor="middle" transform="translate(311 370.9)" font-size="44" fill="#fff" font-family="ArialMT, Arial">';

    /// @dev generates the tokenURI for a given ERC-721 token ID
    /// @param tokenId_ The token id to generate the URI for
    /// @param questId_ The questId tied to the tokenId
    /// @param totalParticipants_ The total number of participants in the quest
    /// @param claimed_ Whether or not the token has been claimed
    /// @param rewardAmount_ The amount of reward tokens that the user is eligible for
    /// @param rewardAddress_ The address of the reward token
    /// @return encoded JSON following the generic OpenSea metadata standard
    function generateTokenURI(
        uint tokenId_,
        string memory questId_,
        uint totalParticipants_,
        bool claimed_,
        uint rewardAmount_,
        address rewardAddress_
    ) external view virtual returns (string memory) {
        bytes memory dataURI = generateDataURI(
            tokenId_,
            questId_,
            totalParticipants_,
            claimed_,
            rewardAmount_,
            rewardAddress_
        );
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(dataURI)));
    }

    function generateDataURI(
        uint tokenId_,
        string memory questId_,
        uint totalParticipants_,
        bool claimed_,
        uint rewardAmount_,
        address rewardAddress_
    ) internal view virtual returns (bytes memory) {
        string memory tokenIdString = tokenId_.toString();
        string memory humanRewardAmountString = this.humanRewardAmount(rewardAmount_, rewardAddress_);
        string memory rewardTokenSymbol = this.symbolForAddress(rewardAddress_);

        bytes memory attributes = abi.encodePacked(
            '[',
            generateAttribute('Quest ID', questId_),
            ',',
            generateAttribute('Token ID', tokenIdString),
            ',',
            generateAttribute('Total Participants', totalParticipants_.toString()),
            ',',
            generateAttribute('Claimed', claimed_ ? 'true' : 'false'),
            ',',
            generateAttribute('Reward Amount', humanRewardAmountString),
            ',',
            generateAttribute('Reward Address', Strings.toHexString(uint160(rewardAddress_), 20)),
            ']'
        );
        bytes memory dataURI = abi.encodePacked(
            '{',
            '"name": "RabbitHole.gg Receipt #',
            tokenIdString,
            '",',
            '"description": "RabbitHole.gg Receipts are used to claim rewards from completed quests.",',
            '"image": "',
            generateSVG(claimed_, humanRewardAmountString, rewardTokenSymbol),
            '",',
            '"attributes": ',
            attributes,
            '}'
        );
        return dataURI;
    }

    /// @dev generates an attribute object for an ERC-721 token
    /// @param key The key for the attribute
    /// @param value The value for the attribute
    function generateAttribute(string memory key, string memory value) internal pure returns (string memory) {
        bytes memory attribute = abi.encodePacked(
            '{',
            '"trait_type": "',
            key,
            '",',
            '"value": "',
            value,
            '"',
            '}'
        );
        return string(attribute);
    }

    /// @dev generates the on-chain SVG for an ERC-721 token ID
    /// @param claimed_ Whether or not the token has been claimed
    /// @param rewardAmountString_ The string decimal of reward tokens that the user is eligible for
    /// @param rewardTokenSymbol_ The symbol of the reward token
    /// @return base64 encoded SVG image
    function generateSVG(bool claimed_, string memory rewardAmountString_, string memory rewardTokenSymbol_) internal pure returns (string memory) {
        bytes memory svg = abi.encodePacked(
            claimed_ ? PURPLE_SVG : GREEN_SVG,
            rewardAmountString_,
            ' ',
            rewardTokenSymbol_,
            '</text></svg>'
        );
        return string(abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(svg)));
    }

    /// @dev Returns a human readable reward amount
    /// @param rewardAmount_ The reward amount
    /// @param rewardAddress_ The reward address
    function humanRewardAmount(uint rewardAmount_, address rewardAddress_) external view returns (string memory) {
        uint8 decimals;

        if (rewardAddress_ == address(0)) {
            decimals = 18;
        } else {
            decimals = ERC20(rewardAddress_).decimals();
        }

        return decimalString(rewardAmount_, decimals, false);
    }

    /// @dev Returns the symbol for a token address
    /// @param tokenAddress_ The reward address
    function symbolForAddress(address tokenAddress_) external view returns (string memory) {
        string memory symbol;

        if (tokenAddress_ == address(0)) {
            symbol = 'ETH';
        } else {
            symbol = ERC20(tokenAddress_).symbol();
        }

        return symbol;
    }

    /// @notice From https://gist.github.com/wilsoncusack/d2e680e0f961e36393d1bf0b6faafba7
    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
        // true if string should include "%"
        bool isPercent;
    }

    function decimalString(uint256 number, uint8 decimals, bool isPercent) internal pure returns (string memory){
        uint8 percentBufferOffset = isPercent ? 1 : 0;
        uint256 tenPowDecimals = 10 ** decimals;
        uint256 temp = number;
        uint8 digits;
        uint8 numSigfigs;
        while (temp != 0) {
            if (numSigfigs > 0) {
                // count all digits preceding least significant figure
                numSigfigs++;
            } else if (temp % 10 != 0) {
                numSigfigs++;
            }
            digits++;
            temp /= 10;
        }

        DecimalStringParams memory params;
        params.isPercent = isPercent;
        if ((digits - numSigfigs) >= decimals) {
            // no decimals, ensure we preserve all trailing zeros
            params.sigfigs = number / tenPowDecimals;
            params.sigfigIndex = digits - decimals;
            params.bufferLength = params.sigfigIndex + percentBufferOffset;
        } else {
            // chop all trailing zeros for numbers with decimals
            params.sigfigs = number / (10 ** (digits - numSigfigs));
            if (tenPowDecimals > number) {
                // number is less tahn one
                // in this case, there may be leading zeros after the decimal place
                // that need to be added

                // offset leading zeros by two to account for leading '0.'
                params.zerosStartIndex = 2;
                params.zerosEndIndex = decimals - digits + 2;
                params.sigfigIndex = numSigfigs + params.zerosEndIndex;
                params.bufferLength = params.sigfigIndex + percentBufferOffset;
                params.isLessThanOne = true;
            } else {
                // In this case, there are digits before and
                // after the decimal place
                params.sigfigIndex = numSigfigs + 1;
                params.decimalIndex = digits - decimals + 1;
            }
        }
        params.bufferLength = params.sigfigIndex + percentBufferOffset;
        return generateDecimalString(params);
    }

    function generateDecimalString(DecimalStringParams memory params) private pure returns (string memory) {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = '%';
        }
        if (params.isLessThanOne) {
            buffer[0] = '0';
            buffer[1] = '.';
        }

        // add leading/trailing 0's
        for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < params.zerosEndIndex; zerosCursor++) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
                buffer[--params.sigfigIndex] = '.';
            }
            buffer[--params.sigfigIndex] = bytes1(uint8(uint256(48) + (params.sigfigs % 10)));
            params.sigfigs /= 10;
        }
        return string(buffer);
    }
}