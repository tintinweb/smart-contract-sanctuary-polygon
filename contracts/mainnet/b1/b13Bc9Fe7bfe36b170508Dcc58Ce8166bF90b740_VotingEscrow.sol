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
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

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
library ClonesUpgradeable {
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
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value at the end of the corresponding block.
     */
    function getPastVotes(address account, uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value at the end of the corresponding block.
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

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
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
library SafeMath {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// DateTime Library v2.0
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day - 32075 + (1461 * (_year + 4800 + (_month - 14) / 12)) / 4
            + (367 * (_month - 2 - ((_month - 14) / 12) * 12)) / 12
            - (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) / 4 - OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            int256 __days = int256(_days);

            int256 L = __days + 68569 + OFFSET19700101;
            int256 N = (4 * L) / 146097;
            L = L - (146097 * N + 3) / 4;
            int256 _year = (4000 * (L + 1)) / 1461001;
            L = L - (1461 * _year) / 4 + 31;
            int256 _month = (80 * L) / 2447;
            int256 _day = L - (2447 * _month) / 80;
            L = _month / 11;
            _month = _month + 2 - 12 * L;
            _year = 100 * (N - 49) + _year + L;

            year = uint256(_year);
            month = uint256(_month);
            day = uint256(_day);
        }
    }

    function timestampFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    )
        internal
        pure
        returns (uint256 timestamp)
    {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR
            + minute * SECONDS_PER_MINUTE + second;
    }

    function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        }
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
    {
        unchecked {
            (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
            uint256 secs = timestamp % SECONDS_PER_DAY;
            hour = secs / SECONDS_PER_HOUR;
            secs = secs % SECONDS_PER_HOUR;
            minute = secs / SECONDS_PER_MINUTE;
            second = secs % SECONDS_PER_MINUTE;
        }
    }

    function isValidDate(uint256 year, uint256 month, uint256 day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second)
        internal
        pure
        returns (bool valid)
    {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (,, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.12;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IVotingEscrow.sol";
import "../Epoch.sol";

/**
 * @title Airdrop Contract
 * @dev A contract for distributing tokens through an airdrop mechanism.
 */
contract Airdrop {
    using SafeERC20 for ERC20Burnable;

    uint256 public constant LOCK_PERIOD = 2 * 365 * 86400;
    uint256 public constant START_TIME = 1686268800; // 6/9/23
    uint256 public constant END_TIME = START_TIME + 2 * EPOCH_DURATION;

    address public immutable owner;

    mapping(address => uint256) private _claimable; // Amount claimable by each address
    mapping(address => address) private _creatorOf; // Addresses of contract creators

    ERC20Burnable private token;
    IVotingEscrow private ve;

    uint256 public unclaimed;

    event Claimed(address indexed claimer, address indexed onBehalf, uint256 amount);

    constructor(address _token, address _ve) {
        owner = msg.sender;
        token = ERC20Burnable(_token);
        ve = IVotingEscrow(_ve);
    }

    /**
     * @dev Initializes the mappings `_claimable` and `_creatorOf`.
     * @notice This function is called by the contract owner to initialize the contract with data.
     * @param data The initialization data encoded as a bytes array.
     * @dev The data is parsed and stored in the contract's storage using inline assembly to significantly reduce gas costs.
     */
    function init(bytes calldata data) external {
        require(msg.sender == owner, "callable only by owner");
        uint256 len = data.length;
        require(len % 52 == 0, "invalid data length");

        assembly {
            let ptr := 0x44 // Skip function selector, the offset and the length field in calldata
            let end := add(ptr, len)

            for {

            } lt(ptr, end) {

            } {
                let slot := calldataload(ptr)
                let value := shr(96, calldataload(add(ptr, 0x20)))
                sstore(slot, value)
                ptr := add(ptr, 0x34) // move to the next tuple
            }
        }
    }

    /**
     * @dev Funds the contract with the specified amount of tokens.
     * @param amount The amount of tokens to fund.
     * @notice This function can only be called by the contract owner.
     * @notice The tokens are transferred from the owner's address to the contract address.
     * @notice The approved amount of tokens for voting escrow is increased.
     */
    function fund(uint256 amount) external {
        require(msg.sender == owner, "callable only by owner");
        require(block.timestamp < END_TIME, "Airdrop period is over");
        token.safeTransferFrom(msg.sender, address(this), amount);
        unclaimed += amount;
        token.approve(address(ve), unclaimed);
    }

    /**
     * @dev Shuts down the airdrop and burns any remaining unclaimed tokens.
     * @notice This function can only be called by the contract owner.
     * @notice The function can only be called after the end time of the airdrop.
     * @notice All unclaimed tokens are burned and the approval for voting escrow is reset.
     */
    function shutdown() external {
        require(msg.sender == owner, "callable only by owner");
        require(block.timestamp >= END_TIME, "Airdrop period is not over");
        uint256 burnAmount = unclaimed;
        require(burnAmount > 0, "nothing to burn");
        unclaimed = 0;
        token.approve(address(ve), 0);
        token.burn(burnAmount);
    }

    /**
     * @dev Returns the amount of tokens claimable by the specified account.
     * @param account The account to check for claimable tokens.
     * @return amount The amount of tokens claimable.
     */
    function claimable(address account) public view returns (uint256 amount) {
        if (_isActive()) {
            amount = _claimable[account];
            if (amount > unclaimed) {
                amount = unclaimed;
            }
        }
    }

    /**
     * @dev Allows an account to claim their tokens.
     *
     * The tokens will be locked in the voting escrow for the specified lock period.
     *
     * @notice The caller must have claimable tokens.
     * @notice The tokens are locked in the voting escrow contract and ownership is transferred to the claimer.
     */
    function claim() external {
        uint256 claimableAmount = claimable(msg.sender);
        require(claimableAmount > 0, "nothing to claim");
        delete _claimable[msg.sender];
        emit Claimed(msg.sender, msg.sender, claimableAmount);
        _lockAndSend(claimableAmount, msg.sender);
    }

    /**
     * @dev Allows the creator of an account (contract) to claim tokens on behalf of that account.
     *
     * The tokens will be locked in the voting escrow for the specified lock period.
     *
     * @param account The account to claim tokens on behalf of.
     * @notice The caller must be the creator of the specified account.
     * @notice The tokens are locked in the voting escrow contract and ownership is transferred to the claimer.
     */
    function claimOnBehalf(address account) external {
        uint256 claimableAmount = claimable(account);
        require(claimableAmount > 0, "nothing to claim");
        address creator = _creatorOf[account];
        require(msg.sender == creator, "not allowed");
        delete _claimable[account];
        delete _creatorOf[account];
        emit Claimed(msg.sender, account, claimableAmount);
        _lockAndSend(claimableAmount, msg.sender);
    }

    /**
     * @dev Locks the specified amount of tokens in the voting escrow and sends them to the specified address.
     * @param amount The amount of tokens to lock and send.
     * @param to The address to send the locked tokens to.
     * @notice The specified amount of tokens is subtracted from the unclaimed token balance.
     * @notice A new lock is created in the voting escrow contract with the specified amount, lock period, and receiver address.
     */
    function _lockAndSend(uint256 amount, address to) internal {
        unclaimed -= amount;
        uint256 tokenId = ve.create_lock_for(amount, LOCK_PERIOD, to);
        require(tokenId != 0 && ve.ownerOf(tokenId) == to, "minting failed");
    }

    /**
     * @dev Checks if the airdrop is currently active.
     * @return A boolean indicating whether the airdrop is active.
     * @notice The airdrop is active if the current timestamp is within the start and end time of the airdrop.
     */
    function _isActive() internal view returns (bool) {
        return block.timestamp >= START_TIME && block.timestamp < END_TIME;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../interfaces/IBribe.sol";
import "../interfaces/IGauge.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IPairFactory.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IVotingEscrow.sol";

contract PairAPI is Initializable {
    struct pairInfo {
        // pair info
        address pair_address; // pair contract address
        string symbol; // pair symbol
        string name; // pair name
        uint256 decimals; // pair decimals
        bool stable; // pair pool type (stable = false, means it's a variable type of pool)
        uint256 total_supply; // pair tokens supply
        // token pair info
        address token0; // pair 1st token address
        string token0_symbol; // pair 1st token symbol
        uint256 token0_decimals; // pair 1st token decimals
        uint256 reserve0; // pair 1st token reserves (nr. of tokens in the contract)
        uint256 claimable0; // claimable 1st token from fees (for unstaked positions)
        address token1; // pair 2nd token address
        string token1_symbol; // pair 2nd token symbol
        uint256 token1_decimals; // pair 2nd token decimals
        uint256 reserve1; // pair 2nd token reserves (nr. of tokens in the contract)
        uint256 claimable1; // claimable 2nd token from fees (for unstaked positions)
        // pairs gauge
        address gauge; // pair gauge address
        uint256 gauge_total_supply; // pair staked tokens (less/eq than/to pair total supply)
        address fee; // pair fees contract address
        address bribe; // pair bribes contract address
        uint256 emissions; // pair emissions (per second)
        address emissions_token; // pair emissions token address
        uint256 emissions_token_decimals; // pair emissions token decimals
        // User deposit
        uint256 account_lp_balance; // account LP tokens balance
        uint256 account_token0_balance; // account 1st token balance
        uint256 account_token1_balance; // account 2nd token balance
        uint256 account_gauge_balance; // account pair staked in gauge balance
        uint256 account_gauge_earned; // account earned emissions for this pair
    }

    struct tokenBribe {
        address token;
        uint8 decimals;
        uint256 amount;
        string symbol;
    }

    struct pairBribeEpoch {
        uint256 epochTimestamp;
        uint256 totalVotes;
        address pair;
        tokenBribe[] bribes;
    }

    uint256 public constant MAX_PAIRS = 1000;
    uint256 public constant MAX_EPOCHS = 200;
    uint256 public constant MAX_REWARDS = 16;
    uint256 public constant WEEK = 7 * 24 * 60 * 60;

    IPairFactory public pairFactory;
    IVoter public voter;

    address public underlyingToken;

    address public owner;

    event Owner(address oldOwner, address newOwner);
    event Voter(address oldVoter, address newVoter);

    function initialize(address _voter) public initializer {
        owner = msg.sender;

        voter = IVoter(_voter);

        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter._ve()).token();
    }

    function getAllPair(address _user, uint256 _amounts, uint256 _offset) external view returns (pairInfo[] memory Pairs) {
        require(_amounts <= MAX_PAIRS, "too many pair");

        Pairs = new pairInfo[](_amounts);

        uint256 i = _offset;
        uint256 totPairs = pairFactory.allPairsLength();
        address _pair;

        for (i; i < _offset + _amounts; i++) {
            // if totalPairs is reached, break.
            if (i == totPairs) {
                break;
            }
            _pair = pairFactory.allPairs(i);
            Pairs[i - _offset] = _pairAddressToInfo(_pair, _user);
        }
    }

    function getPair(address _pair, address _account) external view returns (pairInfo memory _pairInfo) {
        return _pairAddressToInfo(_pair, _account);
    }

    function _pairAddressToInfo(address _pair, address _account) internal view returns (pairInfo memory _pairInfo) {
        IPair ipair = IPair(_pair);

        address token_0;
        address token_1;
        uint256 r0;
        uint256 r1;

        (token_0, token_1) = ipair.tokens();
        (r0, r1, ) = ipair.getReserves();

        IGauge _gauge = IGauge(voter.gauges(_pair));
        uint256 accountGaugeLPAmount = 0;
        uint256 earned = 0;
        uint256 gaugeTotalSupply = 0;
        uint256 emissions = 0;

        if (address(_gauge) != address(0)) {
            if (_account != address(0)) {
                accountGaugeLPAmount = _gauge.balanceOf(_account);
                earned = _gauge.earned(_account);
            } else {
                accountGaugeLPAmount = 0;
                earned = 0;
            }
            gaugeTotalSupply = _gauge.totalSupply();
            emissions = _gauge.rewardRate();
        }

        // Pair General Info
        _pairInfo.pair_address = _pair;
        _pairInfo.symbol = ipair.symbol();
        _pairInfo.name = ipair.name();
        _pairInfo.decimals = ipair.decimals();
        _pairInfo.stable = ipair.stable();
        _pairInfo.total_supply = ipair.totalSupply();

        // Token0 Info
        _pairInfo.token0 = token_0;
        _pairInfo.token0_decimals = IERC20MetadataUpgradeable(token_0).decimals();
        _pairInfo.token0_symbol = IERC20MetadataUpgradeable(token_0).symbol();
        _pairInfo.reserve0 = r0;
        _pairInfo.claimable0 = ipair.claimable0(_account);

        // Token1 Info
        _pairInfo.token1 = token_1;
        _pairInfo.token1_decimals = IERC20MetadataUpgradeable(token_1).decimals();
        _pairInfo.token1_symbol = IERC20MetadataUpgradeable(token_1).symbol();
        _pairInfo.reserve1 = r1;
        _pairInfo.claimable1 = ipair.claimable1(_account);

        // Pair's gauge Info
        _pairInfo.gauge = address(_gauge);
        _pairInfo.gauge_total_supply = gaugeTotalSupply;
        _pairInfo.emissions = emissions;
        _pairInfo.emissions_token = underlyingToken;
        _pairInfo.emissions_token_decimals = IERC20MetadataUpgradeable(underlyingToken).decimals();

        // external address
        _pairInfo.fee = voter.internal_bribes(address(_gauge));
        _pairInfo.bribe = voter.external_bribes(address(_gauge));

        // Account Info
        _pairInfo.account_lp_balance = IERC20Upgradeable(_pair).balanceOf(_account);
        _pairInfo.account_token0_balance = IERC20Upgradeable(token_0).balanceOf(_account);
        _pairInfo.account_token1_balance = IERC20Upgradeable(token_1).balanceOf(_account);
        _pairInfo.account_gauge_balance = accountGaugeLPAmount;
        _pairInfo.account_gauge_earned = earned;
    }

    function getPairBribe(uint256 _amounts, uint256 _offset, address _pair) external view returns (pairBribeEpoch[] memory _pairEpoch) {
        require(_amounts <= MAX_EPOCHS, "too many epochs");

        _pairEpoch = new pairBribeEpoch[](_amounts);

        address _gauge = voter.gauges(_pair);

        IBribe bribe = IBribe(voter.external_bribes(_gauge));

        // check bribe and checkpoints exists
        if (address(0) == address(bribe)) {
            return _pairEpoch;
        }

        // scan bribes
        // get latest balance and epoch start for bribes
        uint256 _epochStartTimestamp = bribe.firstBribeTimestamp();

        // if 0 then no bribe created so far
        if (_epochStartTimestamp == 0) {
            return _pairEpoch;
        }

        uint256 _supply;
        uint256 i = _offset;

        for (i; i < _offset + _amounts; i++) {
            _supply = bribe.totalSupplyAt(_epochStartTimestamp);
            _pairEpoch[i - _offset].epochTimestamp = _epochStartTimestamp;
            _pairEpoch[i - _offset].pair = _pair;
            _pairEpoch[i - _offset].totalVotes = _supply;
            _pairEpoch[i - _offset].bribes = _bribe(_epochStartTimestamp, address(bribe));

            _epochStartTimestamp += WEEK;
        }
    }

    function _bribe(uint256 _ts, address _br) internal view returns (tokenBribe[] memory _tb) {
        IBribe _wb = IBribe(_br);
        uint256 tokenLen = _wb.rewardsListLength();

        _tb = new tokenBribe[](tokenLen);

        uint256 k;
        uint256 _rewPerEpoch;
        IERC20MetadataUpgradeable _t;
        for (k = 0; k < tokenLen; k++) {
            _t = IERC20MetadataUpgradeable(_wb.rewardTokens(k));
            IBribe.Reward memory _reward = _wb.rewardData(address(_t), _ts);
            _rewPerEpoch = _reward.rewardsPerEpoch;
            if (_rewPerEpoch > 0) {
                _tb[k].token = address(_t);
                _tb[k].symbol = _t.symbol();
                _tb[k].decimals = _t.decimals();
                _tb[k].amount = _rewPerEpoch;
            } else {
                _tb[k].token = address(_t);
                _tb[k].symbol = _t.symbol();
                _tb[k].decimals = _t.decimals();
                _tb[k].amount = 0;
            }
        }
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "not owner");
        require(_owner != address(0), "zeroAddr");
        owner = _owner;
        emit Owner(msg.sender, _owner);
    }

    function setVoter(address _voter) external {
        require(msg.sender == owner, "not owner");
        require(_voter != address(0), "zeroAddr");
        address _oldVoter = address(voter);
        voter = IVoter(_voter);

        // update variable depending on voter
        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter._ve()).token();

        emit Voter(_oldVoter, _voter);
    }

    function left(address _pair, address _token) external view returns (uint256 _rewPerEpoch) {
        address _gauge = voter.gauges(_pair);
        IBribe bribe = IBribe(voter.internal_bribes(_gauge));

        uint256 _ts = bribe.getEpochStart();
        IBribe.Reward memory _reward = bribe.rewardData(_token, _ts);
        _rewPerEpoch = _reward.rewardsPerEpoch;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../interfaces/IBribe.sol";
import "../interfaces/IPairFactory.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IVotingEscrow.sol";

contract RewardAPI is Initializable {
    IPairFactory public pairFactory;
    IVoter public voter;
    address public underlyingToken;
    address public owner;

    mapping(address => bool) public notReward;

    constructor() {}

    function initialize(address _voter) public initializer {
        owner = msg.sender;
        voter = IVoter(_voter);
        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter._ve()).token();
    }

    struct Bribes {
        address[] tokens;
        string[] symbols;
        uint256[] decimals;
        uint256[] amounts;
    }

    struct Rewards {
        Bribes[] bribes;
    }

    function hasPendingRewards(uint256 _tokenId, address[] calldata _pairs) external view returns (bool) {
        uint256 _numPairs = _pairs.length;

        for (uint256 i = 0; i < _numPairs; ) {
            address _gauge = voter.gauges(_pairs[i]);
            if (_gauge != address(0)) {
                // external
                address _bribe = voter.external_bribes(_gauge);
                uint256 _epochStart = IBribe(_bribe).getEpochStart();
                uint256 _balance = IBribe(_bribe).balanceOfAt(_tokenId, _epochStart);

                if (_balance != 0) {
                    uint256 _numTokens = IBribe(_bribe).rewardsListLength();
                    uint256 _supply = IBribe(_bribe).totalSupplyAt(_epochStart);

                    for (uint256 j; j < _numTokens; ) {
                        address _token = IBribe(_bribe).rewardTokens(j);
                        if (!notReward[_token]) {
                            IBribe.Reward memory _reward = IBribe(_bribe).rewardData(_token, _epochStart);
                            uint256 _amount = (((_reward.rewardsPerEpoch * 1e18) / _supply) * _balance) / 1e18;
                            if (_amount != 0) return true;
                        }
                        unchecked {
                            ++j;
                        }
                    }
                }

                // internal
                _bribe = voter.internal_bribes(_gauge);
                _balance = IBribe(_bribe).balanceOfAt(_tokenId, _epochStart);

                if (_balance != 0) {
                    uint256 _numTokens = IBribe(_bribe).rewardsListLength();
                    uint256 _supply = IBribe(_bribe).totalSupplyAt(_epochStart);

                    for (uint256 j; j < _numTokens; ) {
                        address _token = IBribe(_bribe).rewardTokens(j);
                        if (!notReward[_token]) {
                            IBribe.Reward memory _reward = IBribe(_bribe).rewardData(_token, _epochStart);
                            uint256 _amount = (((_reward.rewardsPerEpoch * 1e18) / _supply) * _balance) / 1e18;
                            if (_amount != 0) return true;
                        }
                        unchecked {
                            ++j;
                        }
                    }
                }
            }
            unchecked {
                ++i;
            }
        }

        return false;
    }

    // @Notice Get the rewards available the next epoch.
    function getExpectedClaimForNextEpoch(uint256 tokenId, address[] memory pairs) external view returns (Rewards[] memory) {
        uint256 i;
        uint256 len = pairs.length;
        address _gauge;
        address _bribe;

        Bribes[] memory _tempReward = new Bribes[](2);
        Rewards[] memory _rewards = new Rewards[](len);

        //external
        for (i = 0; i < len; i++) {
            _gauge = voter.gauges(pairs[i]);

            // get external
            _bribe = voter.external_bribes(_gauge);
            _tempReward[0] = _getEpochRewards(tokenId, _bribe);

            // get internal
            _bribe = voter.internal_bribes(_gauge);
            _tempReward[1] = _getEpochRewards(tokenId, _bribe);
            _rewards[i].bribes = _tempReward;
        }

        return _rewards;
    }

    function _getEpochRewards(uint256 tokenId, address _bribe) internal view returns (Bribes memory _rewards) {
        uint256 totTokens = IBribe(_bribe).rewardsListLength();
        uint256[] memory _amounts = new uint256[](totTokens);
        address[] memory _tokens = new address[](totTokens);
        string[] memory _symbol = new string[](totTokens);
        uint256[] memory _decimals = new uint256[](totTokens);
        uint256 ts = IBribe(_bribe).getEpochStart();
        uint256 i = 0;
        uint256 _supply = IBribe(_bribe).totalSupplyAt(ts);
        uint256 _balance = IBribe(_bribe).balanceOfAt(tokenId, ts);
        address _token;
        IBribe.Reward memory _reward;

        for (i; i < totTokens; i++) {
            _token = IBribe(_bribe).rewardTokens(i);
            _tokens[i] = _token;
            if (_balance == 0 || notReward[_token]) {
                _amounts[i] = 0;
                _symbol[i] = "";
                _decimals[i] = 0;
            } else {
                _symbol[i] = IERC20MetadataUpgradeable(_token).symbol();
                _decimals[i] = IERC20MetadataUpgradeable(_token).decimals();
                _reward = IBribe(_bribe).rewardData(_token, ts);
                _amounts[i] = (((_reward.rewardsPerEpoch * 1e18) / _supply) * _balance) / 1e18;
            }
        }

        _rewards.tokens = _tokens;
        _rewards.amounts = _amounts;
        _rewards.symbols = _symbol;
        _rewards.decimals = _decimals;
    }

    // read all the bribe available for a pair
    function getPairBribe(address pair) external view returns (Bribes[] memory) {
        address _gauge;
        address _bribe;

        Bribes[] memory _tempReward = new Bribes[](2);

        // get external
        _gauge = voter.gauges(pair);
        _bribe = voter.external_bribes(_gauge);
        _tempReward[0] = _getNextEpochRewards(_bribe);

        // get internal
        _bribe = voter.internal_bribes(_gauge);
        _tempReward[1] = _getNextEpochRewards(_bribe);
        return _tempReward;
    }

    function _getNextEpochRewards(address _bribe) internal view returns (Bribes memory _rewards) {
        uint256 totTokens = IBribe(_bribe).rewardsListLength();
        uint256[] memory _amounts = new uint256[](totTokens);
        address[] memory _tokens = new address[](totTokens);
        string[] memory _symbol = new string[](totTokens);
        uint256[] memory _decimals = new uint256[](totTokens);
        uint256 ts = IBribe(_bribe).getNextEpochStart();
        uint256 i = 0;
        address _token;
        IBribe.Reward memory _reward;

        for (i; i < totTokens; i++) {
            _token = IBribe(_bribe).rewardTokens(i);
            _tokens[i] = _token;
            if (notReward[_token]) {
                _amounts[i] = 0;
                _tokens[i] = address(0);
                _symbol[i] = "";
                _decimals[i] = 0;
            } else {
                _symbol[i] = IERC20MetadataUpgradeable(_token).symbol();
                _decimals[i] = IERC20MetadataUpgradeable(_token).decimals();
                _reward = IBribe(_bribe).rewardData(_token, ts);
                _amounts[i] = _reward.rewardsPerEpoch;
            }
        }

        _rewards.tokens = _tokens;
        _rewards.amounts = _amounts;
        _rewards.symbols = _symbol;
        _rewards.decimals = _decimals;
    }

    function addNotReward(address _token) external {
        require(msg.sender == owner, "not owner");
        notReward[_token] = true;
    }

    function removeNotReward(address _token) external {
        require(msg.sender == owner, "not owner");
        notReward[_token] = false;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "not owner");
        require(_owner != address(0), "zeroAddr");
        owner = _owner;
    }

    function setVoter(address _voter) external {
        require(msg.sender == owner, "not owner");
        require(_voter != address(0), "zeroAddr");
        voter = IVoter(_voter);
        // update variable depending on voter
        pairFactory = IPairFactory(voter.factory());
        underlyingToken = IVotingEscrow(voter._ve()).token();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../interfaces/IBribe.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IPairFactory.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IRewardsDistributor.sol";

interface IPairAPI {
    struct pairInfo {
        // pair info
        address pair_address; // pair contract address
        string symbol; // pair symbol
        string name; // pair name
        uint256 decimals; // pair decimals
        bool stable; // pair pool type (stable = false, means it's a variable type of pool)
        uint256 total_supply; // pair tokens supply
        // token pair info
        address token0; // pair 1st token address
        string token0_symbol; // pair 1st token symbol
        uint256 token0_decimals; // pair 1st token decimals
        uint256 reserve0; // pair 1st token reserves (nr. of tokens in the contract)
        uint256 claimable0; // claimable 1st token from fees (for unstaked positions)
        address token1; // pair 2nd token address
        string token1_symbol; // pair 2nd token symbol
        uint256 token1_decimals; // pair 2nd token decimals
        uint256 reserve1; // pair 2nd token reserves (nr. of tokens in the contract)
        uint256 claimable1; // claimable 2nd token from fees (for unstaked positions)
        // pairs gauge
        address gauge; // pair gauge address
        uint256 gauge_total_supply; // pair staked tokens (less/eq than/to pair total supply)
        address fee; // pair fees contract address
        address bribe; // pair bribes contract address
        uint256 emissions; // pair emissions (per second)
        address emissions_token; // pair emissions token address
        uint256 emissions_token_decimals; // pair emissions token decimals
        // User deposit
        uint256 account_lp_balance; // account LP tokens balance
        uint256 account_token0_balance; // account 1st token balance
        uint256 account_token1_balance; // account 2nd token balance
        uint256 account_gauge_balance; // account pair staked in gauge balance
        uint256 account_gauge_earned; // account earned emissions for this pair
    }

    function getPair(address _pair, address _account) external view returns (pairInfo memory _pairInfo);

    function pair_factory() external view returns (address);
}

contract veNFTAPI is Initializable {
    struct pairVotes {
        address pair;
        uint256 weight;
    }

    struct veNFT {
        uint8 decimals;
        bool voted;
        uint256 id;
        uint128 amount;
        uint256 voting_amount;
        uint256 rebase_amount;
        uint256 lockEnd;
        uint256 vote_ts;
        pairVotes[] votes;
        address account;
        address token;
        string tokenSymbol;
        uint256 tokenDecimals;
    }

    struct Reward {
        uint256 id;
        uint256 amount;
        uint8 decimals;
        address pair;
        address token;
        address fee;
        address bribe;
        string symbol;
    }

    uint256 public constant MAX_RESULTS = 1000;
    uint256 public constant MAX_PAIRS = 30;

    IVoter public voter;
    address public underlyingToken;

    mapping(address => bool) public notReward;

    IVotingEscrow public ve;
    IRewardsDistributor public rewardDistributor;

    address public pairAPI;
    IPairFactory public pairFactory;

    address public owner;
    event Owner(address oldOwner, address newOwner);

    struct AllPairRewards {
        Reward[] rewards;
    }

    constructor() {}

    function initialize(address _voter, address _rewarddistro, address _pairApi, address _pairFactory) public initializer {
        owner = msg.sender;

        pairAPI = _pairApi;
        voter = IVoter(_voter);
        rewardDistributor = IRewardsDistributor(_rewarddistro);

        require(rewardDistributor.voting_escrow() == voter._ve(), "ve!=ve");

        ve = IVotingEscrow(rewardDistributor.voting_escrow());
        underlyingToken = IVotingEscrow(ve).token();

        pairFactory = IPairFactory(_pairFactory);
    }

    function getAllNFT(uint256 _amounts, uint256 _offset) external view returns (veNFT[] memory _veNFT) {
        require(_amounts <= MAX_RESULTS, "too many nfts");
        _veNFT = new veNFT[](_amounts);

        uint256 i = _offset;
        uint256 j = i + _amounts;
        uint256 k = 0;

        address _owner;

        while (i != j) {
            _owner = ve.ownerOf(i);
            // if id_i has owner read data
            if (_owner != address(0)) {
                _veNFT[k] = _getNFTFromId(i, _owner);
            }
            unchecked {
                ++i;
                ++k;
            }
        }
    }

    function getNFTFromId(uint256 id) external view returns (veNFT memory) {
        return _getNFTFromId(id, ve.ownerOf(id));
    }

    function getNFTFromAddress(address _user) external view returns (veNFT[] memory venft) {
        uint256 _id;
        uint256 totNFTs = ve.balanceOf(_user);

        venft = new veNFT[](totNFTs);

        for (uint i = totNFTs; i != 0; ) {
            unchecked {
                --i;
            }
            _id = ve.tokenOfOwnerByIndex(_user, i);
            if (_id != 0) {
                venft[i] = _getNFTFromId(_id, _user);
            }
        }
    }

    function _getNFTFromId(uint256 id, address _owner) internal view returns (veNFT memory venft) {
        if (_owner == address(0)) {
            return venft;
        }

        uint256 _totalPoolVotes = voter.poolVoteLength(id);
        pairVotes[] memory votes = new pairVotes[](_totalPoolVotes);

        IVotingEscrow.LockedBalance memory _lockedBalance;
        _lockedBalance = ve.locked(id);

        uint256 _poolWeight;
        address _votedPair;

        for (uint256 k = _totalPoolVotes; k != 0; ) {
            unchecked {
                --k;
            }
            _votedPair = voter.poolVote(id, k);
            if (_votedPair != address(0)) {
                _poolWeight = voter.votes(id, _votedPair);
                votes[k].pair = _votedPair;
                votes[k].weight = _poolWeight;
            }
        }

        venft.id = id;
        venft.account = _owner;
        venft.decimals = ve.decimals();
        venft.amount = uint128(_lockedBalance.amount);
        venft.voting_amount = ve.balanceOfNFT(id);
        venft.rebase_amount = rewardDistributor.claimable(id);
        venft.lockEnd = _lockedBalance.end;
        venft.vote_ts = voter.lastVoted(id);
        venft.votes = votes;
        venft.token = ve.token();
        venft.tokenSymbol = IERC20MetadataUpgradeable(ve.token()).symbol();
        venft.tokenDecimals = IERC20MetadataUpgradeable(ve.token()).decimals();
        venft.voted = ve.voted(id);
    }

    function hasClaimableRewards(uint256 _tokenId) external view returns (bool) {
        if (rewardDistributor.claimable(_tokenId) != 0) {
            return true;
        }
        uint256 _totalPairs = pairFactory.allPairsLength();
        for (uint256 i = 0; i < _totalPairs; ) {
            address _pair = pairFactory.allPairs(i);
            address _gauge = voter.gauges(_pair);

            if (_gauge != address(0)) {
                (, , , , , address t0, address t1) = IPair(_pair).metadata();

                IPairAPI.pairInfo memory _pairApi = IPairAPI(pairAPI).getPair(_pair, address(0));

                if (0 != IBribe(_pairApi.fee).earned(_tokenId, t0)) return true;
                if (0 != IBribe(_pairApi.fee).earned(_tokenId, t1)) return true;

                address wrappedBribe = _pairApi.bribe;

                if (wrappedBribe != address(0)) {
                    uint256 _totalBribeTokens = IBribe(wrappedBribe).rewardsListLength();

                    for (uint256 j = _totalBribeTokens; j != 0; ) {
                        unchecked {
                            --j;
                        }
                        address _token = IBribe(wrappedBribe).rewardTokens(j);
                        if (0 != IBribe(wrappedBribe).earned(_tokenId, _token) && !notReward[_token]) return true;
                    }
                }
            }

            unchecked {
                ++i;
            }
        }
        return false;
    }

    function allPairRewards(uint256 _amount, uint256 _offset, uint256 id) external view returns (AllPairRewards[] memory rewards) {
        rewards = new AllPairRewards[](MAX_PAIRS);

        uint256 totalPairs = pairFactory.allPairsLength();

        uint256 i = _offset;
        address _pair;
        for (i; i < _offset + _amount; i++) {
            if (i >= totalPairs) {
                break;
            }
            _pair = pairFactory.allPairs(i);
            rewards[i].rewards = _pairReward(_pair, id);
        }
    }

    function singlePairReward(uint256 id, address _pair) external view returns (Reward[] memory _reward) {
        return _pairReward(_pair, id);
    }

    function _pairReward(address _pair, uint256 id) internal view returns (Reward[] memory _reward) {
        if (_pair == address(0)) {
            return _reward;
        }

        IPairAPI.pairInfo memory _pairApi = IPairAPI(pairAPI).getPair(_pair, address(0));

        address wrappedBribe = _pairApi.bribe;

        uint256 totBribeTokens = (wrappedBribe == address(0)) ? 0 : IBribe(wrappedBribe).rewardsListLength();

        uint256 bribeAmount;

        _reward = new Reward[](2 + totBribeTokens);

        address _gauge = (voter.gauges(_pair));

        if (_gauge == address(0)) {
            return _reward;
        }

        (, , , , , address t0, address t1) = IPair(_pair).metadata();
        uint256 _feeToken0 = IBribe(_pairApi.fee).earned(id, t0);
        uint256 _feeToken1 = IBribe(_pairApi.fee).earned(id, t1);

        if (_feeToken0 > 0) {
            _reward[0] = Reward({
                id: id,
                pair: _pair,
                amount: _feeToken0,
                token: t0,
                symbol: IERC20MetadataUpgradeable(t0).symbol(),
                decimals: IERC20MetadataUpgradeable(t0).decimals(),
                fee: voter.internal_bribes(address(_gauge)),
                bribe: address(0)
            });
        }

        if (_feeToken1 > 0) {
            _reward[1] = Reward({
                id: id,
                pair: _pair,
                amount: _feeToken1,
                token: t1,
                symbol: IERC20MetadataUpgradeable(t1).symbol(),
                decimals: IERC20MetadataUpgradeable(t1).decimals(),
                fee: voter.internal_bribes(address(_gauge)),
                bribe: address(0)
            });
        }

        //wrapped bribe point to Bribes.sol (ext bribe)
        if (wrappedBribe == address(0)) {
            return _reward;
        }

        uint256 k = 0;
        address _token;

        for (k; k < totBribeTokens; k++) {
            _token = IBribe(wrappedBribe).rewardTokens(k);
            bribeAmount = IBribe(wrappedBribe).earned(id, _token);
            if (!notReward[_token]) {
                _reward[2 + k] = Reward({
                    id: id,
                    pair: _pair,
                    amount: bribeAmount,
                    token: _token,
                    symbol: IERC20MetadataUpgradeable(_token).symbol(),
                    decimals: IERC20MetadataUpgradeable(_token).decimals(),
                    fee: address(0),
                    bribe: wrappedBribe
                });
            }
        }

        return _reward;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner, "not owner");
        require(_owner != address(0), "zeroAddr");
        owner = _owner;
        emit Owner(msg.sender, _owner);
    }

    function setVoter(address _voter) external {
        require(msg.sender == owner);

        voter = IVoter(_voter);
    }

    function setRewardDistro(address _rewarddistro) external {
        require(msg.sender == owner);

        rewardDistributor = IRewardsDistributor(_rewarddistro);
        require(rewardDistributor.voting_escrow() == voter._ve(), "ve!=ve");

        ve = IVotingEscrow(rewardDistributor.voting_escrow());
        underlyingToken = IVotingEscrow(ve).token();
    }

    function setPairAPI(address _pairApi) external {
        require(msg.sender == owner);
        pairAPI = _pairApi;
    }

    function setPairFactory(address _pairFactory) external {
        require(msg.sender == owner);
        pairFactory = IPairFactory(_pairFactory);
    }

    function setVotingEscrow(address _votingEscrow) external {
        require(msg.sender == owner);
        ve = IVotingEscrow(_votingEscrow);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "../interfaces/IMinter.sol";
import "../interfaces/IVoter.sol";

contract EpochController is OwnableUpgradeable {
    IMinter public minter;
    IVoter public voter;
    uint256 public batchSize;

    uint256 private _lastProcessed;
    bool private _isDistributing;

    constructor() {}

    function initialize(address _minter, address _voter) public initializer {
        __Ownable_init();
        minter = IMinter(_minter);
        voter = IVoter(_voter);
        batchSize = 10;
    }

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        canExec = _isDistributing;
        if (!canExec) {
            canExec = minter.check();
            if (canExec) {
                canExec = voter.length() > 0;
            }
        }
        if (canExec) {
            execPayload = abi.encodeWithSelector(EpochController.distribute.selector);
        } else {
            execPayload = abi.encode(minter.active_period());
        }
    }

    function distribute() external {
        if (!_isDistributing) {
            _isDistributing = minter.check();
        }
        if (_isDistributing) {
            uint256 numPools = voter.length();
            uint256 from = _lastProcessed;
            uint256 to = MathUpgradeable.min(numPools, from + batchSize);
            voter.distribute(from, to);
            bool done = to == numPools;
            _lastProcessed = done ? 0 : to;
            _isDistributing = !done;
        }
    }

    function setBatchSize(uint256 _batchSize) external onlyOwner {
        require(_batchSize != 0, "batch size can not be 0");
        batchSize = _batchSize;
    }

    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0));
        minter = IMinter(_minter);
    }

    function setVoter(address _voter) external onlyOwner {
        require(_voter != address(0));
        voter = IVoter(_voter);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "../interfaces/IPairFactory.sol";
import "../interfaces/IVoter.sol";
import "../Epoch.sol";

contract FeeDistributor is OwnableUpgradeable {
    IPairFactory public pairFactory;
    IVoter public voter;
    uint256 public batchSize;
    uint256 public interval;
    uint256 public intervalOffset;

    uint256 private _lastProcessed;
    bool private _isDistributing;

    address[] private _gauges;

    constructor() {}

    function initialize(address _pairFactory, address _voter) public initializer {
        __Ownable_init();
        pairFactory = IPairFactory(_pairFactory);
        voter = IVoter(_voter);
        batchSize = 20;
        interval = EPOCH_DURATION;
        intervalOffset = 10 minutes;
    }

    function checker() external view returns (bool canExec, bytes memory execPayload) {
        canExec = _isDistributing;
        if (!canExec) {
            uint256 endOfInterval = (block.timestamp / interval) * interval + interval;
            uint256 distributionStartTime = endOfInterval - intervalOffset;
            canExec = (block.timestamp > distributionStartTime && _lastProcessed < distributionStartTime) || true;
            if (canExec) {
                address[] memory gauges = _getGauges();
                canExec = gauges.length > 0;
            }
        }
        if (canExec) {
            execPayload = abi.encodeWithSelector(FeeDistributor.distribute.selector);
        } else {
            execPayload = "0x";
        }
    }

    function distribute() external {
        if (!_isDistributing) {
            _gauges = _getGauges();
            _isDistributing = _gauges.length > 0;
        }
        if (_isDistributing) {
            uint256 numGauges = _gauges.length;
            if (numGauges > batchSize) {
                numGauges = batchSize;
            }
            address[] memory gauges = new address[](numGauges);
            while (numGauges > 0) {
                unchecked {
                    --numGauges;
                }
                gauges[numGauges] = _gauges[_gauges.length - 1];
                _gauges.pop();
            }
            voter.distributeFees(gauges);
            _isDistributing = _gauges.length > 0;
            _lastProcessed = block.timestamp;
        }
    }

    function setBatchSize(uint256 _batchSize) external onlyOwner {
        require(_batchSize != 0, "batch size can not be 0");
        batchSize = _batchSize;
    }

    function setInterval(uint256 _interval) external onlyOwner {
        require(_interval >= 1 hours && _interval <= EPOCH_DURATION, "invalid interval");
        interval = _interval;
    }

    function setIntervalOffset(uint256 _offset) external onlyOwner {
        require(_offset > 0 && _offset < interval, "invalid interval offset");
        intervalOffset = _offset;
    }

    function setPairFactory(address _pairFactory) external onlyOwner {
        require(_pairFactory != address(0));
        pairFactory = IPairFactory(_pairFactory);
    }

    function setVoter(address _voter) external onlyOwner {
        require(_voter != address(0));
        voter = IVoter(_voter);
    }

    function _getGauges() internal view returns (address[] memory gauges) {
        uint256 numPairs = pairFactory.allPairsLength();
        address[] memory tmpGauges = new address[](numPairs);
        uint256 numGauges = 0;
        for (uint256 i = 0; i < numPairs; ) {
            address pair = pairFactory.allPairs(i);
            address gauge = voter.gauges(pair);
            if (gauge != address(0)) {
                (bool success, bytes memory result) = address(voter).staticcall(abi.encodeWithSignature("isAlive(address)", gauge));
                if (success && abi.decode(result, (bool))) {
                    tmpGauges[numGauges] = gauge;
                    unchecked {
                        ++numGauges;
                    }
                }
            }
            unchecked {
                ++i;
            }
        }
        gauges = new address[](numGauges);
        for (uint256 i = 0; i < numGauges; ) {
            gauges[i] = tmpGauges[i];
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./interfaces/IVotingEscrow.sol";

contract BonusDistributor {
    struct BonusPayment {
        uint256 tokenId;
        uint256 bonusPayment;
    }

    address private immutable _owner;
    address private immutable _distributor;

    ERC20Upgradeable public pearl;
    IVotingEscrow public ve;

    constructor(address _operator, address _pearl, address _ve) {
        _owner = msg.sender;
        _distributor = _operator;
        pearl = ERC20Upgradeable(_pearl);
        ve = IVotingEscrow(_ve);
    }

    function distribute(uint256 _total, BonusPayment[] calldata _payments) external {
        require(msg.sender == _distributor, "BonusDistributor: caller is not the distributor");
        uint256 _numPayments = _payments.length;
        uint256 _balance = pearl.balanceOf(address(this));
        require(_total != 0, "BonusDistributor: nothing to distribute");
        require(_total <= _balance, "BonusDistributor: balance too low");
        require(_numPayments != 0, "BonusDistributor: no receivers");
        uint256 _allowance = pearl.allowance(address(this), address(ve));
        if (_allowance < _total) {
            pearl.approve(address(ve), _balance);
        }
        for (uint256 _i = 0; _i < _numPayments; ) {
            ve.deposit_for(_payments[_i].tokenId, _payments[_i].bonusPayment);
            unchecked {
                ++_i;
            }
        }
    }

    function withdraw() external {
        _withdraw(msg.sender);
    }

    function withdraw(address _receiver) external {
        _withdraw(_receiver);
    }

    function _withdraw(address _receiver) internal {
        require(msg.sender == _owner, "BonusDistributor: caller is not the owner");
        uint256 _balance = pearl.balanceOf(address(this));
        pearl.transfer(_receiver, _balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IBribe.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingEscrow.sol";
import "./Epoch.sol";

contract Bribe is IBribe, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public firstBribeTimestamp;

    /* ========== STATE VARIABLES ========== */

    mapping(address => mapping(uint256 => IBribe.Reward)) private _rewardData; // token -> startTimestamp -> Reward
    mapping(address => uint256) _reserves;
    mapping(address => bool) public isRewardToken;
    address[] public rewardTokens;
    address public voter;
    address public bribeFactory;
    address public minter;
    address public ve;
    address public owner;

    string public TYPE;

    // tokenId -> reward token -> lastTime
    mapping(uint256 => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(uint256 => mapping(address => uint256)) public userTimestamp;

    mapping(uint256 => uint256) public _totalSupply;
    mapping(uint256 => mapping(uint256 => uint256)) private _balances; // tokenId -> timestamp -> amount

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    modifier onlyAllowed() {
        require((msg.sender == owner || msg.sender == bribeFactory), "permission is denied!");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _owner, address _voter, address _bribeFactory, string memory _type) {
        require(_bribeFactory != address(0) && _voter != address(0) && _owner != address(0));
        voter = _voter;
        bribeFactory = _bribeFactory;
        firstBribeTimestamp = 0;
        ve = IVoter(_voter)._ve();
        minter = IVoter(_voter).minter();
        require(minter != address(0));
        owner = _owner;

        TYPE = _type;
    }

    function getEpochStart() public view returns (uint256) {
        return IMinter(minter).active_period();
    }

    function getNextEpochStart() public view returns (uint256) {
        return getEpochStart() + EPOCH_DURATION;
    }

    /* ========== VIEWS ========== */

    function rewardData(address _token, uint256 _timestamp) external view override returns (Reward memory) {
        return _rewardData[_token][_timestamp];
    }

    function rewardsListLength() external view returns (uint256) {
        return rewardTokens.length;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply[getNextEpochStart()];
    }

    function totalSupplyAt(uint256 _timestamp) external view returns (uint256) {
        return _totalSupply[_timestamp];
    }

    function balanceOfAt(uint256 tokenId, uint256 _timestamp) public view returns (uint256) {
        return _balances[tokenId][_timestamp];
    }

    // get last deposit available balance (getNextEpochStart)
    function balanceOf(uint256 tokenId) public view returns (uint256) {
        uint256 _timestamp = getNextEpochStart();
        return _balances[tokenId][_timestamp];
    }

    function earned(uint256 tokenId, address _rewardToken) public view returns (uint256) {
        uint256 k = 0;
        uint256 reward = 0;
        uint256 _endTimestamp = getNextEpochStart();
        uint256 _userLastTime = userTimestamp[tokenId][_rewardToken];

        if (_endTimestamp == _userLastTime) {
            return 0;
        }

        // if user first time then set it to first bribe - week to avoid any timestamp problem
        if (_userLastTime < firstBribeTimestamp) {
            _userLastTime = firstBribeTimestamp - EPOCH_DURATION;
        }

        for (k; k < 50; k++) {
            if (_userLastTime == _endTimestamp) {
                // if we reach the current epoch, exit
                break;
            }
            reward += _earned(tokenId, _rewardToken, _userLastTime);
            _userLastTime += EPOCH_DURATION;
        }
        return reward;
    }

    function _earned(uint256 tokenId, address _rewardToken, uint256 _timestamp) internal view returns (uint256) {
        uint256 _balance = balanceOfAt(tokenId, _timestamp);
        if (_balance == 0) {
            return 0;
        } else {
            uint256 _rewardPerToken = rewardPerToken(_rewardToken, _timestamp);
            uint256 _rewards = (_rewardPerToken * _balance) / 1e18;
            return _rewards;
        }
    }

    function rewardPerToken(address _rewardsToken, uint256 _timestamp) public view returns (uint256) {
        if (_totalSupply[_timestamp] == 0) {
            return _rewardData[_rewardsToken][_timestamp].rewardsPerEpoch;
        }
        return (_rewardData[_rewardsToken][_timestamp].rewardsPerEpoch * 1e18) / _totalSupply[_timestamp];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _deposit(uint256 amount, uint256 tokenId) external nonReentrant {
        require(amount > 0, "Cannot stake 0");
        require(msg.sender == voter);
        uint256 _startTimestamp = getNextEpochStart();
        uint256 _oldSupply = _totalSupply[_startTimestamp];
        _totalSupply[_startTimestamp] = _oldSupply + amount;
        _balances[tokenId][_startTimestamp] = _balances[tokenId][_startTimestamp] + amount;
        emit Staked(tokenId, amount);
    }

    function _withdraw(uint256 amount, uint256 tokenId) public nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        require(msg.sender == voter);
        uint256 _startTimestamp = getNextEpochStart();
        // incase of bribe contract reset in gauge proxy
        if (amount <= _balances[tokenId][_startTimestamp]) {
            uint256 _oldSupply = _totalSupply[_startTimestamp];
            uint256 _oldBalance = _balances[tokenId][_startTimestamp];
            _totalSupply[_startTimestamp] = _oldSupply - amount;
            _balances[tokenId][_startTimestamp] = _oldBalance - amount;
            emit Withdrawn(tokenId, amount);
        }
    }

    function getReward(uint256 tokenId, address[] calldata tokens) external nonReentrant {
        require(IVotingEscrow(ve).isApprovedOrOwner(msg.sender, tokenId));
        _getReward(tokenId, tokens);
    }

    function getRewardForOwner(uint256 tokenId, address[] calldata tokens) public nonReentrant {
        require(msg.sender == voter);
        _getReward(tokenId, tokens);
    }

    function _getReward(uint256 tokenId, address[] calldata tokens) internal {
        uint256 _endTimestamp = getNextEpochStart();
        uint256 reward = 0;

        IVotingEscrow _ve = IVotingEscrow(ve);
        address _receiver = _ve.ownerOf(tokenId);

        for (uint256 i = tokens.length; i != 0; ) {
            unchecked {
                --i;
            }
            address _rewardToken = tokens[i];
            reward = earned(tokenId, _rewardToken);
            if (reward > 0) {
                _reserves[_rewardToken] -= reward;
                IERC20(_rewardToken).safeTransfer(_receiver, reward);
                emit RewardPaid(_receiver, _rewardToken, reward);
            }
            userTimestamp[tokenId][_rewardToken] = _endTimestamp;
        }
    }

    function notifyRewardAmount(address _rewardsToken, uint256 reward) external nonReentrant {
        require(isRewardToken[_rewardsToken], "reward token not verified");
        IERC20(_rewardsToken).safeTransferFrom(msg.sender, address(this), reward);

        _reserves[_rewardsToken] += reward;

        uint256 _startTimestamp = getNextEpochStart();
        if (firstBribeTimestamp == 0) {
            firstBribeTimestamp = _startTimestamp;
        }

        uint256 _lastReward = _rewardData[_rewardsToken][_startTimestamp].rewardsPerEpoch;

        _rewardData[_rewardsToken][_startTimestamp].rewardsPerEpoch = _lastReward + reward;
        _rewardData[_rewardsToken][_startTimestamp].lastUpdateTime = block.timestamp;
        _rewardData[_rewardsToken][_startTimestamp].periodFinish = _startTimestamp + EPOCH_DURATION;

        emit RewardAdded(_rewardsToken, reward, _startTimestamp);
    }

    function skim(address _to) external returns (uint256[] memory _amounts) {
        uint256 _numTokens = rewardTokens.length;
        _amounts = new uint256[](_numTokens);
        for (uint256 i = _numTokens; i != 0; ) {
            unchecked {
                --i;
            }
            address _rewardToken = rewardTokens[i];
            uint256 _reserve = _reserves[_rewardToken];
            uint256 _balance = IERC20(_rewardToken).balanceOf(address(this));
            if (_balance > _reserve) {
                uint256 _amount;
                unchecked {
                    _amount = _balance - _reserve;
                }
                _amounts[i] = _amount;
                IERC20(_rewardToken).safeTransfer(_to, _amount);
            }
        }
    }

    function skim(address _rewardsToken, address _to) external returns (uint256 _amount) {
        uint256 _reserve = _reserves[_rewardsToken];
        uint256 _balance = IERC20(_rewardsToken).balanceOf(address(this));
        if (_balance > _reserve) {
            unchecked {
                _amount = _balance - _reserve;
            }
            IERC20(_rewardsToken).safeTransfer(_to, _amount);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /// @notice add rewards tokens
    function addRewards(address[] memory _rewardsToken) public onlyAllowed {
        for (uint256 i = _rewardsToken.length; i != 0; ) {
            unchecked {
                --i;
            }
            _addReward(_rewardsToken[i]);
        }
    }

    /// @notice add a single reward token
    function addReward(address _rewardsToken) public onlyAllowed {
        _addReward(_rewardsToken);
    }

    function _addReward(address _rewardsToken) internal {
        if (!isRewardToken[_rewardsToken]) {
            isRewardToken[_rewardsToken] = true;
            rewardTokens.push(_rewardsToken);
        }
    }

    /// @notice Recover some ERC20 from the contract and updated given bribe
    function recoverERC20AndUpdateData(address tokenAddress, uint256 tokenAmount) external onlyAllowed {
        require(tokenAmount <= IERC20(tokenAddress).balanceOf(address(this)));

        uint256 _startTimestamp = IMinter(minter).active_period() + EPOCH_DURATION;
        uint256 _lastReward = _rewardData[tokenAddress][_startTimestamp].rewardsPerEpoch;
        _rewardData[tokenAddress][_startTimestamp].rewardsPerEpoch = _lastReward - tokenAmount;
        _rewardData[tokenAddress][_startTimestamp].lastUpdateTime = block.timestamp;

        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /// @notice Recover some ERC20 from the contract.
    /// @dev    Be careful --> if called then getReward() at last epoch will fail because some reward are missing!
    ///         Think about calling recoverERC20AndUpdateData()
    function emergencyRecoverERC20(address tokenAddress, uint256 tokenAmount) external onlyAllowed {
        require(tokenAmount <= IERC20(tokenAddress).balanceOf(address(this)));
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setVoter(address _Voter) external onlyOwner {
        require(_Voter != address(0));
        voter = _Voter;
    }

    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0));
        minter = _minter;
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0));
        owner = _owner;
    }

    /* ========== MODIFIERS ========== */

    /* ========== EVENTS ========== */

    event RewardAdded(address rewardToken, uint256 reward, uint256 startTimestamp);
    event Staked(uint256 indexed tokenId, uint256 amount);
    event Withdrawn(uint256 indexed tokenId, uint256 amount);
    event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
    event Recovered(address token, uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint256 constant EPOCH_DURATION = 7 days;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract ERC20Mintable is ERC20Upgradeable {
    uint8 private _decimals;

    function initialize(string memory name, string memory symbol, uint8 decimals_) external initializer {
        __ERC20_init(name, symbol);
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../Bribe.sol";

contract BribeFactory is AccessControlUpgradeable {
    bytes32 public constant BRIBE_ADMIN_ROLE = keccak256("BRIBE_ADMIN");

    address public last_bribe;
    address[] internal _bribes;
    address public voter;

    address[] public defaultRewardToken;

    mapping(address => bool) public isDefaultRewardToken;

    constructor() {}

    function initialize(address _voter, address[] calldata defaultRewardTokens) public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(BRIBE_ADMIN_ROLE, _msgSender());
        voter = _voter;

        // bribe default tokens
        for (uint256 i = 0; i < defaultRewardTokens.length; i++) {
            _pushDefaultRewardToken(defaultRewardTokens[i]);
        }
    }

    /// @notice create a bribe contract
    /// @dev    _owner must be teamMultisig
    function createBribe(address _owner, address _token0, address _token1, string memory _type) external returns (address) {
        if (msg.sender != voter) {
            _checkRole(DEFAULT_ADMIN_ROLE);
        }

        Bribe lastBribe = new Bribe(_owner, voter, address(this), _type);

        if (_token0 != address(0)) lastBribe.addReward(_token0);
        if (_token1 != address(0)) lastBribe.addReward(_token1);

        lastBribe.addRewards(defaultRewardToken);

        last_bribe = address(lastBribe);
        _bribes.push(last_bribe);
        return last_bribe;
    }

    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    ONLY OWNER
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    /// @notice set the bribe factory voter
    function setVoter(address _Voter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_Voter != address(0));
        voter = _Voter;
    }

    function pushDefaultRewardToken(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pushDefaultRewardToken(_token);
    }

    function _pushDefaultRewardToken(address _token) internal {
        require(_token != address(0), "zero address not allowed");
        require(!isDefaultRewardToken[_token], "token already added");
        isDefaultRewardToken[_token] = true;
        defaultRewardToken.push(_token);
    }

    function removeDefaultRewardToken(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(isDefaultRewardToken[_token], "not a default reward token");
        uint256 i = 0;
        for (i; i < defaultRewardToken.length; i++) {
            if (defaultRewardToken[i] == _token) {
                defaultRewardToken[i] = defaultRewardToken[defaultRewardToken.length - 1];
                defaultRewardToken.pop();
                isDefaultRewardToken[_token] = false;
                break;
            }
        }
    }

    /* -----------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
                                    ONLY OWNER or BRIBE ADMIN
    --------------------------------------------------------------------------------
    --------------------------------------------------------------------------------
    ----------------------------------------------------------------------------- */

    /// @notice Add a reward token to a given bribe
    function addRewardToBribe(address _token, address __bribe) external onlyRole(BRIBE_ADMIN_ROLE) {
        IBribe(__bribe).addReward(_token);
    }

    /// @notice Add multiple reward token to a given bribe
    function addRewardsToBribe(address[] memory _token, address __bribe) external onlyRole(BRIBE_ADMIN_ROLE) {
        uint256 i = 0;
        for (i; i < _token.length; i++) {
            IBribe(__bribe).addReward(_token[i]);
        }
    }

    /// @notice Add a reward token to given bribes
    function addRewardToBribes(address _token, address[] memory __bribes) external onlyRole(BRIBE_ADMIN_ROLE) {
        uint256 i = 0;
        for (i; i < __bribes.length; i++) {
            IBribe(__bribes[i]).addReward(_token);
        }
    }

    /// @notice Add multiple reward tokens to given bribes
    function addRewardsToBribes(address[][] memory _token, address[] memory __bribes) external onlyRole(BRIBE_ADMIN_ROLE) {
        uint256 i = 0;
        uint256 k;
        for (i; i < __bribes.length; i++) {
            address _br = __bribes[i];
            for (k = 0; k < _token.length; k++) {
                IBribe(_br).addReward(_token[i][k]);
            }
        }
    }

    /// @notice set a new voter in given bribes
    function setBribeVoter(address[] memory _bribe, address _voter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 i = 0;
        for (i; i < _bribe.length; i++) {
            IBribe(_bribe[i]).setVoter(_voter);
        }
    }

    /// @notice set a new minter in given bribes
    function setBribeMinter(address[] memory _bribe, address _minter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 i = 0;
        for (i; i < _bribe.length; i++) {
            IBribe(_bribe[i]).setMinter(_minter);
        }
    }

    /// @notice set a new owner in given bribes
    function setBribeOwner(address[] memory _bribe, address _owner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 i = 0;
        for (i; i < _bribe.length; i++) {
            IBribe(_bribe[i]).setOwner(_owner);
        }
    }

    /// @notice recover an ERC20 from bribe contracts.
    function recoverERC20From(
        address[] memory _bribe,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 i = 0;
        require(_bribe.length == _tokens.length, "mismatch len");
        require(_tokens.length == _amounts.length, "mismatch len");

        for (i; i < _bribe.length; i++) {
            if (_amounts[i] > 0) IBribe(_bribe[i]).emergencyRecoverERC20(_tokens[i], _amounts[i]);
        }
    }

    /// @notice recover an ERC20 from bribe contracts and update.
    function recoverERC20AndUpdateData(
        address[] memory _bribe,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 i = 0;
        require(_bribe.length == _tokens.length, "mismatch len");
        require(_tokens.length == _amounts.length, "mismatch len");

        for (i; i < _bribe.length; i++) {
            if (_amounts[i] > 0) IBribe(_bribe[i]).emergencyRecoverERC20(_tokens[i], _amounts[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IGauge.sol";
import "../interfaces/IGaugeFactory.sol";
import "../Gauge.sol";

contract GaugeFactory is IGaugeFactory, OwnableUpgradeable {
    address public last_gauge;

    constructor() {}

    function initialize() public initializer {
        __Ownable_init();
    }

    function createGauge(
        address _rewardToken,
        address _ve,
        address _token,
        address _distribution,
        address _internal_bribe,
        address _external_bribe,
        bool _isPair
    ) external returns (address) {
        last_gauge = address(new Gauge(_rewardToken, _ve, _token, _distribution, _internal_bribe, _external_bribe, _isPair));
        return last_gauge;
    }

    function setDistribution(address _gauge, address _newDistribution) external onlyOwner {
        IGauge(_gauge).setDistribution(_newDistribution);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../interfaces/IPairFactory.sol";
import "../interfaces/IPair.sol";

contract PairFactory is IPairFactory, OwnableUpgradeable, PausableUpgradeable {
    using ClonesUpgradeable for address;
    using MathUpgradeable for uint256;

    uint256 public constant FEE_PRECISION = 1e18;
    uint256 public constant MAX_FEE = 0.5e16; // 0.5%

    address public pairImplementation;

    uint256 public stableFee;
    uint256 public volatileFee;

    address public feeManager;
    address public pendingFeeManager;
    address public pairManager;

    mapping(address => mapping(address => mapping(bool => address))) public getPair;
    mapping(address => bool) public isPair; // simplified check if its a pair, given that `stable` flag might not be available in peripherals
    mapping(address => bool) private _privileged;

    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, bool stable, address pair, uint256);
    event PrivilegedAccountStatusUpdated(address indexed account, bool _added);

    modifier onlyFeeManager() {
        require(msg.sender == feeManager);
        _;
    }

    modifier onlyPairManager() {
        require(msg.sender == pairManager || pairManager == address(0));
        _;
    }

    function initialize(address _pairImplementation) public initializer {
        __Ownable_init();
        pairImplementation = _pairImplementation;
        feeManager = msg.sender;
        pairManager = msg.sender;
        stableFee = 0.04e16; // 0.04%
        volatileFee = 0.18e16; // 0.18%
    }

    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    function setPairImplementationAddress(address _pairImplementation) public onlyOwner {
        pairImplementation = _pairImplementation;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function pairs() external view returns (address[] memory) {
        return allPairs;
    }

    function setFeeManager(address _feeManager) external onlyFeeManager {
        pendingFeeManager = _feeManager;
    }

    function setPairManager(address _pairManager) external onlyOwner {
        pairManager = _pairManager;
    }

    function acceptFeeManager() external {
        require(msg.sender == pendingFeeManager);
        feeManager = pendingFeeManager;
    }

    function setFee(bool _stable, uint256 _fee) external onlyFeeManager {
        require(_fee <= MAX_FEE, "MF");
        require(_fee != 0);
        if (_stable) {
            stableFee = _fee;
        } else {
            volatileFee = _fee;
        }
    }

    function updatePrivilegedAccount(address _account, bool _addToPrivileged) external onlyFeeManager {
        require(_privileged[_account] != _addToPrivileged);
        _privileged[_account] = _addToPrivileged;
        emit PrivilegedAccountStatusUpdated(_account, _addToPrivileged);
    }

    function getFee(bool _stable) public view returns (uint256) {
        return _stable ? stableFee : volatileFee;
    }

    function getFeeAmount(bool _stable, uint256 _amount, address _account) external view returns (uint256) {
        if (_privileged[_account]) return 0;
        return getFee(_stable).mulDiv(_amount, FEE_PRECISION);
    }

    function createPair(address tokenA, address tokenB, bool stable) external onlyPairManager returns (address pair) {
        require(tokenA != tokenB, "IA"); // Pair: IDENTICAL_ADDRESSES
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "ZA"); // Pair: ZERO_ADDRESS
        require(getPair[token0][token1][stable] == address(0), "PE"); // Pair: PAIR_EXISTS - single check is sufficient
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, stable)); // notice salt includes stable as well, 3 parameters
        pair = pairImplementation.cloneDeterministic(salt);
        IPair(pair).initialize(token0, token1, stable);
        getPair[token0][token1][stable] = pair;
        getPair[token1][token0][stable] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        isPair[pair] = true;
        emit PairCreated(token0, token1, stable, pair, allPairs.length);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IBribe.sol";
import "./interfaces/IPair.sol";
import "./interfaces/IRewarder.sol";
import "./Epoch.sol";

contract Gauge is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public isForPair;

    IERC20 public rewardToken;
    IERC20 public _VE;
    IERC20 public TOKEN;

    address public DISTRIBUTION;
    address public gaugeRewarder;
    address public internal_bribe;
    address public external_bribe;

    uint256 public rewarderPid;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    uint256 public fees0;
    uint256 public fees1;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public _totalSupply;
    mapping(address => uint256) public _balances;

    event RewardAdded(uint256 reward);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Harvest(address indexed user, uint256 reward);
    event ClaimFees(address indexed from, uint256 claimed0, uint256 claimed1);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyDistribution() {
        require(msg.sender == DISTRIBUTION, "Caller is not RewardsDistribution contract");
        _;
    }

    constructor(
        address _rewardToken,
        address _ve,
        address _token,
        address _distribution,
        address _internal_bribe,
        address _external_bribe,
        bool _isForPair
    ) {
        rewardToken = IERC20(_rewardToken); // main reward
        _VE = IERC20(_ve); // vested
        TOKEN = IERC20(_token); // underlying (LP)
        DISTRIBUTION = _distribution; // distro address (voter)

        internal_bribe = _internal_bribe; // lp fees goes here
        external_bribe = _external_bribe; // bribe fees goes here

        isForPair = _isForPair; // pair boolean, if false no claim_fees
    }

    ///@notice set distribution address (should be GaugeProxyL2)
    function setDistribution(address _distribution) external onlyOwner {
        require(_distribution != address(0), "zero addr");
        require(_distribution != DISTRIBUTION, "same addr");
        DISTRIBUTION = _distribution;
    }

    ///@notice set gauge rewarder address
    function setGaugeRewarder(address _gaugeRewarder) external onlyOwner {
        require(_gaugeRewarder != address(0), "zero addr");
        require(_gaugeRewarder != gaugeRewarder, "same addr");
        gaugeRewarder = _gaugeRewarder;
    }

    ///@notice set extra rewarder pid
    function setRewarderPid(uint256 _pid) external onlyOwner {
        require(_pid >= 0, "zero");
        require(_pid != rewarderPid, "same pid");
        rewarderPid = _pid;
    }

    ///@notice total supply held
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    ///@notice balance of a user
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    ///@notice last time reward
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    ///@notice reward for a single token
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        } else {
            return rewardPerTokenStored.add(lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply));
        }
    }

    ///@notice see earned rewards for user
    function earned(address account) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    ///@notice get total reward for the duration
    function rewardForDuration() external view returns (uint256) {
        return rewardRate.mul(EPOCH_DURATION);
    }

    ///@notice deposit all TOKEN of msg.sender
    function depositAll() external {
        _deposit(TOKEN.balanceOf(msg.sender), msg.sender);
    }

    ///@notice deposit amount TOKEN
    function deposit(uint256 amount) external {
        _deposit(amount, msg.sender);
    }

    ///@notice deposit internal
    function _deposit(uint256 amount, address account) internal nonReentrant updateReward(account) {
        require(amount > 0, "deposit(Gauge): cannot stake 0");

        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);

        TOKEN.safeTransferFrom(account, address(this), amount);

        if (address(gaugeRewarder) != address(0)) {
            IRewarder(gaugeRewarder).onReward(rewarderPid, account, account, 0, _balances[account]);
        }

        emit Deposit(account, amount);
    }

    ///@notice withdraw all token
    function withdrawAll() external {
        _withdraw(_balances[msg.sender]);
    }

    ///@notice withdraw a certain amount of TOKEN
    function withdraw(uint256 amount) external {
        _withdraw(amount);
    }

    ///@notice withdraw internal
    function _withdraw(uint256 amount) internal nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(_totalSupply.sub(amount) >= 0, "supply < 0");
        require(_balances[msg.sender] > 0, "no balances");

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        if (address(gaugeRewarder) != address(0)) {
            IRewarder(gaugeRewarder).onReward(rewarderPid, msg.sender, msg.sender, 0, _balances[msg.sender]);
        }

        TOKEN.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    ///@notice withdraw all TOKEN and harvest rewardToken
    function withdrawAllAndHarvest() external {
        _withdraw(_balances[msg.sender]);
        getReward();
    }

    ///@notice User harvest function
    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit Harvest(msg.sender, reward);
        }

        if (gaugeRewarder != address(0)) {
            IRewarder(gaugeRewarder).onReward(rewarderPid, msg.sender, msg.sender, reward, _balances[msg.sender]);
        }
    }

    function _periodFinish() external view returns (uint256) {
        return periodFinish;
    }

    /// @dev Receive rewards from distribution
    function notifyRewardAmount(address token, uint256 reward) external nonReentrant onlyDistribution updateReward(address(0)) {
        require(token == address(rewardToken));
        rewardToken.safeTransferFrom(DISTRIBUTION, address(this), reward);

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(EPOCH_DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(EPOCH_DURATION);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardToken.balanceOf(address(this));
        require(rewardRate <= balance.div(EPOCH_DURATION), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(EPOCH_DURATION);
        emit RewardAdded(reward);
    }

    function claimFees() external nonReentrant returns (uint256 claimed0, uint256 claimed1) {
        return _claimFees();
    }

    function _claimFees() internal returns (uint256 claimed0, uint256 claimed1) {
        if (!isForPair) {
            return (0, 0);
        }
        address _token = address(TOKEN);

        (claimed0, claimed1) = IPair(_token).claimFees();

        if (claimed0 != 0 || claimed1 != 0) {
            uint256 _fees0 = fees0 + claimed0;
            uint256 _fees1 = fees1 + claimed1;
            (address _token0, address _token1) = IPair(_token).tokens();

            if (_fees0 != 0) {
                fees0 = 0;
                IERC20(_token0).approve(internal_bribe, _fees0);
                IBribe(internal_bribe).notifyRewardAmount(_token0, _fees0);
            } else {
                fees0 = _fees0;
            }

            if (_fees1 != 0) {
                fees1 = 0;
                IERC20(_token1).approve(internal_bribe, _fees1);
                IBribe(internal_bribe).notifyRewardAmount(_token1, _fees1);
            } else {
                fees1 = _fees1;
            }

            emit ClaimFees(msg.sender, claimed0, claimed1);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBribe {
    struct Reward {
        uint256 periodFinish;
        uint256 rewardsPerEpoch;
        uint256 lastUpdateTime;
    }

    function _deposit(uint256 amount, uint256 tokenId) external;

    function _withdraw(uint256 amount, uint256 tokenId) external;

    function addReward(address) external;

    function balanceOfAt(uint256 tokenId, uint256 _timestamp) external view returns (uint256);

    function earned(uint256 tokenId, address _rewardToken) external view returns (uint256);

    function emergencyRecoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function firstBribeTimestamp() external view returns (uint256);

    function getEpochStart() external view returns (uint256);

    function getNextEpochStart() external view returns (uint256);

    function getRewardForOwner(uint256 tokenId, address[] memory tokens) external;

    function notifyRewardAmount(address token, uint256 amount) external;

    function recoverERC20AndUpdateData(address tokenAddress, uint256 tokenAmount) external;

    function rewardData(address _token, uint256 _timestamp) external view returns (Reward memory);

    function rewardTokens(uint256 _index) external view returns (address);

    function rewardsListLength() external view returns (uint256);

    function setMinter(address _minter) external;

    function setOwner(address _owner) external;

    function setVoter(address _voter) external;

    function totalSupplyAt(uint256 _timestamp) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBribeDistribution {
    function _deposit(uint256 amount, uint256 tokenId) external;

    function _withdraw(uint256 amount, uint256 tokenId) external;

    function getRewardForOwner(uint256 tokenId, address[] memory tokens) external;

    function notifyRewardAmount(address token, uint256 amount) external;

    function left(address token) external view returns (uint256);

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;

    function setOwner(address _owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBribeFactory {
    function createInternalBribe(address[] memory) external returns (address);

    function createExternalBribe(address[] memory) external returns (address);

    function createBribe(address _owner, address _token0, address _token1, string memory _type) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGauge {
    function notifyRewardAmount(address token, uint256 amount) external;

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);

    function left(address token) external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

    function isForPair() external view returns (bool);

    function totalSupply() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function setDistribution(address _distro) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGaugeFactory {
    function createGauge(
        address _rewardToken,
        address _ve,
        address _token,
        address _distribution,
        address _internal_bribe,
        address _external_bribe,
        bool _isPair
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMinter {
    function update_period() external returns (uint256);

    function check() external view returns (bool);

    function period() external view returns (uint256);

    function active_period() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPair {
    function initialize(address _token0, address _token1, bool _stable) external;

    function metadata() external view returns (uint256 dec0, uint256 dec1, uint256 r0, uint256 r1, bool st, address t0, address t1);

    function claimFees() external returns (uint256, uint256);

    function tokens() external view returns (address, address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function mint(address to) external returns (uint256 liquidity);

    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast);

    function getAmountOut(uint256, address) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function claimable0(address _user) external view returns (uint256);

    function claimable1(address _user) external view returns (uint256);

    function stable() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPairCallee {
    function hook(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPairFactory {
    function allPairsLength() external view returns (uint256);

    function isPair(address pair) external view returns (bool);

    function allPairs(uint256 index) external view returns (address);

    function getPair(address tokenA, address token, bool stable) external view returns (address);

    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);

    function getFeeAmount(bool _stable, uint256 _amount, address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPearl {
    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function mint(address, uint256) external returns (bool);

    function minter() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewarder {
    function onReward(uint256 pid, address user, address recipient, uint256 amount, uint256 newLpAmount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardsDistributor {
    function checkpoint_token() external;

    function voting_escrow() external view returns (address);

    function checkpoint_total_supply() external;

    function claimable(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRouter {
    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVeArtProxy {
    function _tokenURI(
        uint256 _tokenId,
        uint256 _balanceOf,
        uint256 _locked_end,
        uint256 _value
    ) external pure returns (string memory output);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVoter {
    function _ve() external view returns (address);

    function governor() external view returns (address);

    function gauges(address _pair) external view returns (address);

    function factory() external view returns (address);

    function minter() external view returns (address);

    function emergencyCouncil() external view returns (address);

    function emitDeposit(uint256 _tokenId, address account, uint256 amount) external;

    function emitWithdraw(uint256 _tokenId, address account, uint256 amount) external;

    function isWhitelisted(address token) external view returns (bool);

    function notifyRewardAmount(uint256 amount) external;

    function distribute(address _gauge) external;

    function distributeAll() external;

    function distribute(uint256 start, uint256 finiash) external;

    function distributeFees(address[] memory _gauges) external;

    function internal_bribes(address _gauge) external view returns (address);

    function external_bribes(address _gauge) external view returns (address);

    function usedWeights(uint256 id) external view returns (uint256);

    function lastVoted(uint256 id) external view returns (uint256);

    function poolVote(uint256 id, uint256 _index) external view returns (address _pair);

    function votes(uint256 id, address _pool) external view returns (uint256 votes);

    function poolVoteLength(uint256 tokenId) external view returns (uint256);

    function length() external view returns (uint256);

    function getIncentivizedPools() external view returns (address[] memory);

    function isBribe(address _bribe) external view returns (bool);

    function reset(uint256 _tokenId) external;

    function poke(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721, IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IVotingEscrow is IERC721, IERC721Metadata {
    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function create_lock_for(uint256 _value, uint256 _lock_duration, address _to) external returns (uint256);

    function locked(uint256 id) external view returns (LockedBalance memory);

    function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex) external view returns (uint256);

    function token() external view returns (address);

    function team() external returns (address);

    function epoch() external view returns (uint256);

    function point_history(uint256 loc) external view returns (Point memory);

    function user_point_history(uint256 tokenId, uint256 loc) external view returns (Point memory);

    function user_point_epoch(uint256 tokenId) external view returns (uint256);

    function ownerOf(uint256) external view returns (address);

    function isApprovedOrOwner(address, uint256) external view returns (bool);

    function transferFrom(address, address, uint256) external;

    function voted(uint256) external view returns (bool);

    function voting(uint256 tokenId) external;

    function voter() external view returns (address);

    function abstain(uint256 tokenId) external;

    function checkpoint() external;

    function deposit_for(uint256 tokenId, uint256 value) external;

    function balanceOfNFT(uint256 _id) external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function supply() external view returns (uint256);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "./interfaces/IMinter.sol";
import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/IPearl.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingEscrow.sol";
import "./Epoch.sol";

// codifies the minting rules as per ve(3,3), abstracted from the token to support any token that allows minting
contract Minter is IMinter, OwnableUpgradeable {
    uint256 public constant PRECISION = 1e3;
    uint256 public constant LOCK = EPOCH_DURATION * 52 * 2; // 2 years
    uint256 public constant MAX_TEAM_RATE = 0.05e3; // 5%

    bool public isFirstMint;

    uint256 public EMISSION;
    uint256 public TAIL_EMISSION;
    uint256 public REBASEMAX;
    uint256 public REBASESLOPE;
    uint256 public teamRate;

    uint256 public weekly;
    uint256 public active_period;

    address internal _initializer;
    address public team;
    address public pendingTeam;

    IPearl public _pearl;
    IVoter public _voter;
    IVotingEscrow public _ve;
    IVotingEscrow public _oldVE;
    IRewardsDistributor public _rewards_distributor;

    event Mint(address indexed sender, uint256 weekly, uint256 circulating_supply, uint256 circulating_emission);

    constructor() {}

    function initialize(
        address __voter, // the voting & distribution system
        address __ve, // the ve(3,3) system that will be locked into
        address __oldVE,
        address __rewards_distributor // the distribution system that ensures users aren't diluted
    ) public initializer {
        __Ownable_init();

        _initializer = msg.sender;
        team = msg.sender;

        teamRate = 25;

        EMISSION = 990;
        TAIL_EMISSION = 2;
        REBASEMAX = 500;
        REBASESLOPE = 625;

        _pearl = IPearl(IVotingEscrow(__ve).token());
        _voter = IVoter(__voter);
        _ve = IVotingEscrow(__ve);
        _oldVE = IVotingEscrow(__oldVE);
        _rewards_distributor = IRewardsDistributor(__rewards_distributor);

        active_period = ((block.timestamp + (2 * EPOCH_DURATION)) / EPOCH_DURATION) * EPOCH_DURATION;

        if (__oldVE != address(0)) {
            weekly = Minter(IVoter(_oldVE.voter()).minter()).weekly();
        } else {
            weekly = 2_600_000 * 1e18; // represents a starting weekly emission of 2.6M PEARL
            isFirstMint = true;
        }
    }

    function _initialize() external {
        require(_initializer == msg.sender);
        _initializer = address(0);
        active_period = ((block.timestamp) / EPOCH_DURATION) * EPOCH_DURATION; // allow minter.update_period() to mint new emissions THIS Thursday
    }

    function setTeam(address _team) external {
        require(msg.sender == team, "not team");
        pendingTeam = _team;
    }

    function acceptTeam() external {
        require(msg.sender == pendingTeam, "not pending team");
        team = pendingTeam;
    }

    function setVoter(address __voter) external {
        require(__voter != address(0));
        require(msg.sender == team, "not team");
        _voter = IVoter(__voter);
    }

    function setTeamRate(uint256 _teamRate) external {
        require(msg.sender == team, "not team");
        require(_teamRate <= MAX_TEAM_RATE, "rate too high");
        teamRate = _teamRate;
    }

    function setEmission(uint256 _emission) external {
        require(msg.sender == team, "not team");
        require(_emission <= PRECISION, "rate too high");
        EMISSION = _emission;
    }

    function setRebase(uint256 _max, uint256 _slope) external {
        require(msg.sender == team, "not team");
        require(_max <= PRECISION, "rate too high");
        REBASEMAX = _max;
        REBASESLOPE = _slope;
    }

    // calculate circulating supply as total token supply - locked supply
    function circulating_supply() public view returns (uint256 _circulating) {
        unchecked {
            address oldVE = address(_oldVE);
            _circulating = _pearl.totalSupply() - _pearl.balanceOf(address(_ve));
            if (oldVE != address(0)) {
                _circulating = _circulating - _pearl.balanceOf(oldVE);
            }
        }
    }

    // emission calculation is 1% of available supply to mint adjusted by circulating / total supply
    function calculate_emission() public view returns (uint256) {
        return (weekly * EMISSION) / PRECISION;
    }

    // weekly emission takes the max of calculated (aka target) emission versus circulating tail end emission
    function weekly_emission() public view returns (uint256) {
        return MathUpgradeable.max(calculate_emission(), circulating_emission());
    }

    // calculates tail end (infinity) emissions as 0.2% of total supply
    function circulating_emission() public view returns (uint256) {
        return (circulating_supply() * TAIL_EMISSION) / PRECISION;
    }

    // calculate the rebase protection rate, which is to protect against inflation
    function calculate_rebase(uint256 _weeklyMint) public view returns (uint256) {
        uint256 _veTotal = _pearl.balanceOf(address(_ve));
        uint256 _pearlTotal = _pearl.totalSupply();

        uint256 lockedShare = (_veTotal * REBASESLOPE) / _pearlTotal;
        if (lockedShare >= REBASEMAX) {
            lockedShare = REBASEMAX;
        }

        return (_weeklyMint * lockedShare) / PRECISION;
    }

    // update period can only be called once per cycle (1 week)
    function update_period() external returns (uint256) {
        uint256 _period = active_period;
        if (block.timestamp >= _period + EPOCH_DURATION && _initializer == address(0)) {
            // only trigger if new week
            _period = (block.timestamp / EPOCH_DURATION) * EPOCH_DURATION;
            active_period = _period;

            if (!isFirstMint) {
                weekly = weekly_emission();
            } else {
                isFirstMint = false;
            }

            uint256 _rebase = calculate_rebase(weekly);
            uint256 _teamEmissions = (weekly * teamRate) / PRECISION;
            uint256 _required = weekly;

            uint256 _gauge = weekly - _rebase - _teamEmissions;

            uint256 _balanceOf = _pearl.balanceOf(address(this));
            if (_balanceOf < _required) {
                _pearl.mint(address(this), _required - _balanceOf);
            }

            require(_pearl.transfer(team, _teamEmissions));

            require(_pearl.transfer(address(_rewards_distributor), _rebase));
            _rewards_distributor.checkpoint_token(); // checkpoint token balance that was just minted in rewards distributor
            _rewards_distributor.checkpoint_total_supply(); // checkpoint supply

            _pearl.approve(address(_voter), _gauge);
            _voter.notifyRewardAmount(_gauge);

            emit Mint(msg.sender, weekly, circulating_supply(), circulating_emission());
        }
        return _period;
    }

    function check() external view returns (bool) {
        uint256 _period = active_period;
        return (block.timestamp >= _period + EPOCH_DURATION && _initializer == address(0));
    }

    function period() external view returns (uint256) {
        return (block.timestamp / EPOCH_DURATION) * EPOCH_DURATION;
    }

    function nextPeriod() external view returns (uint256) {
        return active_period + EPOCH_DURATION;
    }

    function setRewardDistributor(address _rewardDistro) external {
        require(msg.sender == team);
        _rewards_distributor = IRewardsDistributor(_rewardDistro);
    }
}

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @title Multicall2 - Aggregate results from multiple read-only function calls
/// @author Michael Elliot <[email protected]>
/// @author Joshua Levine <[email protected]>
/// @author Nick Johnson <[email protected]>

contract Multicall {
    struct Call {
        address target;
        bytes callData;
    }
    struct Result {
        bool success;
        bytes returnData;
    }

    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success, "Multicall aggregate: call failed");
            returnData[i] = ret;
        }
    }

    function blockAndAggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData) {
        (blockNumber, blockHash, returnData) = tryBlockAndAggregate(true, calls);
    }

    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    function getBlockNumber() public view returns (uint256 blockNumber) {
        blockNumber = block.number;
    }

    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }

    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }

    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }

    function tryAggregate(bool requireSuccess, Call[] memory calls) public returns (Result[] memory returnData) {
        returnData = new Result[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);

            if (requireSuccess) {
                require(success, "Multicall2 aggregate: call failed");
            }

            returnData[i] = Result(success, ret);
        }
    }

    function tryBlockAndAggregate(
        bool requireSuccess,
        Call[] memory calls
    ) public returns (uint256 blockNumber, bytes32 blockHash, Result[] memory returnData) {
        blockNumber = block.number;
        blockHash = blockhash(block.number);
        returnData = tryAggregate(requireSuccess, calls);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "contracts/interfaces/IPair.sol";
import "contracts/interfaces/IPairCallee.sol";
import "contracts/interfaces/IPairFactory.sol";
import "contracts/PairFees.sol";

// The base pair of pools, either stable or volatile
contract Pair is IPair, Initializable {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    bool public stable;

    uint256 public totalSupply;

    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public balanceOf;

    bytes32 internal DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 internal constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    uint256 internal constant MINIMUM_LIQUIDITY = 10 ** 3;

    address public token0;
    address public token1;
    address public fees;
    address factory;

    // Structure to capture time period obervations every 30 minutes, used for local oracles
    struct Observation {
        uint256 timestamp;
        uint256 reserve0Cumulative;
        uint256 reserve1Cumulative;
    }

    // Capture oracle reading every 30 minutes
    uint256 constant periodSize = 1800;

    Observation[] public observations;

    uint256 internal decimals0;
    uint256 internal decimals1;

    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public blockTimestampLast;

    uint256 public reserve0CumulativeLast;
    uint256 public reserve1CumulativeLast;

    // index0 and index1 are used to accumulate fees, this is split out from normal trades to keep the swap "clean"
    // this further allows LP holders to easily claim fees for tokens they have/staked
    uint256 public index0;
    uint256 public index1;

    // position assigned to each LP to track their current index0 & index1 vs the global position
    mapping(address => uint256) public supplyIndex0;
    mapping(address => uint256) public supplyIndex1;

    // tracks the amount of unclaimed, but claimable tokens off of fees for token0 and token1
    mapping(address => uint256) public claimable0;
    mapping(address => uint256) public claimable1;

    event Fees(address indexed sender, uint256 amount0, uint256 amount1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint256 reserve0, uint256 reserve1);
    event Claim(address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function initialize(address _token0, address _token1, bool _stable) external initializer {
        factory = msg.sender;
        (token0, token1, stable) = (_token0, _token1, _stable);
        fees = address(new PairFees(_token0, _token1));
        if (_stable) {
            name = string(abi.encodePacked("StableV1 AMM - ", IERC20Metadata(_token0).symbol(), "/", IERC20Metadata(_token1).symbol()));
            symbol = string(abi.encodePacked("sAMM-", IERC20Metadata(_token0).symbol(), "/", IERC20Metadata(_token1).symbol()));
        } else {
            name = string(abi.encodePacked("VolatileV1 AMM - ", IERC20Metadata(_token0).symbol(), "/", IERC20Metadata(_token1).symbol()));
            symbol = string(abi.encodePacked("vAMM-", IERC20Metadata(_token0).symbol(), "/", IERC20Metadata(_token1).symbol()));
        }

        decimals0 = 10 ** IERC20Metadata(_token0).decimals();
        decimals1 = 10 ** IERC20Metadata(_token1).decimals();

        observations.push(Observation(block.timestamp, 0, 0));

        _unlocked = 1;
    }

    // simple re-entrancy check
    uint256 internal _unlocked;
    modifier lock() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    function observationLength() external view returns (uint256) {
        return observations.length;
    }

    function lastObservation() public view returns (Observation memory) {
        return observations[observations.length - 1];
    }

    function metadata() external view returns (uint256 dec0, uint256 dec1, uint256 r0, uint256 r1, bool st, address t0, address t1) {
        return (decimals0, decimals1, reserve0, reserve1, stable, token0, token1);
    }

    function tokens() external view returns (address, address) {
        return (token0, token1);
    }

    // claim accumulated but unclaimed fees (viewable via claimable0 and claimable1)
    function claimFees() external returns (uint256 claimed0, uint256 claimed1) {
        _updateFor(msg.sender);

        claimed0 = claimable0[msg.sender];
        claimed1 = claimable1[msg.sender];

        if (claimed0 != 0 || claimed1 != 0) {
            claimable0[msg.sender] = 0;
            claimable1[msg.sender] = 0;

            PairFees(fees).claimFeesFor(msg.sender, claimed0, claimed1);

            emit Claim(msg.sender, msg.sender, claimed0, claimed1);
        }
    }

    // Accrue fees on token0 and token1
    function _updateFees(uint256 amount0, uint256 amount1) internal {
        if (amount0 != 0) {
            _safeTransfer(token0, fees, amount0); // transfer the fees out to PairFees
            uint256 _ratio = (amount0 * 1e18) / totalSupply; // 1e18 adjustment is removed during claim
            if (_ratio != 0) {
                index0 += _ratio;
            }
        }
        if (amount1 != 0) {
            _safeTransfer(token1, fees, amount1); // transfer the fees out to PairFees
            uint256 _ratio = (amount1 * 1e18) / totalSupply; // 1e18 adjustment is removed during claim
            if (_ratio != 0) {
                index1 += _ratio;
            }
        }
        if (amount0 != 0 || amount1 != 0) {
            PairFees(fees).notifyFeeAmounts(amount0, amount1);
            emit Fees(msg.sender, amount0, amount1);
        }
    }

    // this function MUST be called on any balance changes, otherwise can be used to infinitely claim fees
    // Fees are segregated from core funds, so fees can never put liquidity at risk
    function _updateFor(address recipient) internal {
        uint256 _supplied = balanceOf[recipient]; // get LP balance of `recipient`
        if (_supplied != 0) {
            uint256 _supplyIndex0 = supplyIndex0[recipient]; // get last adjusted index0 for recipient
            uint256 _supplyIndex1 = supplyIndex1[recipient];
            uint256 _index0 = index0; // get global index0 for accumulated fees
            uint256 _index1 = index1;
            supplyIndex0[recipient] = _index0; // update user current position to global position
            supplyIndex1[recipient] = _index1;
            uint256 _delta0 = _index0 - _supplyIndex0; // see if there is any difference that need to be accrued
            uint256 _delta1 = _index1 - _supplyIndex1;
            if (_delta0 != 0) {
                uint256 _share = (_supplied * _delta0) / 1e18; // add accrued difference for each supplied token
                claimable0[recipient] += _share;
            }
            if (_delta1 != 0) {
                uint256 _share = (_supplied * _delta1) / 1e18;
                claimable1[recipient] += _share;
            }
        } else {
            supplyIndex0[recipient] = index0; // new users are set to the default global state
            supplyIndex1[recipient] = index1;
        }
    }

    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint256 balance0, uint256 balance1, uint256 _reserve0, uint256 _reserve1) internal {
        uint256 blockTimestamp = block.timestamp;
        uint256 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed != 0 && _reserve0 != 0 && _reserve1 != 0) {
            reserve0CumulativeLast += _reserve0 * timeElapsed;
            reserve1CumulativeLast += _reserve1 * timeElapsed;
        }

        Observation memory _point = lastObservation();
        timeElapsed = blockTimestamp - _point.timestamp; // compare the last observation with current timestamp, if greater than 30 minutes, record a new event
        if (timeElapsed > periodSize) {
            observations.push(Observation(blockTimestamp, reserve0CumulativeLast, reserve1CumulativeLast));
        }
        reserve0 = balance0;
        reserve1 = balance1;
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices()
        public
        view
        returns (uint256 reserve0Cumulative, uint256 reserve1Cumulative, uint256 blockTimestamp)
    {
        blockTimestamp = block.timestamp;
        reserve0Cumulative = reserve0CumulativeLast;
        reserve1Cumulative = reserve1CumulativeLast;

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) = getReserves();
        if (_blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint256 timeElapsed = blockTimestamp - _blockTimestampLast;
            reserve0Cumulative += _reserve0 * timeElapsed;
            reserve1Cumulative += _reserve1 * timeElapsed;
        }
    }

    // gives the current twap price measured from amountIn * tokenIn gives amountOut
    function current(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut) {
        Observation memory _observation = lastObservation();
        (uint256 reserve0Cumulative, uint256 reserve1Cumulative, ) = currentCumulativePrices();
        if (block.timestamp == _observation.timestamp) {
            _observation = observations[observations.length - 2];
        }

        uint256 timeElapsed = block.timestamp - _observation.timestamp;
        uint256 _reserve0 = (reserve0Cumulative - _observation.reserve0Cumulative) / timeElapsed;
        uint256 _reserve1 = (reserve1Cumulative - _observation.reserve1Cumulative) / timeElapsed;
        amountOut = _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    // as per `current`, however allows user configured granularity, up to the full window size
    function quote(address tokenIn, uint256 amountIn, uint256 granularity) external view returns (uint256 amountOut) {
        uint256[] memory _prices = sample(tokenIn, amountIn, granularity, 1);
        uint256 priceAverageCumulative;
        for (uint256 i = _prices.length; i != 0; ) {
            unchecked {
                --i;
            }
            priceAverageCumulative += _prices[i];
        }
        return priceAverageCumulative / granularity;
    }

    // returns a memory set of twap prices
    function prices(address tokenIn, uint256 amountIn, uint256 points) external view returns (uint256[] memory) {
        return sample(tokenIn, amountIn, points, 1);
    }

    function sample(address tokenIn, uint256 amountIn, uint256 points, uint256 window) public view returns (uint256[] memory) {
        uint256[] memory _prices = new uint256[](points);

        uint256 length = observations.length - 1;
        uint256 nextIndex;
        uint256 index = 0;

        for (uint256 i = length - (points * window); i < length; ) {
            unchecked {
                nextIndex = i + window;
            }
            uint256 timeElapsed = observations[nextIndex].timestamp - observations[i].timestamp;
            uint256 _reserve0 = (observations[nextIndex].reserve0Cumulative - observations[i].reserve0Cumulative) / timeElapsed;
            uint256 _reserve1 = (observations[nextIndex].reserve1Cumulative - observations[i].reserve1Cumulative) / timeElapsed;
            _prices[index] = _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
            // index < length; length cannot overflow
            unchecked {
                ++index;
            }
            i = nextIndex;
        }
        return _prices;
    }

    // this low-level function should be called by addLiquidity functions in Router.sol, which performs important safety checks
    // standard uniswap v2 implementation
    function mint(address to /* lock*/) external returns (uint256 liquidity) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        uint256 _balance0 = IERC20(token0).balanceOf(address(this));
        uint256 _balance1 = IERC20(token1).balanceOf(address(this));
        uint256 _amount0 = _balance0 - _reserve0;
        uint256 _amount1 = _balance1 - _reserve1;

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(_amount0 * _amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min((_amount0 * _totalSupply) / _reserve0, (_amount1 * _totalSupply) / _reserve1);
        }
        require(liquidity != 0, "ILM"); // Pair: INSUFFICIENT_LIQUIDITY_MINTED
        _mint(to, liquidity);

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, _amount0, _amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // standard uniswap v2 implementation
    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        (address _token0, address _token1) = (token0, token1);
        uint256 _balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 _balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 _liquidity = balanceOf[address(this)];

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (_liquidity * _balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (_liquidity * _balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 != 0 && amount1 != 0, "ILB"); // Pair: INSUFFICIENT_LIQUIDITY_BURNED
        _burn(address(this), _liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        _balance0 = IERC20(_token0).balanceOf(address(this));
        _balance1 = IERC20(_token1).balanceOf(address(this));

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external lock {
        require(!Pausable(factory).paused());
        require(amount0Out != 0 || amount1Out != 0, "IOA"); // Pair: INSUFFICIENT_OUTPUT_AMOUNT
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "IL"); // Pair: INSUFFICIENT_LIQUIDITY

        uint256 _balance0;
        uint256 _balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            (address _token0, address _token1) = (token0, token1);
            require(to != _token0 && to != _token1, "IT"); // Pair: INVALID_TO
            if (amount0Out != 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out != 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length != 0) IPairCallee(to).hook(msg.sender, amount0Out, amount1Out, data); // callback, used for flash loans
            _balance0 = IERC20(_token0).balanceOf(address(this));
            _balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = _balance0 > _reserve0 - amount0Out ? _balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = _balance1 > _reserve1 - amount1Out ? _balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In != 0 || amount1In != 0, "IIA"); // Pair: INSUFFICIENT_INPUT_AMOUNT
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            (address _token0, address _token1) = (token0, token1);
            _updateFees(
                IPairFactory(factory).getFeeAmount(stable, amount0In, msg.sender),
                IPairFactory(factory).getFeeAmount(stable, amount1In, msg.sender)
            ); // accrue fees for token0 and token1 and move them out of pool
            //if (amount0In > 0) _update0(IPairFactory(factory).getFeeAmount(stable, amount0In, msg.sender)); // accrue fees for token0 and move them out of pool
            //if (amount1In > 0) _update1(IPairFactory(factory).getFeeAmount(stable, amount1In, msg.sender)); // accrue fees for token1 and move them out of pool
            //PairFees(fees).notifyFeeAmounts(amount0In, amount1In);
            _balance0 = IERC20(_token0).balanceOf(address(this)); // since we removed tokens, we need to reconfirm balances, can also simply use previous balance - amountIn/ 10000, but doing balanceOf again as safety check
            _balance1 = IERC20(_token1).balanceOf(address(this));
            // The curve, either x3y+y3x for stable pools, or x*y for volatile pools
            require(_k(_balance0, _balance1) >= _k(_reserve0, _reserve1), "K"); // Pair: K
        }

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        (address _token0, address _token1) = (token0, token1);
        PairFees(fees).skim();
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - (reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - (reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        return (x0 * ((((y * y) / 1e18) * y) / 1e18)) / 1e18 + (((((x0 * x0) / 1e18) * x0) / 1e18) * y) / 1e18;
    }

    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        return (3 * x0 * ((y * y) / 1e18)) / 1e18 + ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    function _get_y(uint256 x0, uint256 xy, uint256 y) internal pure returns (uint256) {
        for (uint256 i = 255; i != 0; ) {
            uint256 y_prev = y;
            uint256 k = _f(x0, y);
            if (k < xy) {
                uint256 dy = ((xy - k) * 1e18) / _d(x0, y);
                y = y + dy;
            } else {
                uint256 dy = ((k - xy) * 1e18) / _d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
            unchecked {
                --i;
            }
        }
        return y;
    }

    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        amountIn -= IPairFactory(factory).getFeeAmount(stable, amountIn, msg.sender); // remove fee from amount received
        return _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    function _getAmountOut(uint256 amountIn, address tokenIn, uint256 _reserve0, uint256 _reserve1) internal view returns (uint256) {
        if (stable) {
            uint256 xy = _k(_reserve0, _reserve1);
            _reserve0 = (_reserve0 * 1e18) / decimals0;
            _reserve1 = (_reserve1 * 1e18) / decimals1;
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            amountIn = tokenIn == token0 ? (amountIn * 1e18) / decimals0 : (amountIn * 1e18) / decimals1;
            uint256 y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
            return (y * (tokenIn == token0 ? decimals1 : decimals0)) / 1e18;
        } else {
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            return (amountIn * reserveB) / (reserveA + amountIn);
        }
    }

    function _k(uint256 x, uint256 y) internal view returns (uint256) {
        if (stable) {
            uint256 _x = (x * 1e18) / decimals0;
            uint256 _y = (y * 1e18) / decimals1;
            uint256 _a = (_x * _y) / 1e18;
            uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
            return (_a * _b) / 1e18; // x3y+y3x >= k
        } else {
            return x * y; // xy >= k
        }
    }

    function _mint(address dst, uint256 amount) internal {
        _updateFor(dst); // balances must be updated on mint/burn/transfer
        totalSupply += amount;
        balanceOf[dst] += amount;
        emit Transfer(address(0), dst, amount);
    }

    function _burn(address dst, uint256 amount) internal {
        _updateFor(dst);
        totalSupply -= amount;
        balanceOf[dst] -= amount;
        emit Transfer(dst, address(0), amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, "Pair: EXPIRED");
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "Pair: INVALID_SIGNATURE");
        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    function transferFrom(address src, address dst, uint256 amount) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowance[src][spender];

        if (spender != src && spenderAllowance != type(uint256).max) {
            uint256 newAllowance = spenderAllowance - amount;
            allowance[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint256 amount) internal {
        _updateFor(src); // update fee position for src
        _updateFor(dst); // update fee position for dst

        balanceOf[src] -= amount;
        balanceOf[dst] += amount;

        emit Transfer(src, dst, amount);
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        if (value != 0) {
            require(token.code.length > 0);
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Pair Fees contract is used as a 1:1 pair relationship to split out fees, this ensures that the curve does not need to be modified for LP shares
contract PairFees {
    address internal immutable pair; // The pair it is bonded to
    address internal immutable token0; // token0 of pair, saved localy and statically for gas optimization
    address internal immutable token1; // Token1 of pair, saved localy and statically for gas optimization

    uint256 private _reserve0;
    uint256 private _reserve1;

    constructor(address _token0, address _token1) {
        pair = msg.sender;
        token0 = _token0;
        token1 = _token1;
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        if (value != 0) {
            require(token.code.length > 0);
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))));
        }
    }

    // Allow the pair to transfer fees to users
    function claimFeesFor(address recipient, uint256 amount0, uint256 amount1) external {
        require(msg.sender == pair);
        if (amount0 > 0) {
            _reserve0 = _reserve0 - amount0;
            _safeTransfer(token0, recipient, amount0);
        }
        if (amount1 > 0) {
            _reserve1 = _reserve1 - amount1;
            _safeTransfer(token1, recipient, amount1);
        }
    }

    function skim() external returns (uint256 amount0, uint256 amount1) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        _safeTransfer(token0, msg.sender, amount0 = balance0 - _reserve0);
        _safeTransfer(token1, msg.sender, amount1 = balance1 - _reserve1);
        _reserve0 = balance0;
        _reserve1 = balance1;
    }

    function notifyFeeAmounts(uint256 amount0, uint256 amount1) external {
        require(msg.sender == pair);
        if (amount0 > 0) _reserve0 = _reserve0 + amount0;
        if (amount1 > 0) _reserve1 = _reserve1 + amount1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";

contract Pearl is ERC20BurnableUpgradeable {
    address public minter;
    address public migrator;

    function initialize() public initializer {
        __ERC20_init("Pearl", "PEARL");
        minter = msg.sender;
    }

    function reinitialize(address _owner) public reinitializer(7) {
        minter = _owner;
        migrator = _owner;
    }

    function setMinter(address _minter) external {
        require(msg.sender == minter);
        minter = _minter;
    }

    function setMigrator(address _migrator) external {
        require(msg.sender == _migrator);
        migrator = _migrator;
    }

    function mint(address account, uint256 amount) external returns (bool) {
        require(msg.sender == minter || msg.sender == migrator, "not allowed");
        _mint(account, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = _msgSender();
        if (spender != migrator) {
            _spendAllowance(from, spender, amount);
        }
        _transfer(from, to, amount);
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "./interfaces/IRewardsDistributor.sol";
import "./interfaces/IVotingEscrow.sol";
import "./Epoch.sol";

/// @title Curve Fee Distribution modified for ve(3,3) emissions
/// @author Curve Finance, andrecronje
contract RewardsDistributor is Initializable, IRewardsDistributor {
    event CheckpointToken(uint256 time, uint256 tokens);
    event Claimed(uint256 tokenId, uint256 amount, uint256 claim_epoch, uint256 max_epoch);

    uint256 public start_time;
    uint256 public time_cursor;
    mapping(uint256 => uint256) public time_cursor_of;
    mapping(uint256 => uint256) public user_epoch_of;

    uint256 public last_token_time;
    uint256[1000000000000000] public tokens_per_week;
    uint256 public token_last_balance;
    uint256[1000000000000000] public ve_supply;

    address public owner;
    address public voting_escrow;
    address public token;
    address public depositor;

    function initialize(address _voting_escrow) public initializer {
        uint256 _t = (block.timestamp / EPOCH_DURATION) * EPOCH_DURATION;
        start_time = _t;
        last_token_time = _t;
        time_cursor = _t;
        address _token = IVotingEscrow(_voting_escrow).token();
        token = _token;
        voting_escrow = _voting_escrow;
        owner = msg.sender;
        require(IERC20Upgradeable(_token).approve(_voting_escrow, type(uint256).max));
    }

    function timestamp() external view returns (uint256) {
        return (block.timestamp / EPOCH_DURATION) * EPOCH_DURATION;
    }

    function _checkpoint_token() internal {
        uint256 token_balance = IERC20Upgradeable(token).balanceOf(address(this));
        uint256 to_distribute = token_balance - token_last_balance;
        token_last_balance = token_balance;

        uint256 t = last_token_time;
        uint256 since_last = block.timestamp - t;
        last_token_time = block.timestamp;
        uint256 this_week = (t / EPOCH_DURATION) * EPOCH_DURATION;
        uint256 next_week = 0;

        for (uint256 i = 0; i < 20; i++) {
            next_week = this_week + EPOCH_DURATION;
            if (block.timestamp < next_week) {
                if (since_last == 0 && block.timestamp == t) {
                    tokens_per_week[this_week] += to_distribute;
                } else {
                    tokens_per_week[this_week] += (to_distribute * (block.timestamp - t)) / since_last;
                }
                break;
            } else {
                if (since_last == 0 && next_week == t) {
                    tokens_per_week[this_week] += to_distribute;
                } else {
                    tokens_per_week[this_week] += (to_distribute * (next_week - t)) / since_last;
                }
            }
            t = next_week;
            this_week = next_week;
        }
        emit CheckpointToken(block.timestamp, to_distribute);
    }

    function checkpoint_token() external {
        assert(msg.sender == depositor);
        _checkpoint_token();
    }

    function _find_timestamp_epoch(address ve, uint256 _timestamp) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = IVotingEscrow(ve).epoch();
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 2) / 2;
            IVotingEscrow.Point memory pt = IVotingEscrow(ve).point_history(_mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function _find_timestamp_user_epoch(
        address ve,
        uint256 tokenId,
        uint256 _timestamp,
        uint256 max_user_epoch
    ) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = max_user_epoch;
        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) break;
            uint256 _mid = (_min + _max + 2) / 2;
            IVotingEscrow.Point memory pt = IVotingEscrow(ve).user_point_history(tokenId, _mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function ve_for_at(uint256 _tokenId, uint256 _timestamp) external view returns (uint256) {
        address ve = voting_escrow;
        uint256 max_user_epoch = IVotingEscrow(ve).user_point_epoch(_tokenId);
        uint256 epoch = _find_timestamp_user_epoch(ve, _tokenId, _timestamp, max_user_epoch);
        IVotingEscrow.Point memory pt = IVotingEscrow(ve).user_point_history(_tokenId, epoch);

        int256 bias = int256(pt.bias - pt.slope * (int128(int256(_timestamp - pt.ts))));
        if (bias < 0) bias = 0;
        return uint256(bias);
    }

    function _checkpoint_total_supply() internal {
        address ve = voting_escrow;
        uint256 t = time_cursor;
        uint256 rounded_timestamp = (block.timestamp / EPOCH_DURATION) * EPOCH_DURATION;
        IVotingEscrow(ve).checkpoint();

        for (uint256 i = 0; i < 20; i++) {
            if (t > rounded_timestamp) {
                break;
            } else {
                uint256 epoch = _find_timestamp_epoch(ve, t);
                IVotingEscrow.Point memory pt = IVotingEscrow(ve).point_history(epoch);
                int128 dt = 0;
                if (t > pt.ts) {
                    dt = int128(int256(t - pt.ts));
                }
                ve_supply[t] = MathUpgradeable.max(uint256(int256(pt.bias - pt.slope * dt)), 0);
            }
            t += EPOCH_DURATION;
        }
        time_cursor = t;
    }

    function checkpoint_total_supply() external {
        _checkpoint_total_supply();
    }

    function _claim(uint256 _tokenId, address ve, uint256 _last_token_time) internal returns (uint256) {
        uint256 user_epoch = 0;
        uint256 to_distribute = 0;

        uint256 max_user_epoch = IVotingEscrow(ve).user_point_epoch(_tokenId);
        uint256 _start_time = start_time;

        if (max_user_epoch == 0) return 0;

        uint256 week_cursor = time_cursor_of[_tokenId];
        if (week_cursor == 0) {
            user_epoch = _find_timestamp_user_epoch(ve, _tokenId, _start_time, max_user_epoch);
        } else {
            user_epoch = user_epoch_of[_tokenId];
        }

        if (user_epoch == 0) user_epoch = 1;

        IVotingEscrow.Point memory user_point = IVotingEscrow(ve).user_point_history(_tokenId, user_epoch);

        if (week_cursor == 0) week_cursor = ((user_point.ts + EPOCH_DURATION - 1) / EPOCH_DURATION) * EPOCH_DURATION;
        if (week_cursor >= last_token_time) return 0;
        if (week_cursor < _start_time) week_cursor = _start_time;

        IVotingEscrow.Point memory old_user_point;

        for (uint256 i = 0; i < 50; i++) {
            if (week_cursor >= _last_token_time) break;

            if (week_cursor >= user_point.ts && user_epoch <= max_user_epoch) {
                user_epoch += 1;
                old_user_point = user_point;
                if (user_epoch > max_user_epoch) {
                    user_point = IVotingEscrow.Point(0, 0, 0, 0);
                } else {
                    user_point = IVotingEscrow(ve).user_point_history(_tokenId, user_epoch);
                }
            } else {
                int128 dt = int128(int256(week_cursor - old_user_point.ts));
                uint256 balance_of = MathUpgradeable.max(uint256(int256(old_user_point.bias - dt * old_user_point.slope)), 0);
                if (balance_of == 0 && user_epoch > max_user_epoch) break;
                if (balance_of != 0) {
                    to_distribute += (balance_of * tokens_per_week[week_cursor]) / ve_supply[week_cursor];
                }
                week_cursor += EPOCH_DURATION;
            }
        }

        user_epoch = MathUpgradeable.min(max_user_epoch, user_epoch - 1);
        user_epoch_of[_tokenId] = user_epoch;
        time_cursor_of[_tokenId] = week_cursor;

        emit Claimed(_tokenId, to_distribute, user_epoch, max_user_epoch);

        return to_distribute;
    }

    function _claimable(uint256 _tokenId, address ve, uint256 _last_token_time) internal view returns (uint256) {
        uint256 user_epoch = 0;
        uint256 to_distribute = 0;

        uint256 max_user_epoch = IVotingEscrow(ve).user_point_epoch(_tokenId);
        uint256 _start_time = start_time;

        if (max_user_epoch == 0) return 0;

        uint256 week_cursor = time_cursor_of[_tokenId];
        if (week_cursor == 0) {
            user_epoch = _find_timestamp_user_epoch(ve, _tokenId, _start_time, max_user_epoch);
        } else {
            user_epoch = user_epoch_of[_tokenId];
        }

        if (user_epoch == 0) user_epoch = 1;

        IVotingEscrow.Point memory user_point = IVotingEscrow(ve).user_point_history(_tokenId, user_epoch);

        if (week_cursor == 0) week_cursor = ((user_point.ts + EPOCH_DURATION - 1) / EPOCH_DURATION) * EPOCH_DURATION;
        if (week_cursor >= last_token_time) return 0;
        if (week_cursor < _start_time) week_cursor = _start_time;

        IVotingEscrow.Point memory old_user_point;

        for (uint256 i = 0; i < 50; i++) {
            if (week_cursor >= _last_token_time) break;

            if (week_cursor >= user_point.ts && user_epoch <= max_user_epoch) {
                user_epoch += 1;
                old_user_point = user_point;
                if (user_epoch > max_user_epoch) {
                    user_point = IVotingEscrow.Point(0, 0, 0, 0);
                } else {
                    user_point = IVotingEscrow(ve).user_point_history(_tokenId, user_epoch);
                }
            } else {
                int128 dt = int128(int256(week_cursor - old_user_point.ts));
                uint256 balance_of = MathUpgradeable.max(uint256(int256(old_user_point.bias - dt * old_user_point.slope)), 0);
                if (balance_of == 0 && user_epoch > max_user_epoch) break;
                if (balance_of != 0) {
                    to_distribute += (balance_of * tokens_per_week[week_cursor]) / ve_supply[week_cursor];
                }
                week_cursor += EPOCH_DURATION;
            }
        }

        return to_distribute;
    }

    function claimable(uint256 _tokenId) external view returns (uint256) {
        uint256 _last_token_time = (last_token_time / EPOCH_DURATION) * EPOCH_DURATION + EPOCH_DURATION;
        return _claimable(_tokenId, voting_escrow, _last_token_time);
    }

    function claim(uint256 _tokenId) external returns (uint256) {
        if (block.timestamp >= time_cursor) _checkpoint_total_supply();
        uint256 _last_token_time = last_token_time;
        _last_token_time = (_last_token_time / EPOCH_DURATION) * EPOCH_DURATION + EPOCH_DURATION;
        uint256 amount = _claim(_tokenId, voting_escrow, _last_token_time);
        if (amount != 0) {
            // if locked.end then send directly
            IVotingEscrow.LockedBalance memory _locked = IVotingEscrow(voting_escrow).locked(_tokenId);
            if (_locked.end < block.timestamp) {
                address _nftOwner = IVotingEscrow(voting_escrow).ownerOf(_tokenId);
                IERC20Upgradeable(token).transfer(_nftOwner, amount);
            } else {
                IVotingEscrow(voting_escrow).deposit_for(_tokenId, amount);
            }
            token_last_balance -= amount;
        }
        return amount;
    }

    function claim_many(uint256[] memory _tokenIds) external returns (bool) {
        if (block.timestamp >= time_cursor) _checkpoint_total_supply();
        uint256 _last_token_time = last_token_time;
        _last_token_time = (_last_token_time / EPOCH_DURATION) * EPOCH_DURATION + EPOCH_DURATION;
        address _voting_escrow = voting_escrow;
        uint256 total = 0;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            if (_tokenId == 0) break;
            uint256 amount = _claim(_tokenId, _voting_escrow, _last_token_time);
            if (amount != 0) {
                // if locked.end then send directly
                IVotingEscrow.LockedBalance memory _locked = IVotingEscrow(_voting_escrow).locked(_tokenId);
                if (_locked.end < block.timestamp) {
                    address _nftOwner = IVotingEscrow(_voting_escrow).ownerOf(_tokenId);
                    IERC20Upgradeable(token).transfer(_nftOwner, amount);
                } else {
                    IVotingEscrow(_voting_escrow).deposit_for(_tokenId, amount);
                }
                total += amount;
            }
        }
        if (total != 0) {
            token_last_balance -= total;
        }

        return true;
    }

    function setDepositor(address _depositor) external {
        require(msg.sender == owner);
        depositor = _depositor;
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner);
        owner = _owner;
    }

    function withdrawERC20(address _token) external {
        require(msg.sender == owner);
        require(_token != address(0));
        uint256 _balance = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).transfer(msg.sender, _balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/IPair.sol";
import "./interfaces/IPairFactory.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IWETH.sol";

contract Router is IRouter {
    struct route {
        address from;
        address to;
        bool stable;
    }

    address public immutable factory;
    address public immutable pairLibrary;
    IWETH public immutable weth;
    uint256 internal constant MINIMUM_LIQUIDITY = 10 ** 3;

    // create swap event with sender and amountIn for the referral event reader system
    event Swap(address indexed sender, uint256 amount0In, address _tokenIn, address indexed to);

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Router: EXPIRED");
        _;
    }

    constructor(address _factory, address _pairLibrary, address _weth) {
        factory = _factory;
        pairLibrary = _pairLibrary;
        weth = IWETH(_weth);
    }

    receive() external payable {
        assert(msg.sender == address(weth)); // only accept ETH via fallback from the WETH contract
    }

    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        require(tokenA != tokenB, "Router: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Router: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB, bool stable) public view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, stable));
        pair = Clones.predictDeterministicAddress(pairLibrary, salt, factory);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quoteLiquidity(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "Router: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "Router: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB, bool stable) public view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IPair(pairFor(tokenA, tokenB, stable)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountOut(uint256 amountIn, address tokenIn, address tokenOut) external view returns (uint256 amount, bool stable) {
        address pair = pairFor(tokenIn, tokenOut, true);
        uint256 amountStable;
        uint256 amountVolatile;
        if (IPairFactory(factory).isPair(pair)) {
            amountStable = IPair(pair).getAmountOut(amountIn, tokenIn);
        }
        pair = pairFor(tokenIn, tokenOut, false);
        if (IPairFactory(factory).isPair(pair)) {
            amountVolatile = IPair(pair).getAmountOut(amountIn, tokenIn);
        }
        return amountStable > amountVolatile ? (amountStable, true) : (amountVolatile, false);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint256 amountIn, route[] memory routes) public view returns (uint256[] memory amounts) {
        require(routes.length >= 1, "Router: INVALID_PATH");
        amounts = new uint256[](routes.length + 1);
        amounts[0] = amountIn;
        for (uint256 i = 0; i < routes.length; i++) {
            address pair = pairFor(routes[i].from, routes[i].to, routes[i].stable);
            if (IPairFactory(factory).isPair(pair)) {
                amounts[i + 1] = IPair(pair).getAmountOut(amounts[i], routes[i].from);
            }
        }
    }

    function isPair(address pair) external view returns (bool) {
        return IPairFactory(factory).isPair(pair);
    }

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired
    ) external view returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        // create the pair if it doesn't exist yet
        address _pair = IPairFactory(factory).getPair(tokenA, tokenB, stable);
        (uint256 reserveA, uint256 reserveB) = (0, 0);
        uint256 _totalSupply = 0;
        if (_pair != address(0)) {
            _totalSupply = IERC20(_pair).totalSupply();
            (reserveA, reserveB) = getReserves(tokenA, tokenB, stable);
        }
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            liquidity = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
        } else {
            uint256 amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
                liquidity = Math.min((amountA * _totalSupply) / reserveA, (amountB * _totalSupply) / reserveB);
            } else {
                uint256 amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
                liquidity = Math.min((amountA * _totalSupply) / reserveA, (amountB * _totalSupply) / reserveB);
            }
        }
    }

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity
    ) external view returns (uint256 amountA, uint256 amountB) {
        // create the pair if it doesn't exist yet
        address _pair = IPairFactory(factory).getPair(tokenA, tokenB, stable);

        if (_pair == address(0)) {
            return (0, 0);
        }

        (uint256 reserveA, uint256 reserveB) = getReserves(tokenA, tokenB, stable);
        uint256 _totalSupply = IERC20(_pair).totalSupply();

        amountA = (liquidity * reserveA) / _totalSupply; // using balances ensures pro-rata distribution
        amountB = (liquidity * reserveB) / _totalSupply; // using balances ensures pro-rata distribution
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        require(amountADesired >= amountAMin);
        require(amountBDesired >= amountBMin);
        // create the pair if it doesn't exist yet
        address _pair = IPairFactory(factory).getPair(tokenA, tokenB, stable);
        if (_pair == address(0)) {
            _pair = IPairFactory(factory).createPair(tokenA, tokenB, stable);
        }
        (uint256 reserveA, uint256 reserveB) = getReserves(tokenA, tokenB, stable);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Router: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "Router: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, stable, amountADesired, amountBDesired, amountAMin, amountBMin);
        address pair = pairFor(tokenA, tokenB, stable);
        _safeTransferFrom(tokenA, msg.sender, pair, amountA);
        _safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IPair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        bool stable,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        (amountToken, amountETH) = _addLiquidity(token, address(weth), stable, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
        address pair = pairFor(token, address(weth), stable);
        _safeTransferFrom(token, msg.sender, pair, amountToken);
        weth.deposit{value: amountETH}();
        assert(weth.transfer(pair, amountETH));
        liquidity = IPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) _safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = pairFor(tokenA, tokenB, stable);
        require(IPair(pair).transferFrom(msg.sender, pair, liquidity)); // send liquidity to pair
        (uint256 amount0, uint256 amount1) = IPair(pair).burn(to);
        (address token0, ) = sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "Router: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "Router: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityETH(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            address(weth),
            stable,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        _safeTransfer(token, to, amountToken);
        weth.withdraw(amountETH);
        _safeTransferETH(to, amountETH);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB) {
        address pair = pairFor(tokenA, tokenB, stable);
        {
            uint256 value = approveMax ? type(uint256).max : liquidity;
            IPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        }

        (amountA, amountB) = removeLiquidity(tokenA, tokenB, stable, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH) {
        address pair = pairFor(token, address(weth), stable);
        uint256 value = approveMax ? type(uint256).max : liquidity;
        IPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, stable, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint256[] memory amounts, route[] memory routes, address _to) internal virtual {
        for (uint256 i = 0; i < routes.length; i++) {
            (address token0, ) = sortTokens(routes[i].from, routes[i].to);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = routes[i].from == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < routes.length - 1 ? pairFor(routes[i + 1].from, routes[i + 1].to, routes[i + 1].stable) : _to;
            IPair(pairFor(routes[i].from, routes[i].to, routes[i].stable)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
        emit Swap(msg.sender, amounts[0], routes[0].from, _to);
    }

    function swapExactTokensForTokensSimple(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        route[] memory routes = new route[](1);
        routes[0].from = tokenFrom;
        routes[0].to = tokenTo;
        routes[0].stable = stable;
        amounts = getAmountsOut(amountIn, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
        _safeTransferFrom(routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]);
        _swap(amounts, routes, to);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        route[] calldata routes,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        amounts = getAmountsOut(amountIn, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
        _safeTransferFrom(routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]);
        _swap(amounts, routes, to);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        route[] calldata routes,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        require(routes[0].from == address(weth), "Router: INVALID_PATH");
        amounts = getAmountsOut(msg.value, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
        weth.deposit{value: amounts[0]}();
        assert(weth.transfer(pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]));
        _swap(amounts, routes, to);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        route[] calldata routes,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        require(routes[routes.length - 1].to == address(weth), "Router: INVALID_PATH");
        amounts = getAmountsOut(amountIn, routes);
        require(amounts[amounts.length - 1] >= amountOutMin, "Router: INSUFFICIENT_OUTPUT_AMOUNT");
        _safeTransferFrom(routes[0].from, msg.sender, pairFor(routes[0].from, routes[0].to, routes[0].stable), amounts[0]);
        _swap(amounts, routes, address(this));
        weth.withdraw(amounts[amounts.length - 1]);
        _safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function _safeTransferETH(address to, uint256 value) internal {
        if (value != 0) {
            (bool success, ) = to.call{value: value}(new bytes(0));
            require(success, "TransferHelper: ETH_TRANSFER_FAILED");
        }
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        if (value != 0) {
            require(token.code.length > 0);
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))));
        }
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        if (value != 0) {
            require(token.code.length > 0);
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title Storage
 * @dev This contract allows for the storage of key-value pairs.
 * Only an address with the DEFAULT_ADMIN_ROLE can set values.
 */
contract Storage is AccessControlUpgradeable {
    mapping(bytes32 => bytes32) private values;

    function initialize() public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "StorageContract: caller is not an admin");
        _;
    }

    /**
     * @dev Returns the raw bytes32 value associated with the given key.
     * @param key The key for the value.
     * @return The bytes32 value.
     */
    function get(bytes32 key) public view returns (bytes32) {
        return values[key];
    }

    /**
     * @dev Returns the address value associated with the given key.
     * @param key The key for the value.
     * @return The address value.
     */
    function getAddress(bytes32 key) public view returns (address) {
        return address(uint160(uint256(values[key])));
    }

    /**
     * @dev Returns the uint256 value associated with the given key.
     * @param key The key for the value.
     * @return The uint256 value.
     */
    function getUint256(bytes32 key) public view returns (uint256) {
        return uint256(values[key]);
    }

    /**
     * @dev Returns the int256 value associated with the given key.
     * @param key The key for the value.
     * @return The int256 value.
     */
    function getInt256(bytes32 key) public view returns (int256) {
        bytes32 value = values[key];
        int256 intValue;
        assembly {
            intValue := value
        }
        return intValue;
    }

    /**
     * @dev Stores a bytes32 value associated with the key.
     * @param key The key for the value.
     * @param value The bytes32 value to be stored.
     */
    function set(bytes32 key, bytes32 value) public onlyAdmin {
        values[key] = value;
    }

    /**
     * @dev Stores an address value associated with the key.
     * @param key The key for the value.
     * @param value The address value to be stored.
     */
    function setAddress(bytes32 key, address value) public onlyAdmin {
        values[key] = bytes32(uint256(uint160(value)));
    }

    /**
     * @dev Stores a uint256 value associated with the key.
     * @param key The key for the value.
     * @param value The uint256 value to be stored.
     */
    function setUint256(bytes32 key, uint256 value) public onlyAdmin {
        values[key] = bytes32(value);
    }

    /**
     * @dev Stores an int256 value associated with the key.
     * @param key The key for the value.
     * @param value The int256 value to be stored.
     */
    function setInt256(bytes32 key, int256 value) public onlyAdmin {
        bytes32 bytes32Value;
        assembly {
            bytes32Value := value
        }
        values[key] = bytes32Value;
    }

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to a new admin.
     * @param newAdmin The address of the new admin.
     */
    function grantAdminRole(address newAdmin) public onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

    /**
     * @dev Revokes `DEFAULT_ADMIN_ROLE` from an address.
     * @param admin The address of the admin to be revoked.
     */
    function revokeAdminRole(address admin) public onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, admin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Base64Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import {DateTime} from "@quant-finance/solidity-datetime/contracts/DateTime.sol";

import {IVeArtProxy} from "./interfaces/IVeArtProxy.sol";

contract VeArtProxy is IVeArtProxy, Initializable {
    using DateTime for uint256;

    function initialize() public initializer {}

    function _tokenURI(
        uint256 _tokenId,
        uint256 _balanceOf,
        uint256 _locked_end,
        uint256 /*_value*/
    ) external pure returns (string memory output) {
        string memory svg = _generateSVG(_tokenId, _balanceOf, _locked_end);
        string memory json = Base64Upgradeable.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "lock #',
                        toString(_tokenId),
                        '", "description": "Pearl locks can be used to boost gauge yields, vote on token emission, and receive bribes", "image": "data:image/svg+xml;base64,',
                        Base64Upgradeable.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _generateSVG(uint256 _tokenId, uint256 _balanceOf, uint256 _locked_end) internal pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    '<?xml version="1.0" encoding="UTF-8"?><svg fill="none" preserveAspectRatio="xMinYMin meet" viewBox="0 0 300 300" xmlns="http://www.w3.org/2000/svg"><style type="text/css">.st0{fill-rule:evenodd;clip-rule:evenodd;fill:#2E5CFF;fill-opacity:0.7;}.st1{opacity:0.7;}.st2{fill:#2E5CFF;}.st3{font-family:"Lexend-Regular","Arial";}.st4{font-size:16px;}.st5{opacity:0.4;}.st6{font-size:8px;}.st7{font-size:12px;}</style><g clip-path="url(#k)"><rect width="300" height="300" fill="#fff"/><g clip-path="url(#j)" clip-rule="evenodd" fill-rule="evenodd" filter="url(#h)" opacity=".4"><path d="m-122.58-59.62c133.8 0 254.44 87.558 339.14 227.61 26.901 44.505 0.705 106.63-32.481 117.08-143.14 45.051-330.27-234.33-512.82-203-33.832 5.813-67.429 22.616-103.26 55.586-8.811 8.084-18.854 16.803-25.609 23.525 84.521-136.15 203.34-220.89 335.03-220.89v0.0908z" fill="url(#f)" opacity=".48"/><path d="m422.46-59.711c-133.86 0-254.55 87.582-339.28 227.68-26.971 44.608-0.6463 106.66 32.494 117.11 111.76 35.16 250.38-127.47 392.75-185.52 81.618-33.343 181.74-25.984 248.91 61.78-84.555-136.19-203.13-221.04-334.87-221.04z" fill="url(#e)" opacity=".48"/></g><g filter="url(#g)" shape-rendering="crispEdges"><circle cx="150.5" cy="114.5" r="79.5" fill="#fff" fill-opacity=".02"/><circle cx="150.5" cy="114.5" r="79.949" stroke="url(#d)" stroke-width=".8983"/></g><g clip-path="url(#i)"><path d="m149.68 158.3c25.038 0 45.335-20.203 45.335-45.124 0-24.922-20.297-45.125-45.335-45.125-25.037 0-45.334 20.203-45.334 45.125 0 24.921 20.297 45.124 45.334 45.124z" fill="url(#c)"/><path d="m149.71 158.3c-24.721 0-46.999-10.413-62.654-27.069-4.9743-5.293-0.1352-12.675 6.0052-13.92 26.438-5.358 61.01 27.865 94.736 24.139 6.247-0.69 12.458-2.691 19.074-6.614 1.628-0.964 3.479-1.996 4.729-2.8-15.61 16.188-37.568 26.264-61.891 26.264z" clip-rule="evenodd" fill="url(#b)" fill-rule="evenodd" opacity=".48"/><path d="m149.64 158.3c24.722 0 46.999-10.413 62.654-27.069 4.98-5.299 0.121-12.678-6.005-13.92-20.64-4.183-46.238 15.151-72.521 22.056-15.075 3.961-33.566 3.084-45.962-7.348 15.612 16.188 37.512 26.281 61.834 26.281z" clip-rule="evenodd" fill="url(#a)" fill-rule="evenodd" opacity=".48"/></g></g><defs><filter id="h" x="-74.247" y="-74.247" width="448.5" height="448.5" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur result="effect1_foregroundBlur_574_1183" stdDeviation="37.1237"/></filter><filter id="g" x="-1.7628" y="-1.8305" width="304.53" height="304.52" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feGaussianBlur in="BackgroundImageFix" stdDeviation="17.9661"/><feComposite in2="SourceAlpha" operator="in" result="effect1_backgroundBlur_574_1183"/><feColorMatrix in="SourceAlpha" result="hardAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0"/><feOffset dy="35.9322"/><feGaussianBlur stdDeviation="35.9322"/><feComposite in2="hardAlpha" operator="out"/><feColorMatrix values="0 0 0 0 0.179167 0 0 0 0 0.35975 0 0 0 0 1 0 0 0 0.1 0"/><feBlend in2="effect1_backgroundBlur_574_1183" result="effect2_dropShadow_574_1183"/><feBlend in="SourceGraphic" in2="effect2_dropShadow_574_1183" result="shape"/></filter><linearGradient id="f" x1="227.73" x2="-457.6" y1="115.22" y2="115.22" gradientUnits="userSpaceOnUse"><stop stop-color="#03B0DC" offset="0"/><stop stop-color="#0BA5DE" offset=".12"/><stop stop-color="#2188E3" offset=".32"/><stop stop-color="#465AED" offset=".58"/><stop stop-color="#781BFA" offset=".89"/><stop stop-color="#8C03FF" offset="1"/></linearGradient><linearGradient id="e" x1="757.33" x2="72.011" y1="115.18" y2="115.18" gradientUnits="userSpaceOnUse"><stop stop-color="#03B0DC" offset="0"/><stop stop-color="#0BA5DE" offset=".12"/><stop stop-color="#2188E3" offset=".32"/><stop stop-color="#465AED" offset=".58"/><stop stop-color="#781BFA" offset=".89"/><stop stop-color="#8C03FF" offset="1"/></linearGradient><linearGradient id="d" x1="150.5" x2="150.5" y1="35" y2="194" gradientUnits="userSpaceOnUse"><stop stop-color="#fff" offset="0"/><stop stop-color="#fff" stop-opacity="0" offset="1"/></linearGradient><radialGradient id="c" cx="0" cy="0" r="1" gradientTransform="translate(135.94 87.652) rotate(37.751) scale(72.271 51.31)" gradientUnits="userSpaceOnUse"><stop stop-color="#2E5CFF" offset="0"/><stop stop-color="#162435" offset="1"/></radialGradient><linearGradient id="b" x1="85" x2="211.6" y1="137.51" y2="137.51" gradientUnits="userSpaceOnUse"><stop stop-color="#03B0DC" offset="0"/><stop stop-color="#0BA5DE" offset=".12"/><stop stop-color="#2188E3" offset=".32"/><stop stop-color="#465AED" offset=".58"/><stop stop-color="#781BFA" offset=".89"/><stop stop-color="#8C03FF" offset="1"/></linearGradient><linearGradient id="a" x1="87.809" x2="214.36" y1="137.51" y2="137.51" gradientUnits="userSpaceOnUse"><stop stop-color="#03B0DC" offset="0"/><stop stop-color="#0BA5DE" offset=".12"/><stop stop-color="#2188E3" offset=".32"/><stop stop-color="#465AED" offset=".58"/><stop stop-color="#781BFA" offset=".89"/><stop stop-color="#8C03FF" offset="1"/></linearGradient><clipPath id="k"><rect width="300" height="300" fill="#fff"/></clipPath><clipPath id="j"><rect width="300" height="300" fill="#fff"/></clipPath><clipPath id="i"><rect transform="translate(85 49)" width="129.36" height="129.36" fill="#fff"/></clipPath></defs><path class="st0" d="m25.5 229.9c-0.9 0-1.7 0.3-2.3 1-0.6 0.6-1 1.4-1 2.3v1.9c-0.5 0-1 0.2-1.3 0.5-0.4 0.4-0.5 0.8-0.5 1.3v4.2c0 0.5 0.2 1 0.5 1.3 0.4 0.4 0.8 0.5 1.3 0.5h6.6c0.5 0 1-0.2 1.3-0.5 0.4-0.4 0.5-0.8 0.5-1.3v-4.1c0-0.5-0.2-1-0.5-1.3-0.4-0.4-0.8-0.5-1.3-0.5v-1.9c0-1.9-1.5-3.4-3.3-3.4zm2.3 5.2v-1.9c0-0.6-0.2-1.2-0.7-1.7-0.4-0.4-1-0.7-1.7-0.7s-1.2 0.2-1.7 0.7c-0.4 0.4-0.7 1-0.7 1.7v1.9h4.8z"/><g class="st1"><text class="st2 st3 st4" transform="translate(37.471 242.91)">',
                    formatUintToString(_balanceOf, 18),
                    '</text></g><g class="st5"><text class="st2 st3 st6" transform="translate(20 263)">Lock ends</text></g><g class="st5"><text class="st2 st3 st6" transform="translate(280 263)" text-anchor="end">Token ID</text></g><g class="st1"><text class="st2 st3 st7" transform="translate(20 280)">',
                    toDateString(_locked_end),
                    '</text></g><g class="st1"><text class="st2 st3 st7" transform="translate(280 280)" text-anchor="end">',
                    toString(_tokenId),
                    "</text></g></svg>"
                )
            );
    }

    /// @notice Converts a timestamp into a formatted date string representation
    /// @param timestamp The timestamp to be converted to a formatted date string
    /// @return string representation of the given timestamp
    function toDateString(uint256 timestamp) private pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day) = timestamp.timestampToDate();
        string[12] memory monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        return string(abi.encodePacked(toString(day), " ", monthNames[month], ", ", toString(year)));
    }

    /// @notice Converts a uint256 value into a string representation
    /// @dev Optimizes for values with 32 digits or less using a bytes32 buffer, otherwise uses a dynamic bytes array
    /// @param value The uint256 value to be converted to a string
    /// @return string representation of the given uint256 value
    function toString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        // If the number of digits is more than 32, use a dynamic bytes array.
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            unchecked {
                digits -= 1;
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            }
        }
        return string(buffer);
    }

    /// @notice Formats a uint256 value into a string with decimals
    /// @dev The number of decimals specifies the position of the decimal point
    /// @param value The uint256 value to be formatted as a string
    /// @param decimals The number of decimal places
    /// @return A string representing the uint256 value with the given number of decimals
    function formatUintToString(uint256 value, uint256 decimals) public pure returns (string memory) {
        uint256 mainValue = value / (10 ** decimals);
        string memory mainStr = toString(mainValue);
        uint256 decimalValue = value % (10 ** decimals);
        // return early if decimal value is 0
        if (decimalValue == 0) {
            return mainStr;
        }
        string memory decimalStr = toString(decimalValue);
        decimalStr = padWithZeros(decimalStr, decimals);
        decimalStr = removeTrailingZeros(decimalStr);
        return string(abi.encodePacked(mainStr, ".", decimalStr));
    }

    /// @notice Pads a string with leading zeros until it reaches a specific length
    /// @param str The original string
    /// @param decimals The desired length of the string
    /// @return The string padded with leading zeros
    function padWithZeros(string memory str, uint256 decimals) private pure returns (string memory) {
        uint256 strLength = bytes(str).length;
        while (strLength < decimals) {
            str = string(abi.encodePacked("0", str));
            unchecked {
                ++strLength;
            }
        }
        return str;
    }

    /// @notice Removes trailing zeros from a string
    /// @param str The original string
    /// @return The string without trailing zeros
    function removeTrailingZeros(string memory str) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        uint256 strLength = strBytes.length;
        while (strLength > 0 && strBytes[strLength - 1] == "0") {
            unchecked {
                --strLength;
            }
        }
        return substring(strBytes, 0, strLength);
    }

    /// @notice Extracts a substring from a string
    /// @param strBytes The bytes representation of the original string
    /// @param startIndex The starting index of the substring
    /// @param endIndex The ending index of the substring
    /// @return The extracted substring
    function substring(bytes memory strBytes, uint256 startIndex, uint256 endIndex) private pure returns (string memory) {
        bytes memory result = new bytes(endIndex - startIndex);
        uint256 j = 0;
        for (uint256 i = startIndex; i < endIndex; ) {
            bytes(result)[j] = strBytes[i];
            unchecked {
                ++i;
                ++j;
            }
        }
        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "./interfaces/IBribe.sol";
import "./interfaces/IBribeFactory.sol";
import "./interfaces/IGauge.sol";
import "./interfaces/IGaugeFactory.sol";
import "./interfaces/IMinter.sol";
import "./interfaces/IPair.sol";
import "./interfaces/IPairFactory.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IVotingEscrow.sol";

contract Voter is IVoter, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public _ve; // the ve token that governs these contracts
    address public factory; // the PairFactory
    address internal base;
    address public gaugefactory;
    address public bribefactory;
    address public minter;
    address public governor; // should be set to an IGovernor
    address public emergencyCouncil; // credibly neutral party similar to Curve's Emergency DAO

    uint256 internal index;
    mapping(address => uint256) internal supplyIndex;
    mapping(address => uint256) public claimable;

    uint256 public totalWeight; // total voting weight

    address[] public pools; // all pools viable for incentives
    mapping(address => address) public gauges; // pool => gauge
    mapping(address => uint256) public gaugesDistributionTimestamp;
    mapping(address => address) public poolForGauge; // gauge => pool
    mapping(address => address) public internal_bribes; // gauge => internal bribe (only fees)
    mapping(address => address) public external_bribes; // gauge => external bribe (real bribes)
    mapping(address => uint256) public weights; // pool => weight
    mapping(uint256 => mapping(address => uint256)) public votes; // nft => pool => votes
    mapping(uint256 => address[]) public poolVote; // nft => pools
    mapping(uint256 => uint256) public usedWeights; // nft => total voting weight of user
    mapping(uint256 => uint256) public lastVoted; // nft => timestamp of last vote, to ensure one vote per epoch
    mapping(address => bool) public isGauge;
    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isAlive;

    address public usdr;

    mapping(address => bool) public isBribe;

    event GaugeCreated(
        address indexed gauge,
        address creator,
        address internal_bribe,
        address indexed external_bribe,
        address indexed pool
    );
    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);
    event Voted(address indexed voter, uint256 tokenId, uint256 weight);
    event Abstained(uint256 tokenId, uint256 weight);
    event Deposit(address indexed lp, address indexed gauge, uint256 tokenId, uint256 amount);
    event Withdraw(address indexed lp, address indexed gauge, uint256 tokenId, uint256 amount);
    event NotifyReward(address indexed sender, address indexed reward, uint256 amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint256 amount);
    event Whitelisted(address indexed whitelister, address indexed token);

    constructor() {}

    function initialize(address __ve, address _factory, address _gauges, address _bribes) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _ve = __ve;
        factory = _factory;
        base = IVotingEscrow(__ve).token();
        gaugefactory = _gauges;
        bribefactory = _bribes;
        governor = msg.sender;
        emergencyCouncil = msg.sender;
    }

    function _initialize(address[] memory _tokens, address _minter) external {
        require(msg.sender == minter || msg.sender == emergencyCouncil);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _whitelist(_tokens[i]);
        }
        minter = _minter;
    }

    function setMinter(address _minter) external {
        require(msg.sender == emergencyCouncil);
        minter = _minter;
    }

    function setGovernor(address _governor) public {
        require(msg.sender == governor);
        governor = _governor;
    }

    function setEmergencyCouncil(address _council) public {
        require(msg.sender == emergencyCouncil);
        emergencyCouncil = _council;
    }

    function setUSDR(address _usdr) external {
        require(msg.sender == governor);
        usdr = _usdr;
    }

    function getIncentivizedPools() external view returns (address[] memory) {
        return pools;
    }

    function reset(uint256 _tokenId) external nonReentrant {
        require(msg.sender == _ve || IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        lastVoted[_tokenId] = block.timestamp;
        _reset(_tokenId);
        IVotingEscrow(_ve).abstain(_tokenId);
    }

    function _reset(uint256 _tokenId) internal {
        address[] storage _poolVote = poolVote[_tokenId];
        uint256 _poolVoteCnt = _poolVote.length;
        uint256 _totalWeight = 0;

        for (uint256 i = 0; i < _poolVoteCnt; i++) {
            address _pool = _poolVote[i];
            uint256 _votes = votes[_tokenId][_pool];

            if (_votes != 0) {
                weights[_pool] -= _votes;
                votes[_tokenId][_pool] -= _votes;
                if (_votes > 0) {
                    IBribe(internal_bribes[gauges[_pool]])._withdraw(uint256(_votes), _tokenId);
                    IBribe(external_bribes[gauges[_pool]])._withdraw(uint256(_votes), _tokenId);
                    _totalWeight += _votes;
                } else {
                    _totalWeight -= _votes;
                }
                emit Abstained(_tokenId, _votes);
            }
        }
        totalWeight -= _totalWeight;
        usedWeights[_tokenId] = 0;
        delete poolVote[_tokenId];
    }

    function poke(uint256 _tokenId) external nonReentrant {
        require(msg.sender == _ve || IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        address[] memory _poolVote = poolVote[_tokenId];
        uint256 _poolCnt = _poolVote.length;
        uint256[] memory _weights = new uint256[](_poolCnt);
        for (uint256 i = _poolCnt; i != 0; ) {
            unchecked {
                --i;
            }
            _weights[i] = votes[_tokenId][_poolVote[i]];
        }
        _vote(_tokenId, _poolVote, _weights);
    }

    function _vote(uint256 _tokenId, address[] memory _poolVote, uint256[] memory _weights) internal {
        _reset(_tokenId);
        uint256 _poolCnt = _poolVote.length;
        uint256 _weight = IVotingEscrow(_ve).balanceOfNFT(_tokenId);
        uint256 _totalVoteWeight = 0;
        uint256 _usedWeight = 0;

        for (uint256 i = _poolCnt; i != 0; ) {
            unchecked {
                --i;
            }
            _totalVoteWeight += _weights[i];
        }

        for (uint256 i = _poolCnt; i != 0; ) {
            unchecked {
                --i;
            }
            address _pool = _poolVote[i];
            address _gauge = gauges[_pool];

            if (isGauge[_gauge]) {
                uint256 _poolWeight = (_weights[i] * _weight) / _totalVoteWeight;
                require(votes[_tokenId][_pool] == 0);
                require(_poolWeight != 0);

                poolVote[_tokenId].push(_pool);

                weights[_pool] += _poolWeight;
                votes[_tokenId][_pool] += _poolWeight;
                IBribe(internal_bribes[_gauge])._deposit(uint256(_poolWeight), _tokenId);
                IBribe(external_bribes[_gauge])._deposit(uint256(_poolWeight), _tokenId);
                _usedWeight += _poolWeight;
                emit Voted(msg.sender, _tokenId, _poolWeight);
            }
        }
        if (_usedWeight != 0) IVotingEscrow(_ve).voting(_tokenId);
        totalWeight += _usedWeight;
        usedWeights[_tokenId] = _usedWeight;
    }

    function vote(uint256 _tokenId, address[] memory _poolVote, uint256[] memory _weights) external nonReentrant {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        require(_poolVote.length == _weights.length);
        lastVoted[_tokenId] = block.timestamp;
        _vote(_tokenId, _poolVote, _weights);
    }

    function whitelist(address _token) public {
        require(msg.sender == governor, "!governor");
        _whitelist(_token);
    }

    function _whitelist(address _token) internal {
        require(!isWhitelisted[_token], "already whitelisted");
        isWhitelisted[_token] = true;
        emit Whitelisted(msg.sender, _token);
    }

    function createGauge(address _pool) external returns (address) {
        require(gauges[_pool] == address(0x0), "exists");
        address[] memory allowedRewards = new address[](3);
        address[] memory internalRewards = new address[](2);
        bool isPair = IPairFactory(factory).isPair(_pool);
        address tokenA;
        address tokenB;

        if (isPair) {
            (tokenA, tokenB) = IPair(_pool).tokens();
            allowedRewards[0] = tokenA;
            allowedRewards[1] = tokenB;
            internalRewards[0] = tokenA;
            internalRewards[1] = tokenB;

            if (base != tokenA && base != tokenB) {
                allowedRewards[2] = base;
            }
        }

        if (msg.sender != governor) {
            // gov can create for any pool, even non-Pearl pairs
            require(isPair, "!_pool");
            require(isWhitelisted[tokenA] && isWhitelisted[tokenB], "!whitelisted");
            require(usdr == address(0) || tokenA == usdr || tokenB == usdr, "!usdr");
        }

        string memory _type = string.concat("Pearl LP Fees: ", IERC20MetadataUpgradeable(_pool).symbol());
        address _internal_bribe = IBribeFactory(bribefactory).createBribe(owner(), tokenA, tokenB, _type);
        isBribe[_internal_bribe] = true;

        _type = string.concat("Pearl Bribes: ", IERC20MetadataUpgradeable(_pool).symbol());
        address _external_bribe = IBribeFactory(bribefactory).createBribe(owner(), tokenA, tokenB, _type);
        isBribe[_external_bribe] = true;

        address _gauge = IGaugeFactory(gaugefactory).createGauge(base, _ve, _pool, address(this), _internal_bribe, _external_bribe, isPair);

        IERC20Upgradeable(base).approve(_gauge, type(uint256).max);
        internal_bribes[_gauge] = _internal_bribe;
        external_bribes[_gauge] = _external_bribe;
        gauges[_pool] = _gauge;
        poolForGauge[_gauge] = _pool;
        isGauge[_gauge] = true;
        isAlive[_gauge] = true;
        supplyIndex[_gauge] = index;
        pools.push(_pool);
        emit GaugeCreated(_gauge, msg.sender, _internal_bribe, _external_bribe, _pool);
        return _gauge;
    }

    function killGauge(address _gauge) external {
        require(msg.sender == emergencyCouncil, "not emergency council");
        require(isAlive[_gauge], "gauge already dead");
        isAlive[_gauge] = false;
        claimable[_gauge] = 0;
        emit GaugeKilled(_gauge);
    }

    function reviveGauge(address _gauge) external {
        require(msg.sender == emergencyCouncil, "not emergency council");
        require(!isAlive[_gauge], "gauge already alive");
        isAlive[_gauge] = true;
        emit GaugeRevived(_gauge);
    }

    function emitDeposit(uint256 tokenId, address account, uint256 amount) external {
        require(isGauge[msg.sender]);
        require(isAlive[msg.sender]);
        emit Deposit(account, msg.sender, tokenId, amount);
    }

    function emitWithdraw(uint256 tokenId, address account, uint256 amount) external {
        require(isGauge[msg.sender]);
        emit Withdraw(account, msg.sender, tokenId, amount);
    }

    function length() external view returns (uint256) {
        return pools.length;
    }

    function poolVoteLength(uint256 tokenId) external view returns (uint256) {
        return poolVote[tokenId].length;
    }

    function notifyRewardAmount(uint256 amount) external {
        require(totalWeight != 0, "no votes");
        _safeTransferFrom(base, msg.sender, address(this), amount); // transfer the distro in
        uint256 _ratio = (amount * 1e18) / totalWeight; // 1e18 adjustment is removed during claim
        if (_ratio != 0) {
            index += _ratio;
        }
        emit NotifyReward(msg.sender, base, amount);
    }

    function _updateFor(address _gauge) internal {
        address _pool = poolForGauge[_gauge];
        uint256 _supplied = weights[_pool];
        if (_supplied != 0) {
            uint256 _supplyIndex = supplyIndex[_gauge];
            uint256 _index = index; // get global index0 for accumulated distro
            supplyIndex[_gauge] = _index; // update _gauge current position to global position
            uint256 _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (_delta != 0) {
                uint256 _share = (_supplied * _delta) / 1e18; // add accrued difference for each supplied token
                if (isAlive[_gauge]) {
                    claimable[_gauge] += _share;
                }
            }
        } else {
            supplyIndex[_gauge] = index; // new users are set to the default global state
        }
    }

    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint256 _tokenId) external {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        for (uint256 i = _bribes.length; i != 0; ) {
            unchecked {
                --i;
            }
            IBribe(_bribes[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    function claimFees(address[] memory _fees, address[][] memory _tokens, uint256 _tokenId) external {
        require(IVotingEscrow(_ve).isApprovedOrOwner(msg.sender, _tokenId));
        for (uint256 i = _fees.length; i != 0; ) {
            unchecked {
                --i;
            }
            IBribe(_fees[i]).getRewardForOwner(_tokenId, _tokens[i]);
        }
    }

    function distributeFees(address[] memory _gauges) external {
        for (uint256 i = _gauges.length; i != 0; ) {
            unchecked {
                --i;
            }
            if (IGauge(_gauges[i]).isForPair()) {
                IGauge(_gauges[i]).claimFees();
            }
        }
    }

    function distribute(address _gauge) public nonReentrant {
        IMinter(minter).update_period();

        uint256 lastTimestamp = gaugesDistributionTimestamp[_gauge];
        uint256 currentTimestamp = IMinter(minter).active_period();

        if (lastTimestamp < currentTimestamp) {
            _updateFor(_gauge);
            uint256 _claimable = claimable[_gauge];
            // distribute only if claimable is > 0, currentEpoch != lastepoch and gauge is alive
            if (_claimable != 0 && isAlive[_gauge]) {
                claimable[_gauge] = 0;
                gaugesDistributionTimestamp[_gauge] = currentTimestamp;
                IGauge(_gauge).notifyRewardAmount(base, _claimable);
                emit DistributeReward(msg.sender, _gauge, _claimable);
            }
        }
    }

    function distributeAll() external {
        distribute(0, pools.length);
    }

    function distribute(uint256 start, uint256 finish) public {
        for (uint256 x = start; x < finish; ) {
            distribute(gauges[pools[x]]);
            unchecked {
                ++x;
            }
        }
    }

    function distribute(address[] memory _gauges) external {
        for (uint256 x = _gauges.length; x != 0; ) {
            unchecked {
                --x;
            }
            distribute(_gauges[x]);
        }
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        if (value != 0) {
            require(token.code.length != 0);
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSelector(IERC20Upgradeable.transferFrom.selector, from, to, value)
            );
            require(success && (data.length == 0 || abi.decode(data, (bool))));
        }
    }

    function setBribeFactory(address _bribeFactory) external {
        require(msg.sender == emergencyCouncil);
        bribefactory = _bribeFactory;
    }

    function setGaugeFactory(address _gaugeFactory) external {
        require(msg.sender == emergencyCouncil);
        gaugefactory = _gaugeFactory;
    }

    function setPairFactory(address _factory) external {
        require(msg.sender == emergencyCouncil);
        factory = _factory;
    }

    function whitelist(address[] memory _token) public {
        require(msg.sender == governor);
        for (uint256 i = _token.length; i != 0; ) {
            unchecked {
                --i;
            }
            _whitelist(_token[i]);
        }
    }

    function initGauges(address[] memory _gauges, address[] memory _pools) public {
        require(msg.sender == emergencyCouncil);
        for (uint256 i = _pools.length; i != 0; ) {
            unchecked {
                --i;
            }
            address _pool = _pools[i];
            address _gauge = _gauges[i];
            address tokenA;
            address tokenB;
            (tokenA, tokenB) = IPair(_pool).tokens();

            string memory _type = string.concat("Pearl LP Fees: ", IERC20MetadataUpgradeable(_pool).symbol());
            address _internal_bribe = IBribeFactory(bribefactory).createBribe(owner(), tokenA, tokenB, _type);
            _type = string.concat("Pearl Bribes: ", IERC20MetadataUpgradeable(_pool).symbol());
            address _external_bribe = IBribeFactory(bribefactory).createBribe(owner(), tokenA, tokenB, _type);
            IERC20Upgradeable(base).approve(_gauge, type(uint256).max);
            internal_bribes[_gauge] = _internal_bribe;
            external_bribes[_gauge] = _external_bribe;
            gauges[_pool] = _gauge;
            poolForGauge[_gauge] = _pool;
            isGauge[_gauge] = true;
            isAlive[_gauge] = true;
            _updateFor(_gauge);
            pools.push(_pool);

            // update index
            supplyIndex[_gauge] = index; // new gauges are set to the default global state

            emit GaugeCreated(_gauge, msg.sender, _internal_bribe, _external_bribe, _pool);
        }
    }

    function increaseGaugeApprovals(address _gauge) external {
        require(msg.sender == emergencyCouncil);
        require(isGauge[_gauge] = true);
        IERC20Upgradeable(base).approve(_gauge, 0);
        IERC20Upgradeable(base).approve(_gauge, type(uint256).max);
    }

    function setNewBribe(address _gauge, address _internal, address _external) external {
        require(msg.sender == emergencyCouncil);
        require(isGauge[_gauge] = true);
        internal_bribes[_gauge] = _internal;
        external_bribes[_gauge] = _external;
    }

    function setVotingEscrow(address _votingEscrow) external {
        require(msg.sender == governor);
        _ve = _votingEscrow;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {veNFTAPI} from "./APIHelper/veNFTAPI.sol";
import {RewardAPI} from "./APIHelper/RewardAPI.sol";
import {IMinter} from "./interfaces/IMinter.sol";
import {IVeArtProxy} from "./interfaces/IVeArtProxy.sol";
import {IVoter} from "./interfaces/IVoter.sol";
import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";
import {EPOCH_DURATION} from "./Epoch.sol";

/// @title Voting Escrow
/// @notice veNFT implementation that escrows ERC-20 tokens in the form of an ERC-721 NFT
/// @notice Votes have a weight depending on time, so that users are committed to the future of (whatever they are voting for)
/// @author Modified from Solidly (https://github.com/solidlyexchange/solidly/blob/master/contracts/ve.sol)
/// @author Modified from Curve (https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy)
/// @author Modified from Nouns DAO (https://github.com/withtally/my-nft-dao-project/blob/main/contracts/ERC721Checkpointable.sol)
/// @dev Vote weight decays linearly over time. Lock time cannot be more than `MAXTIME` (2 years).
contract VotingEscrow is Initializable, IVotingEscrow, IVotes {
    address public constant PREVIOUS_IMPLEMENTATION = 0xf484c4AB97ee393F8D1aF6948B70bd88a033cBAB;

    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME,
        MERGE_TYPE,
        SPLIT_TYPE
    }

    /* We cannot really do block numbers per se b/c slope is per time, not per block
     * and per block could be fairly bad b/c Ethereum changes blocktimes.
     * What we can do is to extrapolate ***At functions */

    /// @notice A checkpoint for marking delegated tokenIds from a given timestamp
    struct Checkpoint {
        uint256 timestamp;
        uint256[] tokenIds;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed provider, uint256 tokenId, uint256 value, uint256 indexed locktime, DepositType deposit_type, uint256 ts);
    event Withdraw(address indexed provider, uint256 tokenId, uint256 value, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);
    event Migrate(uint256 indexed tokenId, address migrator, address owner);

    /*//////////////////////////////////////////////////////////////
                               INITIALIZER
    //////////////////////////////////////////////////////////////*/

    address public token;
    address public voter;
    address public team;
    address public artProxy;
    address public api;

    mapping(uint256 => Point) private _point_history; // epoch -> unsigned point

    /// @dev Mapping of interface id to bool about whether or not it's supported
    mapping(bytes4 => bool) internal supportedInterfaces;

    /// @dev ERC165 interface ID of ERC165
    bytes4 internal constant ERC165_INTERFACE_ID = 0x01ffc9a7;

    /// @dev ERC165 interface ID of ERC721
    bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;

    /// @dev ERC165 interface ID of ERC721Metadata
    bytes4 internal constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

    /// @dev Current count of token
    uint256 internal tokenId;

    function initialize(address token_addr, address art_proxy) public virtual initializer {
        token = token_addr;
        team = msg.sender;
        artProxy = art_proxy;

        _point_history[0].blk = block.number;
        _point_history[0].ts = block.timestamp;

        supportedInterfaces[ERC165_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = true;

        _entered_state = _not_entered;

        tokenId = 1989;
    }

    /*//////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev reentrancy guard
    uint8 internal constant _not_entered = 1;
    uint8 internal constant _entered = 2;
    uint8 internal _entered_state;
    modifier nonreentrant() {
        require(_entered_state == _not_entered);
        _entered_state = _entered;
        _;
        _entered_state = _not_entered;
    }

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public constant name = "vePearl";
    string public constant symbol = "vePEARL";
    string public constant version = "2.0.0";
    uint8 public constant decimals = 18;

    function setTeam(address _team) external {
        require(msg.sender == team);
        team = _team;
    }

    function setArtProxy(address _proxy) external {
        require(msg.sender == team);
        artProxy = _proxy;
    }

    function setAPI(address _api) external {
        require(msg.sender == team);
        api = _api;
    }

    /// @dev Returns current token URI metadata
    /// @param _tokenId Token ID to fetch URI for.
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(idToOwner[_tokenId] != address(0), "Query for nonexistent token");
        LockedBalance memory locked_balance = _locked[_tokenId];
        return
            IVeArtProxy(artProxy)._tokenURI(
                _tokenId,
                _balanceOfNFT(_tokenId, block.timestamp),
                locked_balance.end,
                uint256(int256(locked_balance.amount))
            );
    }

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from NFT ID to the address that owns it.
    mapping(uint256 => address) internal idToOwner;

    /// @dev Mapping from owner address to count of his tokens.
    mapping(address => uint256) internal ownerToNFTokenCount;

    /// @dev Returns the address of the owner of the NFT.
    /// @param _tokenId The identifier for an NFT.
    function ownerOf(uint256 _tokenId) public view returns (address) {
        return idToOwner[_tokenId];
    }

    /// @dev Returns the number of NFTs owned by `_owner`.
    ///      Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    /// @param _owner Address for whom to query the balance.
    function _balance(address _owner) internal view returns (uint256) {
        return ownerToNFTokenCount[_owner];
    }

    /// @dev Returns the number of NFTs owned by `_owner`.
    ///      Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    /// @param _owner Address for whom to query the balance.
    function balanceOf(address _owner) external view returns (uint256) {
        return _balance(_owner);
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from NFT ID to approved address.
    mapping(uint256 => address) internal idToApprovals;

    /// @dev Mapping from owner address to mapping of operator addresses.
    mapping(address => mapping(address => bool)) internal ownerToOperators;

    mapping(uint256 => uint256) public ownership_change;

    /// @dev Get the approved address for a single NFT.
    /// @param _tokenId ID of the NFT to query the approval of.
    function getApproved(uint256 _tokenId) external view returns (address) {
        return idToApprovals[_tokenId];
    }

    /// @dev Checks if `_operator` is an approved operator for `_owner`.
    /// @param _owner The address that owns the NFTs.
    /// @param _operator The address that acts on behalf of the owner.
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return (ownerToOperators[_owner])[_operator];
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
    ///      Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
    ///      Throws if `_tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
    ///      Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
    /// @param _approved Address to be approved for the given NFT ID.
    /// @param _tokenId ID of the token to be approved.
    function approve(address _approved, uint256 _tokenId) public {
        address owner = idToOwner[_tokenId];
        // Throws if `_tokenId` is not a valid NFT
        require(owner != address(0));
        // Throws if `_approved` is the current owner
        require(_approved != owner);
        // Check requirements
        bool senderIsOwner = (idToOwner[_tokenId] == msg.sender);
        bool senderIsApprovedForAll = (ownerToOperators[owner])[msg.sender];
        require(senderIsOwner || senderIsApprovedForAll);
        // Set the approval
        idToApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    /// @dev Enables or disables approval for a third party ("operator") to manage all of
    ///      `msg.sender`'s assets. It also emits the ApprovalForAll event.
    ///      Throws if `_operator` is the `msg.sender`. (NOTE: This is not written the EIP)
    /// @notice This works even if sender doesn't own any tokens at the time.
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval.
    function setApprovalForAll(address _operator, bool _approved) external {
        // Throws if `_operator` is the `msg.sender`
        assert(_operator != msg.sender);
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    /* TRANSFER FUNCTIONS */
    /// @dev Clear an approval of a given address
    ///      Throws if `_owner` is not the current owner.
    function _clearApproval(address _owner, uint256 _tokenId) internal {
        // Throws if `_owner` is not the current owner
        assert(idToOwner[_tokenId] == _owner);
        if (idToApprovals[_tokenId] != address(0)) {
            // Reset approvals
            idToApprovals[_tokenId] = address(0);
        }
    }

    /// @dev Returns whether the given spender can transfer a given token ID
    /// @param _spender address of the spender to query
    /// @param _tokenId uint ID of the token to be transferred
    /// @return bool whether the msg.sender is approved for the given token ID, is an operator of the owner, or is the owner of the token
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = idToOwner[_tokenId];
        bool spenderIsOwner = owner == _spender;
        bool spenderIsApproved = _spender == idToApprovals[_tokenId];
        bool spenderIsApprovedForAll = (ownerToOperators[owner])[_spender];
        return spenderIsOwner || spenderIsApproved || spenderIsApprovedForAll;
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    /// @dev Exeute transfer of a NFT.
    ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
    ///      address for this NFT. (NOTE: `msg.sender` not allowed in internal function so pass `_sender`.)
    ///      Throws if `_to` is the zero address.
    ///      Throws if `_from` is not the current owner.
    ///      Throws if `_tokenId` is not a valid NFT.
    function _transferFrom(address _from, address _to, uint256 _tokenId, address _sender) internal {
        // Check requirements
        require(_isApprovedOrOwner(_sender, _tokenId));
        // Clear approval. Throws if `_from` is not the current owner
        _clearApproval(_from, _tokenId);
        // Remove NFT. Throws if `_tokenId` is not a valid NFT
        _removeTokenFrom(_from, _tokenId);
        // auto re-delegate
        _moveTokenDelegates(delegates(_from), delegates(_to), _tokenId);
        // Add NFT
        _addTokenTo(_to, _tokenId);
        // Set the block of ownership transfer (for Flash NFT protection)
        ownership_change[_tokenId] = block.number;
        // Log the transfer
        emit Transfer(_from, _to, _tokenId);
    }

    /// @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
    ///      Throws if `_from` is not the current owner.
    ///      Throws if `_to` is the zero address.
    ///      Throws if `_tokenId` is not a valid NFT.
    /// @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
    ///        they maybe be permanently lost.
    /// @param _from The current owner of the NFT.
    /// @param _to The new owner.
    /// @param _tokenId The NFT to transfer.
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        _transferFrom(_from, _to, _tokenId, msg.sender);
    }

    /// @dev Transfers the ownership of an NFT from one address to another address.
    ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the
    ///      approved address for this NFT.
    ///      Throws if `_from` is not the current owner.
    ///      Throws if `_to` is the zero address.
    ///      Throws if `_tokenId` is not a valid NFT.
    ///      If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
    ///      the return value is not `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
    /// @param _from The current owner of the NFT.
    /// @param _to The new owner.
    /// @param _tokenId The NFT to transfer.
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /// @dev Transfers the ownership of an NFT from one address to another address.
    ///      Throws unless `msg.sender` is the current owner, an authorized operator, or the
    ///      approved address for this NFT.
    ///      Throws if `_from` is not the current owner.
    ///      Throws if `_to` is the zero address.
    ///      Throws if `_tokenId` is not a valid NFT.
    ///      If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
    ///      the return value is not `bytes4(keccak256("onERC721Received(address,address,uint,bytes)"))`.
    /// @param _from The current owner of the NFT.
    /// @param _to The new owner.
    /// @param _tokenId The NFT to transfer.
    /// @param _data Additional data with no specified format, sent in call to `_to`.
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
        _transferFrom(_from, _to, _tokenId, msg.sender);

        if (_isContract(_to)) {
            // Throws if transfer destination is a contract which does not implement 'onERC721Received'
            try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 response) {
                if (response != IERC721Receiver(_to).onERC721Received.selector) {
                    revert("ERC721: ERC721Receiver rejected tokens");
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Interface identification is specified in ERC-165.
    /// @param _interfaceID Id of the interface
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from owner address to mapping of index to tokenIds
    mapping(address => mapping(uint256 => uint256)) internal ownerToNFTokenIdList;

    /// @dev Mapping from NFT ID to index of owner
    mapping(uint256 => uint256) internal tokenToOwnerIndex;

    /// @dev  Get token by index
    function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex) external view returns (uint256) {
        return ownerToNFTokenIdList[_owner][_tokenIndex];
    }

    /// @dev Add a NFT to an index mapping to a given address
    /// @param _to address of the receiver
    /// @param _tokenId uint ID Of the token to be added
    function _addTokenToOwnerList(address _to, uint256 _tokenId) internal {
        uint256 current_count = _balance(_to);

        ownerToNFTokenIdList[_to][current_count] = _tokenId;
        tokenToOwnerIndex[_tokenId] = current_count;
    }

    /// @dev Add a NFT to a given address
    ///      Throws if `_tokenId` is owned by someone.
    function _addTokenTo(address _to, uint256 _tokenId) internal {
        // Throws if `_tokenId` is owned by someone
        assert(idToOwner[_tokenId] == address(0));
        // Change the owner
        idToOwner[_tokenId] = _to;
        // Update owner token index tracking
        _addTokenToOwnerList(_to, _tokenId);
        // Change count tracking
        ownerToNFTokenCount[_to] += 1;
    }

    /// @dev Function to mint tokens
    ///      Throws if `_to` is zero address.
    ///      Throws if `_tokenId` is owned by someone.
    /// @param _to The address that will receive the minted tokens.
    /// @param _tokenId The token id to mint.
    /// @return A boolean that indicates if the operation was successful.
    function _mint(address _to, uint256 _tokenId) internal returns (bool) {
        // Throws if `_to` is zero address
        assert(_to != address(0));
        // checkpoint for gov
        _moveTokenDelegates(address(0), delegates(_to), _tokenId);
        // Add NFT. Throws if `_tokenId` is owned by someone
        _addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
        return true;
    }

    /// @dev Remove a NFT from an index mapping to a given address
    /// @param _from address of the sender
    /// @param _tokenId uint ID Of the token to be removed
    function _removeTokenFromOwnerList(address _from, uint256 _tokenId) internal {
        // Delete
        uint256 current_count = _balance(_from) - 1;
        uint256 current_index = tokenToOwnerIndex[_tokenId];

        if (current_count == current_index) {
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][current_count] = 0;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[_tokenId] = 0;
        } else {
            uint256 lastTokenId = ownerToNFTokenIdList[_from][current_count];

            // Add
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][current_index] = lastTokenId;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[lastTokenId] = current_index;

            // Delete
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][current_count] = 0;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[_tokenId] = 0;
        }
    }

    /// @dev Remove a NFT from a given address
    ///      Throws if `_from` is not the current owner.
    function _removeTokenFrom(address _from, uint256 _tokenId) internal {
        // Throws if `_from` is not the current owner
        assert(idToOwner[_tokenId] == _from);
        // Change the owner
        idToOwner[_tokenId] = address(0);
        // Update owner token index tracking
        _removeTokenFromOwnerList(_from, _tokenId);
        // Change count tracking
        ownerToNFTokenCount[_from] -= 1;
    }

    function _burn(uint256 _tokenId) internal {
        require(_isApprovedOrOwner(msg.sender, _tokenId) || IVoter(voter).isBribe(msg.sender), "caller is not owner nor approved");

        address owner = ownerOf(_tokenId);

        // Clear approval
        delete idToApprovals[_tokenId];
        // checkpoint for gov
        _moveTokenDelegates(delegates(owner), address(0), _tokenId);
        // Remove token
        //_removeTokenFrom(msg.sender, _tokenId);
        _removeTokenFrom(owner, _tokenId);

        emit Transfer(owner, address(0), _tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                             ESCROW STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => uint256) public user_point_epoch;
    mapping(uint256 => Point[1000000000]) private _user_point_history; // user -> Point[user_epoch]
    mapping(uint256 => LockedBalance) private _locked;
    uint256 public epoch;
    mapping(uint256 => int128) public slope_changes; // time -> signed slope change
    uint256 public supply;

    uint256 internal constant MAXTIME = 2 * 365 * 86400;
    int128 internal constant iMAXTIME = 2 * 365 * 86400;
    uint256 internal constant MULTIPLIER = 1 ether;

    function point_history(uint256 loc) external view returns (Point memory) {
        return _point_history[loc];
    }

    function user_point_history(uint256 _tokenId, uint256 loc) external view returns (Point memory) {
        return _user_point_history[_tokenId][loc];
    }

    function locked(uint256 _tokenId) external view returns (LockedBalance memory) {
        return _locked[_tokenId];
    }

    /*//////////////////////////////////////////////////////////////
                              ESCROW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the most recently recorded rate of voting power decrease for `_tokenId`
    /// @param _tokenId token of the NFT
    /// @return Value of the slope
    function get_last_user_slope(uint256 _tokenId) external view returns (int128) {
        uint256 uepoch = user_point_epoch[_tokenId];
        return _user_point_history[_tokenId][uepoch].slope;
    }

    /// @notice Get the timestamp for checkpoint `_idx` for `_tokenId`
    /// @param _tokenId token of the NFT
    /// @param _idx User epoch number
    /// @return Epoch time of the checkpoint
    function user_point_history__ts(uint256 _tokenId, uint256 _idx) external view returns (uint256) {
        return _user_point_history[_tokenId][_idx].ts;
    }

    /// @notice Get timestamp when `_tokenId`'s lock finishes
    /// @param _tokenId User NFT
    /// @return Epoch time of the lock end
    function locked__end(uint256 _tokenId) external view returns (uint256) {
        return _locked[_tokenId].end;
    }

    /// @notice Record global and per-user data to checkpoint
    /// @param _tokenId NFT token ID. No user checkpoint if 0
    /// @param old_locked Pevious locked amount / end lock time for the user
    /// @param new_locked New locked amount / end lock time for the user
    function _checkpoint(uint256 _tokenId, LockedBalance memory old_locked, LockedBalance memory new_locked) internal {
        Point memory u_old;
        Point memory u_new;
        int128 old_dslope = 0;
        int128 new_dslope = 0;
        uint256 _epoch = epoch;

        if (_tokenId != 0) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (old_locked.end > block.timestamp && old_locked.amount > 0) {
                u_old.slope = old_locked.amount / iMAXTIME;
                u_old.bias = u_old.slope * int128(int256(old_locked.end - block.timestamp));
            }
            if (new_locked.end > block.timestamp && new_locked.amount > 0) {
                u_new.slope = new_locked.amount / iMAXTIME;
                u_new.bias = u_new.slope * int128(int256(new_locked.end - block.timestamp));
            }

            // Read values of scheduled changes in the slope
            // old_locked.end can be in the past and in the future
            // new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
            old_dslope = slope_changes[old_locked.end];
            if (new_locked.end != 0) {
                if (new_locked.end == old_locked.end) {
                    new_dslope = old_dslope;
                } else {
                    new_dslope = slope_changes[new_locked.end];
                }
            }
        }

        Point memory last_point = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
        if (_epoch > 0) {
            last_point = _point_history[_epoch];
        }
        uint256 last_checkpoint = last_point.ts;
        // initial_last_point is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        Point memory initial_last_point = last_point;
        uint256 block_slope = 0; // dblock/dt
        if (block.timestamp > last_point.ts) {
            block_slope = (MULTIPLIER * (block.number - last_point.blk)) / (block.timestamp - last_point.ts);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        {
            uint256 t_i = (last_checkpoint / EPOCH_DURATION) * EPOCH_DURATION;
            for (uint256 i = 0; i < 255; ++i) {
                // Hopefully it won't happen that this won't get used in 5 years!
                // If it does, users will be able to withdraw but vote weight will be broken
                t_i += EPOCH_DURATION;
                int128 d_slope = 0;
                if (t_i > block.timestamp) {
                    t_i = block.timestamp;
                } else {
                    d_slope = slope_changes[t_i];
                }
                last_point.bias -= last_point.slope * int128(int256(t_i - last_checkpoint));
                last_point.slope += d_slope;
                if (last_point.bias < 0) {
                    // This can happen
                    last_point.bias = 0;
                }
                if (last_point.slope < 0) {
                    // This cannot happen - just in case
                    last_point.slope = 0;
                }
                last_checkpoint = t_i;
                last_point.ts = t_i;
                last_point.blk = initial_last_point.blk + (block_slope * (t_i - initial_last_point.ts)) / MULTIPLIER;
                _epoch += 1;
                if (t_i == block.timestamp) {
                    last_point.blk = block.number;
                    break;
                } else {
                    _point_history[_epoch] = last_point;
                }
            }
        }

        epoch = _epoch;
        // Now point_history is filled until t=now

        if (_tokenId != 0) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);
            if (last_point.slope < 0) {
                last_point.slope = 0;
            }
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
        }

        // Record the changed point into history
        _point_history[_epoch] = last_point;

        if (_tokenId != 0) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [new_locked.end]
            // and add old_user_slope to [old_locked.end]
            if (old_locked.end > block.timestamp) {
                // old_dslope was <something> - u_old.slope, so we cancel that
                old_dslope += u_old.slope;
                if (new_locked.end == old_locked.end) {
                    old_dslope -= u_new.slope; // It was a new deposit, not extension
                }
                slope_changes[old_locked.end] = old_dslope;
            }

            if (new_locked.end > block.timestamp) {
                if (new_locked.end > old_locked.end) {
                    new_dslope -= u_new.slope; // old slope disappeared at this point
                    slope_changes[new_locked.end] = new_dslope;
                }
                // else: we recorded it already in old_dslope
            }
            // Now handle user history
            uint256 user_epoch = user_point_epoch[_tokenId] + 1;

            user_point_epoch[_tokenId] = user_epoch;
            u_new.ts = block.timestamp;
            u_new.blk = block.number;
            _user_point_history[_tokenId][user_epoch] = u_new;
        }
    }

    /// @notice Deposit and lock tokens for a user
    /// @param _tokenId NFT that holds lock
    /// @param _value Amount to deposit
    /// @param unlock_time New time when to unlock the tokens, or 0 if unchanged
    /// @param locked_balance Previous locked amount / timestamp
    /// @param deposit_type The type of deposit
    function _deposit_for(
        uint256 _tokenId,
        uint256 _value,
        uint256 unlock_time,
        LockedBalance memory locked_balance,
        DepositType deposit_type
    ) internal {
        uint256 supply_before = supply;

        supply = supply_before + _value;
        LockedBalance memory old_locked;
        (old_locked.amount, old_locked.end) = (locked_balance.amount, locked_balance.end);
        // Adding to existing lock, or if a lock is expired - creating a new one
        locked_balance.amount += int128(int256(_value));
        if (unlock_time != 0) {
            locked_balance.end = unlock_time;
        }
        _locked[_tokenId] = locked_balance;

        // Possibilities:
        // Both old_locked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_tokenId, old_locked, locked_balance);

        address from = msg.sender;
        if (_value != 0 && deposit_type != DepositType.MERGE_TYPE && deposit_type != DepositType.SPLIT_TYPE) {
            assert(IERC20(token).transferFrom(from, address(this), _value));
        }

        emit Deposit(from, _tokenId, _value, locked_balance.end, deposit_type, block.timestamp);
        emit Supply(supply_before, supply_before + _value);
    }

    function block_number() external view returns (uint256) {
        return block.number;
    }

    /// @notice Record global data to checkpoint
    function checkpoint() external {
        _checkpoint(0, LockedBalance(0, 0), LockedBalance(0, 0));
    }

    function migrate(uint256 _tokenId) external {
        require(idToOwner[_tokenId] == address(0));
        VotingEscrow _oldVE = VotingEscrow(PREVIOUS_IMPLEMENTATION);
        address _owner = _oldVE.ownerOf(_tokenId);

        _oldVE.transferFrom(_owner, address(this), _tokenId);
        IVoter(_oldVE.voter()).reset(_tokenId);

        _mint(_owner, _tokenId);

        LockedBalance memory old_locked = _oldVE.locked(_tokenId);
        uint256 supply_before = supply;

        supply = supply_before + uint256(int256(old_locked.amount));
        _locked[_tokenId] = LockedBalance(old_locked.amount, old_locked.end);

        _checkpoint(_tokenId, LockedBalance(0, 0), _locked[_tokenId]);

        IERC20(token).transferFrom(PREVIOUS_IMPLEMENTATION, address(this), uint256(uint128(old_locked.amount)));

        emit Migrate(_tokenId, msg.sender, _owner);
    }

    /// @notice Deposit `_value` tokens for `_tokenId` and add to the lock
    /// @dev Anyone (even a smart contract) can deposit for someone else, but
    ///      cannot extend their locktime and deposit for a brand new user
    /// @param _tokenId lock NFT
    /// @param _value Amount to add to user's lock
    function deposit_for(uint256 _tokenId, uint256 _value) external nonreentrant {
        LockedBalance memory locked_balance = _locked[_tokenId];

        require(_value > 0); // dev: need non-zero value
        require(locked_balance.amount > 0, "No existing lock found");
        require(locked_balance.end > block.timestamp, "Cannot add to expired lock. Withdraw");
        _deposit_for(_tokenId, _value, 0, locked_balance, DepositType.DEPOSIT_FOR_TYPE);
    }

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lock_duration`
    /// @param _value Amount to deposit
    /// @param _lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    function _create_lock(uint256 _value, uint256 _lock_duration, address _to) internal returns (uint256) {
        uint256 unlock_time = ((block.timestamp + _lock_duration) / EPOCH_DURATION) * EPOCH_DURATION; // Locktime is rounded down to weeks

        require(_value > 0); // dev: need non-zero value
        require(unlock_time > block.timestamp, "Can only lock until time in the future");
        require(unlock_time <= block.timestamp + MAXTIME, "Voting lock can be 2 years max");

        ++tokenId;
        uint256 _tokenId = tokenId;
        _mint(_to, _tokenId);

        _deposit_for(_tokenId, _value, unlock_time, _locked[_tokenId], DepositType.CREATE_LOCK_TYPE);
        return _tokenId;
    }

    /// @notice Deposit `_value` tokens for `msg.sender` and lock for `_lock_duration`
    /// @param _value Amount to deposit
    /// @param _lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
    function create_lock(uint256 _value, uint256 _lock_duration) external nonreentrant returns (uint256) {
        return _create_lock(_value, _lock_duration, msg.sender);
    }

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lock_duration`
    /// @param _value Amount to deposit
    /// @param _lock_duration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    function create_lock_for(uint256 _value, uint256 _lock_duration, address _to) external nonreentrant returns (uint256) {
        return _create_lock(_value, _lock_duration, _to);
    }

    /// @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
    /// @param _value Amount of tokens to deposit and add to the lock
    function increase_amount(uint256 _tokenId, uint256 _value) external nonreentrant {
        assert(_isApprovedOrOwner(msg.sender, _tokenId));

        LockedBalance memory locked_balance = _locked[_tokenId];

        assert(_value > 0); // dev: need non-zero value
        require(locked_balance.amount > 0, "No existing lock found");
        require(locked_balance.end > block.timestamp, "Cannot add to expired lock. Withdraw");

        _deposit_for(_tokenId, _value, 0, locked_balance, DepositType.INCREASE_LOCK_AMOUNT);
    }

    /// @notice Extend the unlock time for `_tokenId`
    /// @param _lock_duration New number of seconds until tokens unlock
    function increase_unlock_time(uint256 _tokenId, uint256 _lock_duration) external nonreentrant {
        assert(_isApprovedOrOwner(msg.sender, _tokenId));

        LockedBalance memory locked_balance = _locked[_tokenId];
        uint256 unlock_time = ((block.timestamp + _lock_duration) / EPOCH_DURATION) * EPOCH_DURATION; // Locktime is rounded down to weeks

        require(locked_balance.end > block.timestamp, "Lock expired");
        require(locked_balance.amount > 0, "Nothing is locked");
        require(unlock_time > locked_balance.end, "Can only increase lock duration");
        require(unlock_time <= block.timestamp + MAXTIME, "Voting lock can be 2 years max");

        _deposit_for(_tokenId, 0, unlock_time, locked_balance, DepositType.INCREASE_UNLOCK_TIME);
    }

    /// @notice Withdraw all tokens for `_tokenId`
    /// @dev Only possible if the lock has expired
    function withdraw(uint256 _tokenId) external nonreentrant {
        assert(_isApprovedOrOwner(msg.sender, _tokenId));
        require(!voted[_tokenId], "pending votes");

        LockedBalance memory locked_balance = _locked[_tokenId];
        require(block.timestamp >= locked_balance.end, "not expired");
        uint256 value = uint256(int256(locked_balance.amount));

        _locked[_tokenId] = LockedBalance(0, 0);
        uint256 supply_before = supply;
        supply = supply_before - value;

        // old_locked can have either expired <= timestamp or zero end
        // locked_balance has only 0 end
        // Both can have >= 0 amount
        _checkpoint(_tokenId, locked_balance, LockedBalance(0, 0));

        assert(IERC20(token).transfer(msg.sender, value));

        // Burn the NFT
        _burn(_tokenId);

        emit Withdraw(msg.sender, _tokenId, value, block.timestamp);
        emit Supply(supply_before, supply_before - value);
    }

    /*///////////////////////////////////////////////////////////////
                           GAUGE VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.

    /// @notice Binary search to estimate timestamp for block number
    /// @param _block Block to find
    /// @param max_epoch Don't go beyond this epoch
    /// @return Approximate timestamp for block
    function _find_block_epoch(uint256 _block, uint256 max_epoch) internal view returns (uint256) {
        // Binary search
        uint256 _min = 0;
        uint256 _max = max_epoch;
        for (uint256 i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (_point_history[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /// @notice Get the current voting power for `_tokenId`
    /// @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    /// @param _tokenId NFT for lock
    /// @param _t Epoch time to return voting power at
    /// @return User voting power
    function _balanceOfNFT(uint256 _tokenId, uint256 _t) internal view returns (uint256) {
        uint256 _epoch = user_point_epoch[_tokenId];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory last_point = _user_point_history[_tokenId][_epoch];
            last_point.bias -= last_point.slope * int128(int256(_t) - int256(last_point.ts));
            if (last_point.bias < 0) {
                last_point.bias = 0;
            }
            return uint256(int256(last_point.bias));
        }
    }

    function balanceOfNFT(uint256 _tokenId) external view returns (uint256) {
        if (ownership_change[_tokenId] == block.number) return 0;
        return _balanceOfNFT(_tokenId, block.timestamp);
    }

    function balanceOfNFTAt(uint256 _tokenId, uint256 _t) external view returns (uint256) {
        return _balanceOfNFT(_tokenId, _t);
    }

    /// @notice Measure voting power of `_tokenId` at block height `_block`
    /// @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    /// @param _tokenId User's wallet NFT
    /// @param _block Block to calculate the voting power at
    /// @return Voting power
    function _balanceOfAtNFT(uint256 _tokenId, uint256 _block) internal view returns (uint256) {
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        assert(_block <= block.number);

        // Binary search
        uint256 _min = 0;
        uint256 _max = user_point_epoch[_tokenId];
        for (uint256 i = 0; i < 128; ++i) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (_user_point_history[_tokenId][_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = _user_point_history[_tokenId][_min];

        uint256 max_epoch = epoch;
        uint256 _epoch = _find_block_epoch(_block, max_epoch);
        Point memory point_0 = _point_history[_epoch];
        uint256 d_block = 0;
        uint256 d_t = 0;
        if (_epoch < max_epoch) {
            Point memory point_1 = _point_history[_epoch + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = block.number - point_0.blk;
            d_t = block.timestamp - point_0.ts;
        }
        uint256 block_time = point_0.ts;
        if (d_block != 0) {
            block_time += (d_t * (_block - point_0.blk)) / d_block;
        }

        upoint.bias -= upoint.slope * int128(int256(block_time - upoint.ts));
        if (upoint.bias >= 0) {
            return uint256(uint128(upoint.bias));
        } else {
            return 0;
        }
    }

    function balanceOfAtNFT(uint256 _tokenId, uint256 _block) external view returns (uint256) {
        return _balanceOfAtNFT(_tokenId, _block);
    }

    /// @notice Calculate total voting power at some point in the past
    /// @param _block Block to calculate the total voting power at
    /// @return Total voting power at `_block`
    function totalSupplyAt(uint256 _block) external view returns (uint256) {
        assert(_block <= block.number);
        uint256 _epoch = epoch;
        uint256 target_epoch = _find_block_epoch(_block, _epoch);

        Point memory point = _point_history[target_epoch];
        uint256 dt = 0;
        if (target_epoch < _epoch) {
            Point memory point_next = _point_history[target_epoch + 1];
            if (point.blk != point_next.blk) {
                dt = ((_block - point.blk) * (point_next.ts - point.ts)) / (point_next.blk - point.blk);
            }
        } else {
            if (point.blk != block.number) {
                dt = ((_block - point.blk) * (block.timestamp - point.ts)) / (block.number - point.blk);
            }
        }
        // Now dt contains info on how far are we beyond point
        return _supply_at(point, point.ts + dt);
    }

    /// @notice Calculate total voting power at some point in the past
    /// @param point The point (bias/slope) to start search from
    /// @param t Time to calculate the total voting power at
    /// @return Total voting power at that time
    function _supply_at(Point memory point, uint256 t) internal view returns (uint256) {
        Point memory last_point = point;
        uint256 t_i = (last_point.ts / EPOCH_DURATION) * EPOCH_DURATION;
        for (uint256 i = 0; i < 255; ++i) {
            t_i += EPOCH_DURATION;
            int128 d_slope = 0;
            if (t_i > t) {
                t_i = t;
            } else {
                d_slope = slope_changes[t_i];
            }
            last_point.bias -= last_point.slope * int128(int256(t_i - last_point.ts));
            if (t_i == t) {
                break;
            }
            last_point.slope += d_slope;
            last_point.ts = t_i;
        }

        if (last_point.bias < 0) {
            last_point.bias = 0;
        }
        return uint256(uint128(last_point.bias));
    }

    function totalSupply() external view returns (uint256) {
        return totalSupplyAtT(block.timestamp);
    }

    /// @notice Calculate total voting power
    /// @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    /// @return Total voting power
    function totalSupplyAtT(uint256 t) public view returns (uint256) {
        uint256 _epoch = epoch;
        Point memory last_point = _point_history[_epoch];
        return _supply_at(last_point, t);
    }

    /*///////////////////////////////////////////////////////////////
                            GAUGE VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => bool) public voted;

    function setVoter(address _voter) external {
        require(msg.sender == team);
        ownerToOperators[address(this)][voter] = false;
        voter = _voter;
        ownerToOperators[address(this)][_voter] = true;
    }

    function voting(uint256 _tokenId) external {
        require(msg.sender == voter);
        voted[_tokenId] = true;
    }

    function abstain(uint256 _tokenId) external {
        require(msg.sender == voter);
        voted[_tokenId] = false;
    }

    function merge(uint256 _from, uint256 _to) external {
        require(_from != _to);
        require(_isApprovedOrOwner(msg.sender, _from));
        require(_isApprovedOrOwner(msg.sender, _to));
        require(!veNFTAPI(api).hasClaimableRewards(_from), "unclaimed rewards");

        if (voted[_from]) {
            IVoter(voter).reset(_from);
        }

        LockedBalance memory _locked0 = _locked[_from];
        LockedBalance memory _locked1 = _locked[_to];
        uint256 value0 = uint256(int256(_locked0.amount));
        uint256 end = _locked0.end >= _locked1.end ? _locked0.end : _locked1.end;

        _locked[_from] = LockedBalance(0, 0);
        _checkpoint(_from, _locked0, LockedBalance(0, 0));
        _burn(_from);
        _deposit_for(_to, value0, end, _locked1, DepositType.MERGE_TYPE);
    }

    /**
     * @notice split NFT into multiple
     * @param amounts   % of split
     * @param _tokenId  NFTs ID
     */
    function split(uint256[] memory amounts, uint256 _tokenId) external {
        // check permission and vote
        require(_isApprovedOrOwner(msg.sender, _tokenId));

        // save old data and totalWeight
        address _to = idToOwner[_tokenId];
        LockedBalance memory locked_balance = _locked[_tokenId];
        uint256 end = locked_balance.end;
        uint256 value = uint256(int256(locked_balance.amount));
        require(value != 0); // dev: need non-zero value

        // reset supply, _deposit_for increase it
        supply = supply - value;

        uint256 i;
        uint256 totalWeight = 0;
        for (i = 0; i < amounts.length; ) {
            totalWeight += amounts[i];
            unchecked {
                ++i;
            }
        }

        // remove old data
        _locked[_tokenId] = LockedBalance(0, 0);
        _checkpoint(_tokenId, locked_balance, LockedBalance(0, 0));

        // save end
        uint256 unlock_time = end;
        require(unlock_time > block.timestamp, "Can only lock until time in the future");
        require(unlock_time <= block.timestamp + MAXTIME, "Voting lock can be 2 years max");

        uint256 doPoke;

        if (voted[_tokenId]) {
            IVoter _voter = IVoter(voter);
            IMinter _minter = IMinter(_voter.minter());
            uint256 _lastVoted = _voter.lastVoted(_tokenId);
            uint256 _epoch = _minter.active_period();
            if (_lastVoted >= _epoch) doPoke = _tokenId;
        }

        // mint
        uint256 _value = 0;
        for (i = 0; i < amounts.length; ) {
            if (i != 0) {
                ++tokenId;
                _tokenId = tokenId;
                _mint(_to, _tokenId);
            }
            _value = (value * amounts[i]) / totalWeight;
            _deposit_for(_tokenId, _value, unlock_time, _locked[_tokenId], DepositType.SPLIT_TYPE);
            unchecked {
                ++i;
            }
        }

        if (doPoke != 0) {
            IVoter(voter).poke(doPoke);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            DAO VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of each accounts delegate
    mapping(address => address) private _delegates;
    uint256 public constant MAX_DELEGATES = 1024; // avoid too much gas

    /// @notice A record of delegated token checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /**
     * @notice Overrides the standard `Comp.sol` delegates mapping to return
     * the delegator's own address if they haven't delegated.
     * This avoids having to delegate to oneself.
     */
    function delegates(address delegator) public view returns (address) {
        address current = _delegates[delegator];
        return current == address(0) ? delegator : current;
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }
        uint256[] storage _tokenIds = checkpoints[account][nCheckpoints - 1].tokenIds;
        uint256 votes = 0;
        for (uint256 i = _tokenIds.length; i != 0; ) {
            unchecked {
                --i;
            }
            uint256 tId = _tokenIds[i];
            votes = votes + _balanceOfNFT(tId, block.timestamp);
        }
        return votes;
    }

    function getPastVotesIndex(address account, uint256 timestamp) public view returns (uint32) {
        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }
        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].timestamp <= timestamp) {
            return (nCheckpoints - 1);
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].timestamp > timestamp) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint storage cp = checkpoints[account][center];
            if (cp.timestamp == timestamp) {
                return center;
            } else if (cp.timestamp < timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    function getPastVotes(address account, uint256 timestamp) public view returns (uint256) {
        uint32 _checkIndex = getPastVotesIndex(account, timestamp);
        // Sum votes
        uint256[] storage _tokenIds = checkpoints[account][_checkIndex].tokenIds;
        uint256 votes = 0;
        for (uint256 i = _tokenIds.length; i != 0; ) {
            unchecked {
                --i;
            }
            uint256 tId = _tokenIds[i];
            // Use the provided input timestamp here to get the right decay
            votes = votes + _balanceOfNFT(tId, timestamp);
        }
        return votes;
    }

    function getPastTotalSupply(uint256 timestamp) external view returns (uint256) {
        return totalSupplyAtT(timestamp);
    }

    /*///////////////////////////////////////////////////////////////
                             DAO VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function _moveTokenDelegates(address srcRep, address dstRep, uint256 _tokenId) internal {
        if (srcRep != dstRep && _tokenId > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256[] storage srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].tokenIds : checkpoints[srcRep][0].tokenIds;
                uint32 nextSrcRepNum = _findWhatCheckpointToWrite(srcRep);
                uint256[] storage srcRepNew = checkpoints[srcRep][nextSrcRepNum].tokenIds;
                // All the same except _tokenId
                for (uint256 i = 0; i < srcRepOld.length; i++) {
                    uint256 tId = srcRepOld[i];
                    if (tId != _tokenId) {
                        srcRepNew.push(tId);
                    }
                }

                numCheckpoints[srcRep] = srcRepNum + 1;
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256[] storage dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].tokenIds : checkpoints[dstRep][0].tokenIds;
                uint32 nextDstRepNum = _findWhatCheckpointToWrite(dstRep);
                uint256[] storage dstRepNew = checkpoints[dstRep][nextDstRepNum].tokenIds;
                // All the same plus _tokenId
                require(dstRepOld.length + 1 <= MAX_DELEGATES, "dstRep would have too many tokenIds");
                for (uint256 i = 0; i < dstRepOld.length; i++) {
                    uint256 tId = dstRepOld[i];
                    dstRepNew.push(tId);
                }
                dstRepNew.push(_tokenId);

                numCheckpoints[dstRep] = dstRepNum + 1;
            }
        }
    }

    function _findWhatCheckpointToWrite(address account) internal view returns (uint32) {
        uint256 _timestamp = block.timestamp;
        uint32 _nCheckPoints = numCheckpoints[account];

        if (_nCheckPoints > 0 && checkpoints[account][_nCheckPoints - 1].timestamp == _timestamp) {
            return _nCheckPoints - 1;
        } else {
            return _nCheckPoints;
        }
    }

    function _moveAllDelegates(address owner, address srcRep, address dstRep) internal {
        // You can only redelegate what you own
        if (srcRep != dstRep) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256[] storage srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].tokenIds : checkpoints[srcRep][0].tokenIds;
                uint32 nextSrcRepNum = _findWhatCheckpointToWrite(srcRep);
                uint256[] storage srcRepNew = checkpoints[srcRep][nextSrcRepNum].tokenIds;
                // All the same except what owner owns
                for (uint256 i = 0; i < srcRepOld.length; i++) {
                    uint256 tId = srcRepOld[i];
                    if (idToOwner[tId] != owner) {
                        srcRepNew.push(tId);
                    }
                }

                numCheckpoints[srcRep] = srcRepNum + 1;
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256[] storage dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].tokenIds : checkpoints[dstRep][0].tokenIds;
                uint32 nextDstRepNum = _findWhatCheckpointToWrite(dstRep);
                uint256[] storage dstRepNew = checkpoints[dstRep][nextDstRepNum].tokenIds;
                uint256 ownerTokenCount = ownerToNFTokenCount[owner];
                require(dstRepOld.length + ownerTokenCount <= MAX_DELEGATES, "dstRep would have too many tokenIds");
                // All the same
                for (uint256 i = 0; i < dstRepOld.length; i++) {
                    uint256 tId = dstRepOld[i];
                    dstRepNew.push(tId);
                }
                // Plus all that's owned
                for (uint256 i = 0; i < ownerTokenCount; i++) {
                    uint256 tId = ownerToNFTokenIdList[owner][i];
                    dstRepNew.push(tId);
                }

                numCheckpoints[dstRep] = dstRepNum + 1;
            }
        }
    }

    function _delegate(address delegator, address delegatee) internal {
        /// @notice differs from `_delegate()` in `Comp.sol` to use `delegates` override method to simulate auto-delegation
        address currentDelegate = delegates(delegator);

        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);
        _moveAllDelegates(delegator, currentDelegate, delegatee);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        if (delegatee == address(0)) delegatee = msg.sender;
        return _delegate(msg.sender, delegatee);
    }

    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public {
        require(delegatee != msg.sender);
        require(delegatee != address(0));

        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), block.chainid, address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "VotingEscrow::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "VotingEscrow::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "VotingEscrow::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }
}

contract OldVE is VotingEscrow {
    function initialize(address token_addr, address art_proxy) public override {
        super.initialize(token_addr, art_proxy);
        tokenId = 0;
    }
}